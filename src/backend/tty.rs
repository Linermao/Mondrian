use anyhow::Context;
use smithay::backend::allocator::dmabuf::Dmabuf;
use smithay::backend::allocator::format::FormatSet;
use smithay::backend::drm::compositor::{DrmCompositor, PrimaryPlaneElement};
use smithay::backend::drm::exporter::gbm::GbmFramebufferExporter;
use smithay::backend::drm::DrmSurface;
use smithay::backend::renderer::element::default_primary_scanout_output_compare;
use smithay::backend::renderer::multigpu::MultiFrame;
use smithay::backend::renderer::{ImportDma, ImportEgl, ImportMemWl, RendererSuper};
use smithay::desktop::utils::update_surface_primary_scanout_output;
use smithay::output::OutputModeSource;
use smithay::reexports::calloop::RegistrationToken;
use smithay::reexports::drm::control::ModeTypeFlags;
use smithay::reexports::drm::Device;
use smithay::reexports::gbm::Modifier;
use smithay::reexports::input::DeviceCapability;
use smithay::reexports::wayland_protocols::wp::linux_dmabuf::zv1::server::zwp_linux_dmabuf_feedback_v1;
use smithay::reexports::wayland_server::protocol::wl_surface::WlSurface;
use smithay::reexports::wayland_server::DisplayHandle;
use smithay::utils::Time;
use smithay::wayland::dmabuf::{DmabufFeedback, DmabufFeedbackBuilder, DmabufGlobal};
use smithay::wayland::drm_syncobj::{supports_syncobj_eventfd, DrmSyncobjState};
use smithay::{
    desktop::utils::{
        OutputPresentationFeedback, surface_presentation_feedback_flags_from_states,
        surface_primary_scanout_output,
    },
};
use smithay::{
    backend::{
        SwapBuffersError,
        allocator::{
            Fourcc,
            gbm::{GbmAllocator, GbmBufferFlags, GbmDevice},
        },
        drm::{
            DrmAccessError, DrmDevice, DrmDeviceFd, DrmError, DrmEvent, DrmEventMetadata, DrmNode,
            NodeType,
            compositor::FrameFlags,
        },
        egl::{EGLDevice, EGLDisplay, context::ContextPriority},
        input::InputEvent,
        libinput::{LibinputInputBackend, LibinputSessionInterface},
        renderer::{
            element::RenderElementStates,
            gles::GlesRenderer,
            multigpu::{GpuManager, MultiRenderer, gbm::GbmGlesBackend},
            damage::Error as OutputDamageTrackerError,
        },
        session::{Event as SessionEvent, Session, libseat::LibSeatSession},
        udev::{self, UdevBackend, UdevEvent},
    },
    output::Mode as WlMode,
    reexports::{
        calloop::{
            LoopHandle,
            timer::{TimeoutAction, Timer},
        },
        drm::control::{Device as _, connector, crtc},
        input::Libinput,
        rustix::fs::OFlags,
        wayland_protocols::wp::presentation_time::server::wp_presentation_feedback,
    },
    utils::{Clock, DeviceFd, Monotonic},
    wayland::{drm_lease::DrmLease, presentation::Refresh},
};
use smithay::output::Output;
use smithay_drm_extras::{
    display_info,
    drm_scanner::{DrmScanEvent, DrmScanner},
};
use std::{
    collections::{HashMap, HashSet},
    io,
    path::Path,
    time::Duration,
};

use crate::manager::animation::AnimationManager;
use crate::manager::input::InputManager;
use crate::manager::render::RenderManager;
use crate::manager::window::WindowManager;
use crate::manager::{cursor::CursorManager, output::OutputManager, workspace::WorkspaceManager};
use crate::render::AsGlesRenderer;
use crate::state::{GlobalData, State};

// we cannot simply pick the first supported format of the intersection of *all* formats, because:
// - we do not want something like Abgr4444, which looses color information, if something better is available
// - some formats might perform terribly
// - we might need some work-arounds, if one supports modifiers, but the other does not
//
// So lets just pick `ARGB2101010` (10-bit) or `ARGB8888` (8-bit) for now, they are widely supported.
const SUPPORTED_COLOR_FORMATS: [Fourcc; 4] = [
    Fourcc::Abgr2101010,
    Fourcc::Argb2101010,
    Fourcc::Abgr8888,
    Fourcc::Argb8888,
];

pub type TtyRenderer<'render> = MultiRenderer<
    'render,
    'render,
    GbmGlesBackend<GlesRenderer, DrmDeviceFd>,
    GbmGlesBackend<GlesRenderer, DrmDeviceFd>,
>;

pub type TtyFrame<'render, 'frame, 'buffer> = MultiFrame<
    'render,
    'render,
    'frame,
    'buffer,
    GbmGlesBackend<GlesRenderer, DrmDeviceFd>,
    GbmGlesBackend<GlesRenderer, DrmDeviceFd>,
>;

pub type TtyRendererError<'render> = <TtyRenderer<'render> as RendererSuper>::Error;

pub struct Tty {
    pub session: LibSeatSession,
    pub libinput: Libinput,
    pub gpu_manager: GpuManager<GbmGlesBackend<GlesRenderer, DrmDeviceFd>>,
    pub primary_node: DrmNode,
    pub primary_render_node: DrmNode,
    pub devices: HashMap<DrmNode, GpuDevice>,
    pub seat_name: String,
    pub dmabuf_global: Option<DmabufGlobal>,
}
pub struct GpuDevice {
    token: RegistrationToken,
    render_node: DrmNode,
    drm_scanner: DrmScanner,
    surfaces: HashMap<crtc::Handle, Surface>,
    #[allow(dead_code)]
    active_leases: Vec<DrmLease>,
    drm: DrmDevice,
    gbm: GbmDevice<DrmDeviceFd>,

    // record non_desktop connectors such as VR headsets
    // we need to handle them differently
    non_desktop_connectors: HashSet<(connector::Handle, crtc::Handle)>,
}

pub struct Surface {
    output: Output,
    #[allow(dead_code)]
    device_id: DrmNode,
    render_node: DrmNode,
    compositor: GbmDrmCompositor,
    dmabuf_feedback: Option<SurfaceDmabufFeedback>,
}

type GbmDrmCompositor = DrmCompositor<
    GbmAllocator<DrmDeviceFd>,
    GbmFramebufferExporter<DrmDeviceFd>,
    Option<OutputPresentationFeedback>,
    DrmDeviceFd,
>;

impl Tty {
    pub fn new(loop_handle: &LoopHandle<'_, GlobalData>) -> anyhow::Result<Self> {
        // Initialize session
        let (session, notifier) = LibSeatSession::new()?;
        let seat_name = session.seat();

        let mut libinput = Libinput::new_with_udev::<LibinputSessionInterface<LibSeatSession>>(
            session.clone().into(),
        );
        libinput.udev_assign_seat(&seat_name).unwrap();
        let libinput_backend = LibinputInputBackend::new(libinput.clone());

        loop_handle
            .insert_source(libinput_backend, |mut event, _, data| {
                if let InputEvent::DeviceAdded { device } = &mut event {
                    info!("libinput Device added: {:?}", device);
                    if device.has_capability(DeviceCapability::Keyboard) {
                        if let Some(led_state) = data
                            .input_manager
                            .get_keyboard()
                            .map(|keyboard| keyboard.led_state())
                        {
                            info!("Setting keyboard led state: {:?}", led_state);
                        }
                    }
                } else if let InputEvent::DeviceRemoved { ref device } = event {
                    info!("libinput Device removed: {:?}", device);
                }
                data.process_input_event(event);
            })
            .unwrap();

        loop_handle
            .insert_source(notifier, move |event, _, data| match event {
                SessionEvent::ActivateSession => {
                    info!("Session activated");
                    if data.backend.tty().libinput.resume().is_err() {
                        error!("error resuming libinput session");
                    };
                    for (node, device) in data
                        .backend
                        .tty()
                        .devices
                        .iter_mut()
                        .map(|(node, device)| (*node, device)) 
                    {
                        device.drm.activate(false).expect("failed to activate drm backend");
                        data.loop_handle.insert_idle(move |data| {

                            let device: &mut GpuDevice = if let Some(device) = data.backend.tty().devices.get_mut(&node) {
                                device
                            } else {
                                warn!("not change because of unknown device");
                                return;
                            };

                            let crtcs: Vec<_> = device.surfaces.keys().copied().collect();
                            for crtc in crtcs {
                                data.backend.tty().render_output(
                                    node,
                                    crtc,
                                    data.clock.now(),
                                    &mut data.render_manager,
                                    &data.output_manager,
                                    &data.workspace_manager,
                                    &data.window_manager,
                                    &mut data.cursor_manager,
                                    &data.input_manager,
                                    &mut data.animation_manager,
                                    &data.clock,
                                    &data.loop_handle,
                                );
                            }
                        });
                    }
                }
                SessionEvent::PauseSession => {
                    info!("Session paused");
                    data.backend.tty().libinput.suspend();
                    for device in data.backend.tty().devices.values_mut() {
                        device.drm.pause();
                    }
                }
            })
            .unwrap();

        // Initialize Gpu manager
        let api = GbmGlesBackend::with_context_priority(ContextPriority::Medium);
        let gpu_manager = GpuManager::new(api).context("error creating the GPU manager")?;

        let primary_gpu_path = udev::primary_gpu(&seat_name)
            .context("error getting the primary GPU")?
            .context("couldn't find a GPU")?;

        info!("using as the primary node: {:?}", primary_gpu_path);

        let primary_node = DrmNode::from_path(primary_gpu_path)
            .context("error opening the primary GPU DRM node")?;

        info!("Primary GPU: {:?}", primary_node);

        // get render node if exit - /renderD128
        let primary_render_node = primary_node
            .node_with_type(NodeType::Render)
            .and_then(Result::ok)
            .unwrap_or_else(|| {
                warn!("error getting the render node for the primary GPU; proceeding anyway");
                primary_node
            });

        let primary_render_node_path = if let Some(path) = primary_render_node.dev_path() {
            format!("{:?}", path)
        } else {
            format!("{}", primary_render_node)
        };
        info!("using as the render node: {}", primary_render_node_path);

        Ok(Self {
            session,
            libinput,
            gpu_manager,
            primary_node,
            primary_render_node,
            devices: HashMap::new(),
            seat_name,
            dmabuf_global: None,
        })
    }

    pub fn init(
        &mut self,
        loop_handle: &LoopHandle<'_, GlobalData>,
        display_handle: &DisplayHandle,
        output_manager: &mut OutputManager,
        render_manager: &RenderManager,
        state: &mut State,
    ) {
        let udev_backend = UdevBackend::new(&self.seat_name).unwrap();

        // gpu device
        for (device_id, path) in udev_backend.device_list() {
            if let Ok(node) = DrmNode::from_dev_id(device_id) {
                if let Err(err) = self.device_added(
                    node,
                    &path,
                    output_manager,
                    loop_handle,
                    display_handle,
                ) {
                    warn!("erro adding device: {:?}", err);
                }
            }
        }
        let mut renderer = self
            .gpu_manager
            .single_renderer(&self.primary_render_node)
            .unwrap();

        // initial shader
        render_manager.compile_shaders(&mut renderer.as_gles_renderer());
    
        state.shm_state.update_formats(renderer.shm_formats());

        match renderer.bind_wl_display(display_handle) {
            Ok(_) => info!("EGL hardware-acceleration enabled"),
            Err(err) => info!(?err, "Failed to initialize EGL hardware-acceleration"),
        }

        // create dmabuf
        let dmabuf_formats = renderer.dmabuf_formats();
        let default_feedback =
            DmabufFeedbackBuilder::new(self.primary_render_node.dev_id(), dmabuf_formats.clone())
                .build()
                .expect("Failed building default dmabuf feedback");
    
        let dmabuf_global = state
            .dmabuf_state
            .create_global_with_default_feedback::<GlobalData>(
                display_handle,
                &default_feedback,
            );
        self.dmabuf_global = Some(dmabuf_global);
    
        // Update the dmabuf feedbacks for all surfaces
        for device in self.devices.values_mut() {
            for surface in device.surfaces.values_mut() {
                surface.dmabuf_feedback = surface_dmabuf_feedback(
                    surface.compositor.surface(), 
                    &self.primary_render_node, 
                    &surface.render_node, 
                    &mut self.gpu_manager
                )
            }
        }

        // Expose syncobj protocol if supported by primary GPU
        if let Some(device) = self.devices.get(&self.primary_node) {
            let import_device = device.drm.device_fd().clone();
            if supports_syncobj_eventfd(&import_device) {
                info!("syncobj enabled");
                let syncobj_state =
                    DrmSyncobjState::new::<GlobalData>(&display_handle, import_device);
                state.syncobj_state = Some(syncobj_state);
            }
        }

        loop_handle
            .insert_source(udev_backend, move |event, _, data| match event {
                UdevEvent::Added { device_id, path } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        if let Err(err) = data.backend.tty().device_added(
                            node,
                            &path,
                            &mut data.output_manager,
                            &data.loop_handle,
                            &data.display_handle,
                        ) {
                            warn!("erro adding device: {:?}", err);
                        }
                    }
                }
                UdevEvent::Changed { device_id } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        data.backend.tty().device_changed(
                            node,
                            &mut data.output_manager,
                            &data.display_handle,
                            &data.loop_handle
                        )
                    }
                }
                UdevEvent::Removed { device_id } => {
                    if let Ok(node) = DrmNode::from_dev_id(device_id) {
                        data.backend.tty().device_removed(
                            &data.loop_handle,
                            &data.display_handle,
                            node,
                            &mut data.output_manager,
                            &mut data.state,
                        );
                    }
                }
            })
            .unwrap();
    }

    pub fn device_added(
        &mut self,
        node: DrmNode,
        path: &Path,
        output_manager: &mut OutputManager,
        loop_handle: &LoopHandle<'_, GlobalData>,
        display_handle: &DisplayHandle,
    ) -> anyhow::Result<()> {
        info!("device added: {:?}", node);
        let fd = self.session.open(
            path,
            OFlags::RDWR | OFlags::CLOEXEC | OFlags::NOCTTY | OFlags::NONBLOCK,
        )?;
        let device_fd = DrmDeviceFd::new(DeviceFd::from(fd));

        let (drm, drm_notifier) = DrmDevice::new(device_fd.clone(), true)?;
        let gbm = GbmDevice::new(device_fd)?;

        let token = loop_handle
            .insert_source(drm_notifier, move |event, meta, data| {
                match event {
                    DrmEvent::VBlank(crtc) => {
                        let meta = meta.expect("VBlank events must have metadata");
                        data.backend.tty().on_vblank(
                            node,
                            crtc,
                            meta,
                            data.output_manager.current_output(),
                            &data.clock,
                            &data.loop_handle,
                        );
                    }
                    DrmEvent::Error(error) => warn!("DRM Vblank error: {error}"),
                };
            })
            .unwrap();

        let egl_display = unsafe { EGLDisplay::new(gbm.clone())? };
        let egl_device = EGLDevice::device_for_display(&egl_display)?;

        // get render_node, if not, using node
        let render_node = egl_device.try_get_render_node()?.unwrap_or(node);

        self.gpu_manager
            .as_mut()
            .add_node(render_node, gbm.clone())
            .context("error adding render node to GPU manager")?;

        self.devices.insert(
            node,
            GpuDevice {
                token,
                drm_scanner: DrmScanner::new(),
                non_desktop_connectors: HashSet::new(),
                render_node,
                drm,
                gbm,

                surfaces: HashMap::new(),
                active_leases: Vec::new(),
            },
        );

        self.device_changed(node, output_manager, display_handle, loop_handle);

        Ok(())
    }

    pub fn device_changed(
        &mut self,
        node: DrmNode,
        output_manager: &mut OutputManager,
        display_handle: &DisplayHandle,
        loop_handle: &LoopHandle<'_, GlobalData>
    ) {
        info!("device changed: {:?}", node);
        let device: &mut GpuDevice = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            warn!("not change because of unknown device");
            return;
        };

        let scan_result = match device.drm_scanner.scan_connectors(&device.drm) {
            Ok(x) => x,
            Err(err) => {
                warn!("error scanning connectors: {err:?}");
                return;
            }
        };

        for event in scan_result {
            match event {
                DrmScanEvent::Connected {
                    connector,
                    crtc: Some(crtc),
                } => {
                    self.connector_connected(node, connector, crtc, output_manager, display_handle, loop_handle);
                }
                DrmScanEvent::Disconnected {
                    connector,
                    crtc: Some(crtc),
                } => {
                    self.connector_disconnected(node, connector, crtc, output_manager);
                }
                _ => {}
            }
        }
    }

    pub fn device_removed(
        &mut self,
        loop_handle: &LoopHandle<'_, GlobalData>,
        display_handle: &DisplayHandle,
        node: DrmNode,
        output_manager: &mut OutputManager,
        state: &mut State,
    ) {
        info!("device removed: {:?}", node);

        let device: &mut GpuDevice = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            warn!("not change because of unknown device");
            return;
        };

        let crtcs: Vec<_> = device
            .drm_scanner
            .crtcs()
            .map(|(info, crtc)| (info.clone(), crtc))
            .collect();

        for (connector, crtc) in crtcs {
            self.connector_disconnected(node, connector, crtc, output_manager);
        }

        if let Some(device) = self.devices.remove(&node) {
            if node == self.primary_node || device.render_node == self.primary_render_node {
                match self.gpu_manager.single_renderer(&device.render_node) {
                    Ok(mut renderer) => renderer.unbind_wl_display(),
                    Err(err) => {
                        warn!("error creating renderer during device removal: {err}");
                    }
                }
                // Disable and destroy the dmabuf global.
                if let Some(global) = self.dmabuf_global.take() {
                    state
                        .dmabuf_state
                        .disable_global::<GlobalData>(display_handle, &global);
                    loop_handle
                        .insert_source(
                            Timer::from_duration(Duration::from_secs(10)),
                            move |_, _, data| {
                                data.state
                                    .dmabuf_state
                                    .destroy_global::<GlobalData>(&data.display_handle, global);
                                TimeoutAction::Drop
                            },
                        )
                        .unwrap();

                    // Clear the dmabuf feedbacks for all surfaces.
                    for device in self.devices.values_mut() {
                        for surface in device.surfaces.values_mut() {
                            surface.dmabuf_feedback = None;
                        }
                    }
                } else {
                    error!("Failed to remove dmabuf global");
                }
            }

            self.gpu_manager.as_mut().remove_node(&device.render_node);
            loop_handle.remove(device.token);
        }
    }

    pub fn on_vblank(
        &mut self,
        node: DrmNode,
        crtc: crtc::Handle,
        meta: DrmEventMetadata,
        output: &Output,
        clock: &Clock<Monotonic>,
        loop_handle: &LoopHandle<'_, GlobalData>,
    ) {
        let _span = tracy_client::span!("vblank_time");

        let device = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            return;
        };

        let surface = if let Some(surface) = device.surfaces.get_mut(&crtc) {
            surface
        } else {
            error!("Trying to finish frame on non-existent backend surface");
            return;
        };

        let tp = match meta.time {
            smithay::backend::drm::DrmEventTime::Monotonic(tp) => Some(tp),
            smithay::backend::drm::DrmEventTime::Realtime(_) => None,
        };

        let seq = meta.sequence;

        let (clock, flags) = if let Some(tp) = tp {
            (
                tp.into(),
                wp_presentation_feedback::Kind::Vsync
                    | wp_presentation_feedback::Kind::HwClock
                    | wp_presentation_feedback::Kind::HwCompletion,
            )
        } else {
            (clock.now(), wp_presentation_feedback::Kind::Vsync)
        };

        let submit_result = surface
            .compositor
            .frame_submitted()
            .map_err(Into::<SwapBuffersError>::into);

        let Some(frame_duration) = output
            .current_mode()
            .map(|mode| Duration::from_secs_f64(1_000f64 / mode.refresh as f64))
        else {
            return;
        };

        let schedule_render = match submit_result {
            Ok(user_data) => {
                if let Some(mut feedback) = user_data.flatten() {
                    feedback.presented(
                        clock,
                        Refresh::fixed(frame_duration),
                        seq as u64,
                        flags,
                    );
                }

                true
            }
            Err(err) => {
                warn!("Error during rendering: {:?}", err);
                match err {
                    SwapBuffersError::AlreadySwapped => true,
                    // If the device has been deactivated do not reschedule, this will be done
                    // by session resume
                    SwapBuffersError::TemporaryFailure(err)
                        if matches!(
                            err.downcast_ref::<DrmError>(),
                            Some(&DrmError::DeviceInactive)
                        ) =>
                    {
                        false
                    }
                    SwapBuffersError::TemporaryFailure(err) => matches!(
                        err.downcast_ref::<DrmError>(),
                        Some(DrmError::Access(DrmAccessError {
                            source,
                            ..
                        })) if source.kind() == io::ErrorKind::PermissionDenied
                    ),
                    SwapBuffersError::ContextLost(err) => {
                        panic!("Rendering loop lost: {}", err)
                    }
                }
            }
        };

        if schedule_render {
            let next_frame_target = clock + frame_duration;

            loop_handle.insert_idle(move |data| {
                
                data.backend.tty().render_output(
                    node,
                    crtc,
                    next_frame_target,
                    &mut data.render_manager,
                    &data.output_manager,
                    &data.workspace_manager,
                    &data.window_manager,
                    &mut data.cursor_manager,
                    &data.input_manager,
                    &mut data.animation_manager,
                    &data.clock,
                    &data.loop_handle,
                );

                data.post_repaint(next_frame_target);
            });
        }
    }

    pub fn connector_connected(
        &mut self,
        node: DrmNode,
        connector: connector::Info,
        crtc: crtc::Handle,
        output_manager: &mut OutputManager,
        display_handle: &DisplayHandle,
        loop_handle: &LoopHandle<'_, GlobalData>
    ) {
        let device = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            return;
        };

        let output_name = format!(
            "{}-{}",
            connector.interface().as_str(),
            connector.interface_id()
        );
        info!(?crtc, "Trying to setup connector {}", output_name);

        let drm_device = &device.drm;
        let non_desktop = drm_device
            .get_properties(connector.handle())
            .ok()
            .and_then(|props| {
                let (info, value) = props
                    .into_iter()
                    .filter_map(|(handle, value)| {
                        let info = drm_device.get_property(handle).ok()?;

                        Some((info, value))
                    })
                    .find(|(info, _)| info.name().to_str() == Ok("non-desktop"))?;

                info.value_type().convert_value(value).as_boolean()
            })
            .unwrap_or(false);

        if non_desktop {
            info!("Connector {} is non-desktop", output_name);
            device
                .non_desktop_connectors
                .insert((connector.handle(), crtc));
            // TODO: lease the connector for non-desktop connectors
        } else {
            let display_info = display_info::for_connector(drm_device, connector.handle());

            let make = display_info
                .as_ref()
                .and_then(|info| info.make())
                .unwrap_or_else(|| "Unknown".into());

            let model_name = display_info
                .as_ref()
                .and_then(|info| info.model())
                .unwrap_or_else(|| "Unknown".into());


            let modes = connector.modes();

            let preferred_mode = modes.iter()
                .find(|mode| mode.mode_type().contains(ModeTypeFlags::PREFERRED));
            
            let default_size = preferred_mode
                .map(|m| m.size())
                .unwrap_or_else(|| {
                    modes.iter()
                        .map(|m| m.size())
                        .max()
                        .unwrap_or((0, 0))
                });
            
            // TODO: use config perfect vrefresh
            let drm_mode = modes.iter()
                .filter(|mode| mode.size() == default_size && mode.vrefresh() <= 100)
                .min_by_key(|mode| 100 - mode.vrefresh())
                .or(preferred_mode)
                .unwrap_or(&modes[0])
                .clone();

            // print all modes
            for mode in modes {
                let marker = if mode == &drm_mode { "[*]" } else { "   " };
                info!(
                    "{} Mode: {}x{} @ {}Hz {:?}",
                    marker,
                    mode.size().0,
                    mode.size().1,
                    mode.vrefresh(),
                    mode.mode_type()
                );
            }

            let wl_mode = WlMode::from(drm_mode);

            let (phys_w, phys_h) = connector.size().unwrap_or((0, 0));
            info!("Connector {} size: {}x{}", output_name, phys_w, phys_h);

            output_manager.add_output(
                output_name,
                (phys_w as i32, phys_h as i32).into(),
                connector.subpixel().into(),
                make,
                model_name,
                (0, 0).into(),
                true,
                display_handle,
            );

            output_manager.change_current_state(
                Some(wl_mode),
                None,
                None,
                Some((0, 0).into()), // TODO: multiple outputs
            );
            output_manager.set_preferred(wl_mode);

            let driver = match drm_device.get_driver() {
                Ok(driver) => driver,
                Err(err) => {
                    warn!("error getting driver: {:?}", err);
                    return;
                }
            };

            let mut planes = match drm_device.planes(&crtc) {
                Ok(planes) => planes,
                Err(err) => {
                    warn!("error getting planes: {:?}", err);
                    return;
                }
            };

            // Using an overlay plane on a nvidia card breaks
            if driver
                .name()
                .to_string_lossy()
                .to_lowercase()
                .contains("nvidia")
                || driver
                    .description()
                    .to_string_lossy()
                    .to_lowercase()
                    .contains("nvidia")
            {
                info!("Nvidia driver detected, disabling overlay planes");
                planes.overlay = vec![];
            }

            // TODO: error handling
            let drm_surface = match device
                .drm
                .create_surface(crtc, drm_mode, &[connector.handle()])
            {
                Ok(surface) => surface,
                Err(err) => {
                    warn!("error creating surface: {:?}", err);
                    return;
                }
            };

            let gbm_flags = GbmBufferFlags::RENDERING | GbmBufferFlags::SCANOUT;
            let allocator = GbmAllocator::new(device.gbm.clone(), gbm_flags);

            let mut renderer = self
                .gpu_manager
                .single_renderer(&device.render_node)
                .unwrap();
            let egl_context = renderer.as_gles_renderer().egl_context();
            let render_formats = egl_context.dmabuf_render_formats();

            // Filter out the CCS modifiers as they have increased bandwidth, causing some monitor
            // configurations to stop working.
            //
            // The invalid modifier attempt below should make this unnecessary in some cases, but it
            // would still be a bad idea to remove this until Smithay has some kind of full-device
            // modesetting test that is able to "downgrade" existing connector modifiers to get enough
            // bandwidth for a newly connected one.
            let render_formats = render_formats
                .iter()
                .copied()
                .filter(|format| {
                    !matches!(
                        format.modifier,
                        Modifier::I915_y_tiled_ccs
                    // I915_FORMAT_MOD_Yf_TILED_CCS
                    | Modifier::Unrecognized(0x100000000000005)
                    | Modifier::I915_y_tiled_gen12_rc_ccs
                    | Modifier::I915_y_tiled_gen12_mc_ccs
                    // I915_FORMAT_MOD_Y_TILED_GEN12_RC_CCS_CC
                    | Modifier::Unrecognized(0x100000000000008)
                    // I915_FORMAT_MOD_4_TILED_DG2_RC_CCS
                    | Modifier::Unrecognized(0x10000000000000a)
                    // I915_FORMAT_MOD_4_TILED_DG2_MC_CCS
                    | Modifier::Unrecognized(0x10000000000000b)
                    // I915_FORMAT_MOD_4_TILED_DG2_RC_CCS_CC
                    | Modifier::Unrecognized(0x10000000000000c)
                    )
                })
                .collect::<FormatSet>();

            let compositor = match DrmCompositor::new(
                OutputModeSource::Auto(output_manager.current_output().clone()),
                drm_surface,
                None,
                allocator.clone(),
                GbmFramebufferExporter::new(device.gbm.clone(), Some(device.render_node)),
                SUPPORTED_COLOR_FORMATS,
                render_formats,
                device.drm.cursor_size(),
                Some(device.gbm.clone()),
            ) {
                Ok(compositor) => compositor,
                Err(err) => {
                    warn!("error creating compositor: {:?}", err);
                    return;
                }
            };

            let dmabuf_feedback = surface_dmabuf_feedback(
                compositor.surface(), 
                &self.primary_render_node,
                &device.render_node,
                &mut self.gpu_manager
            );

            let surface = Surface {
                output: output_manager.current_output().clone(),
                device_id: node,
                render_node: device.render_node,
                compositor,
                dmabuf_feedback,
            };

            device.surfaces.insert(crtc, surface);

            // kick-off rendering 
            loop_handle.insert_idle(move |data| {
                data.backend.tty().render_output(
                    node,
                    crtc,
                    data.clock.now(),
                    &mut data.render_manager,
                    &data.output_manager,
                    &data.workspace_manager,
                    &data.window_manager,
                    &mut data.cursor_manager,
                    &data.input_manager,
                    &mut data.animation_manager,
                    &data.clock,
                    &data.loop_handle,
                );
            });
        }
    }

    pub fn connector_disconnected(
        &mut self,
        node: DrmNode,
        connector: connector::Info,
        crtc: crtc::Handle,
        output_manager: &mut OutputManager,
    ) {
        let device: &mut GpuDevice = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            warn!("not change because of unknown device");
            return;
        };

        if let Some((handle, value)) = device
            .non_desktop_connectors
            .iter()
            .find(|(handle, _)| *handle == connector.handle())
            .cloned()
        {
            info!("leasing connector");
            device.non_desktop_connectors.remove(&(handle, value));
        } else {
            let surface = match device.surfaces.remove(&crtc) {
                Some(surface) => surface,
                None => {
                    warn!("Failed to remove surface: {:?}", crtc);
                    return;
                }
            };
            output_manager.remove_output(&surface.output);
        }
    }

    pub fn render_output(
        &mut self,
        node: DrmNode,
        crtc: crtc::Handle,
        frame_target: Time<Monotonic>,

        render_manager: &mut RenderManager,
        output_manager: &OutputManager,
        workspace_manager: &WorkspaceManager,
        window_manager: &WindowManager,
        cursor_manager: &mut CursorManager,
        input_manager: &InputManager,
        animation_manager: &mut AnimationManager,

        clock: &Clock<Monotonic>,
        loop_handle: &LoopHandle<'_, GlobalData>,
    ) {
        let _span = tracy_client::span!("tty_render");

        let device: &mut GpuDevice = if let Some(device) = self.devices.get_mut(&node) {
            device
        } else {
            warn!("not change because of unknown device");
            return;
        };

        let surface = if let Some(surface) = device.surfaces.get_mut(&crtc) {
            surface
        } else {
            return;
        };

        let mut renderer = self
            .gpu_manager
            .single_renderer(&surface.render_node)
            .unwrap();

        let elements = render_manager.get_render_elements(
            &mut renderer,
            output_manager,
            workspace_manager,
            window_manager,
            cursor_manager,
            input_manager,
            animation_manager,
        );

        match surface
            .compositor
            .render_frame(&mut renderer, &elements, [0.; 4], FrameFlags::DEFAULT)
            .map(|render_frame_result| {
                if let PrimaryPlaneElement::Swapchain(element) = render_frame_result.primary_element {
                    element.sync.wait().unwrap();
                }
                (!render_frame_result.is_empty, render_frame_result.states)
            })
            .map_err(|err| match err {
                smithay::backend::drm::compositor::RenderFrameError::PrepareFrame(err) => {
                    SwapBuffersError::from(err)
                }
                smithay::backend::drm::compositor::RenderFrameError::RenderFrame(
                    OutputDamageTrackerError::Rendering(err),
                ) => SwapBuffersError::from(err),
                _ => unreachable!(),
            }) {
            Ok((rendered, render_element_states)) => {
                if rendered {

                    update_primary_scanout_output(
                        workspace_manager, 
                        output_manager.current_output(), 
                        &render_element_states
                    );

                    // need queue_frame to switch buffer
                    let output_presentation_feedback = take_presentation_feedback(
                        output_manager.current_output(),
                        workspace_manager,
                        &render_element_states,
                    );

                    // queue_frame will arise vlbank
                    match surface
                        .compositor
                        .queue_frame(Some(output_presentation_feedback))
                        .map_err(Into::<SwapBuffersError>::into)
                    {
                        Ok(_) => {}
                        Err(err) => {
                            warn!("error queue frame: {:?}", err);
                            match err {
                                SwapBuffersError::AlreadySwapped => {
                                    panic!("AlreadySwapped: {}", err);
                                }
                                SwapBuffersError::TemporaryFailure(err) => {
                                    if matches!(
                                        err.downcast_ref::<DrmError>(),
                                        Some(&DrmError::DeviceInactive)
                                    ) {
                                        panic!("TemporaryFailure: {}", err);
                                    }
                                }
                                SwapBuffersError::ContextLost(err) => {
                                    panic!("ContextLost: {}", err)
                                }
                            }
                        }
                    }
                } else {
                    let output_refresh = output_manager.current_refresh();
                    let next_frame_target = frame_target+Duration::from_millis(1_000_000/output_refresh as u64);
                    
                    let reschedule_timeout =
                        Duration::from(next_frame_target).saturating_sub(clock.now().into());
                    debug!(
                        "reschedule repaint timer with delay {:?} on {:?}",
                        reschedule_timeout,
                        crtc,
                    );
                    let timer = Timer::from_duration(reschedule_timeout);

                    loop_handle
                        .insert_source(timer, move |_, _, data| {
                            data.backend.tty().render_output(
                                node,
                                crtc,
                                next_frame_target,
                                &mut data.render_manager,
                                &data.output_manager,
                                &data.workspace_manager,
                                &data.window_manager,
                                &mut data.cursor_manager,
                                &data.input_manager,
                                &mut data.animation_manager,
                                &data.clock,
                                &data.loop_handle,
                            );
                            TimeoutAction::Drop
                        })
                        .expect("failed to schedule frame timer");
                }
            }
            Err(err) => {
                warn!("error rendering frame: {:?}", err);
                match err {
                    SwapBuffersError::AlreadySwapped => {}
                    SwapBuffersError::TemporaryFailure(err) => {
                        if matches!(
                            err.downcast_ref::<DrmError>(),
                            Some(&DrmError::DeviceInactive)
                        ) {
                            return;
                        }
                    }
                    SwapBuffersError::ContextLost(err) => {
                        panic!("Rendering loop lost: {}", err)
                    }
                }
            }
        }
    }

    pub fn dmabuf_imported(&mut self, dmabuf: &Dmabuf) -> bool {
        let mut renderer = match self.gpu_manager.single_renderer(&self.primary_render_node) {
            Ok(renderer) => renderer,
            Err(err) => {
                warn!("error creating renderer for primary GPU: {:?}", err);
                return false;
            }
        };
        match renderer.import_dmabuf(dmabuf, None) {
            Ok(_) => {
                dmabuf.set_node(Some(self.primary_render_node));
                true
            }
            Err(err) => {
                warn!("error import dmabuf: {:?}", err);
                false
            }
        }
    }

    pub fn early_import(&mut self, surface: &WlSurface) {
        if let Err(err) = self.gpu_manager.early_import(
            // We always render on the primary GPU.
            self.primary_render_node,
            surface,
        ) {
            warn!("error doing early import: {err:?}");
        }
    }

    pub fn change_vt(&mut self, vt: i32) {
        if let Err(err) = self.session.change_vt(vt) {
            warn!("error changing VT: {err}");
        }
    }
}

#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct SurfaceDmabufFeedback {
    pub render_feedback: DmabufFeedback,
    pub scanout_feedback: DmabufFeedback,
}

fn surface_dmabuf_feedback(
    drm_surface: &DrmSurface,
    primary_render_node: &DrmNode,
    render_node: &DrmNode,
    gpu_manager: &mut GpuManager<GbmGlesBackend<GlesRenderer, DrmDeviceFd>>,
) -> Option<SurfaceDmabufFeedback> {
    let primary_formats = gpu_manager.single_renderer(&primary_render_node).ok()?.dmabuf_formats();
    let render_formats = gpu_manager.single_renderer(&render_node).ok()?.dmabuf_formats();

    let all_render_formats = primary_formats
        .iter()
        .chain(render_formats.iter())
        .copied()
        .collect::<FormatSet>();

    let planes = drm_surface.planes().clone();

    // We limit the scan-out tranche to formats we can also render from
    // so that there is always a fallback render path available in case
    // the supplied buffer can not be scanned out directly
    let planes_formats = drm_surface
        .plane_info()
        .formats
        .iter()
        .copied()
        .chain(planes.overlay.into_iter().flat_map(|p| p.formats))
        .collect::<FormatSet>()
        .intersection(&all_render_formats)
        .copied()
        .collect::<FormatSet>();

    let builder = DmabufFeedbackBuilder::new(primary_render_node.dev_id(), primary_formats);
    let render_feedback = builder
        .clone()
        .add_preference_tranche(render_node.dev_id(), None, render_formats.clone())
        .build()
        .unwrap();
    
    let scanout_feedback = builder
        .add_preference_tranche(
            drm_surface.device_fd().dev_id().unwrap(),
            Some(zwp_linux_dmabuf_feedback_v1::TrancheFlags::Scanout),
            planes_formats,
        )
        .add_preference_tranche(render_node.dev_id(), None, render_formats)
        .build()
        .unwrap();
    
    Some(SurfaceDmabufFeedback { render_feedback, scanout_feedback })
}

pub fn take_presentation_feedback(
    output: &Output,
    workspace_manager: &WorkspaceManager,
    render_element_states: &RenderElementStates,
) -> OutputPresentationFeedback {
    let mut output_presentation_feedback = OutputPresentationFeedback::new(output);

    workspace_manager.windows().for_each(|window| {
        window.take_presentation_feedback(
            &mut output_presentation_feedback,
            surface_primary_scanout_output,
            |surface, _| {
                surface_presentation_feedback_flags_from_states(surface, render_element_states)
            },
        );
    });
    let map = smithay::desktop::layer_map_for_output(output);
    for layer_surface in map.layers() {
        layer_surface.take_presentation_feedback(
            &mut output_presentation_feedback,
            surface_primary_scanout_output,
            |surface, _| {
                surface_presentation_feedback_flags_from_states(surface, render_element_states)
            },
        );
    }

    output_presentation_feedback
}

pub fn update_primary_scanout_output(
    workspace_manager: &WorkspaceManager,
    output: &Output,
    render_element_states: &RenderElementStates,
) {
    workspace_manager.windows().for_each(|window| {
        window.with_surfaces(|surface, states| {
            update_surface_primary_scanout_output(
                surface,
                output,
                states,
                render_element_states,
                default_primary_scanout_output_compare,
            );
        });
    });
    let map = smithay::desktop::layer_map_for_output(output);
    for layer_surface in map.layers() {
        layer_surface.with_surfaces(|surface, states| {
            update_surface_primary_scanout_output(
                surface,
                output,
                states,
                render_element_states,
                default_primary_scanout_output_compare,
            );
        });
    }
}