use std::{
    collections::HashMap,
    time::{Duration, Instant},
};

use smithay::{
    backend::renderer::{
        element::{
            memory::MemoryRenderBufferRenderElement, surface::{render_elements_from_surface_tree, WaylandSurfaceRenderElement}, AsRenderElements, Kind
        }, gles::{GlesRenderer, Uniform}, Color32F
    },
    desktop::{layer_map_for_output, Window},
    utils::{IsAlive, Logical, Point, Rectangle, Scale},
    wayland::shell::wlr_layer::Layer,
};

use crate::{
    animation::{Animation, AnimationState, AnimationType}, input::focus::KeyboardFocusTarget, manager::window::WindowExt, protocol::xdg_shell::FullscreenSurface, render::{
        background::{Background, BackgroundRenderElement}, border::{BorderRenderElement, BorderShader}, elements::{CustomRenderElements, OutputRenderElements, ShaderRenderElement}, MondrianRenderer
    }
};

use super::{
    cursor::{CursorManager, RenderCursor, XCursor},
    input::InputManager,
    output::OutputManager,
    workspace::WorkspaceManager,
};

pub struct RenderManager {
    // no need now
    start_time: Instant,
    animations: HashMap<Window, Animation>,
}

impl RenderManager {
    pub fn new() -> Self {
        Self {
            start_time: Instant::now(),
            animations: HashMap::new(),
        }
    }

    pub fn compile_shaders(&self, renderer: &mut GlesRenderer) {
        BorderRenderElement::complie_shaders(renderer);
        BackgroundRenderElement::complie_shaders(renderer);
    }

    pub fn get_render_elements<R: MondrianRenderer>(
        &mut self,
        renderer: &mut R,
        output_manager: &OutputManager,
        workspace_manager: &WorkspaceManager,
        cursor_manager: &mut CursorManager,
        input_manager: &InputManager,
    ) -> Vec<OutputRenderElements<R>> {
        let _span = tracy_client::span!("get_render_elements");

        let mut output_elements = vec![];

        // First is Cursor
        output_elements.extend(
            self.get_cursor_render_elements(
                renderer,
                output_manager,
                cursor_manager,
                input_manager,
            )
            .into_iter()
            .map(OutputRenderElements::Custom),
        );

        // Then Some Control elements

        // Then Windows, Borders and Layer-shell
        output_elements.extend(
            self.get_windows_render_elements(
                    renderer, 
                    output_manager, 
                    workspace_manager, 
                    input_manager
                )
                .into_iter()
                .map(OutputRenderElements::Custom),
        );

        // output_elements.extend(
        //     self.get_background_render_elements(renderer, output_manager)
        //         .into_iter()
        //         .map(OutputRenderElements::Custom),
        // );

        output_elements
    }

    pub fn get_windows_render_elements<R: MondrianRenderer>(
        &mut self,
        renderer: &mut R,
        output_manager: &OutputManager,
        workspace_manager: &WorkspaceManager,
        input_manager: &InputManager,
    ) -> Vec<CustomRenderElements<R>> {
        let _span = tracy_client::span!("get_windows_render_elements");

        self.refresh(output_manager);

        let mut elements: Vec<CustomRenderElements<R>> = vec![];

        let output = output_manager.current_output();
        let output_geo = output_manager.output_geometry(output).unwrap();
        let output_scale = output.current_scale().fractional_scale();

        // layer shell top and overlap
        let layer_map = layer_map_for_output(output);
        for layer in [Layer::Overlay, Layer::Top] {
            for layer_surface in layer_map.layers_on(layer) {
                let layout_rec = layer_map.layer_geometry(layer_surface).unwrap();
                elements.extend(
                    layer_surface.render_elements::<WaylandSurfaceRenderElement<R>>(
                        renderer,
                        (layout_rec.loc + output_geo.loc).to_physical_precise_round(output_scale),
                        Scale::from(output_scale),
                        1.0,
                    ).into_iter().map(CustomRenderElements::Surface)
                );
            }
        }

        // fullscreen surface
        if let Some((window, _)) = output
            .user_data()
            .get::<FullscreenSurface>()
            .and_then(|f| f.get())
        {
            let location: Point<i32, Logical> = (0, 0).into();
            elements.extend(window
                .render_elements::<WaylandSurfaceRenderElement<R>>(
                    renderer,
                    (location - window.geometry().loc).to_physical_precise_round(output_scale),
                    Scale::from(output_scale),
                    1.0,
                ).into_iter().map(CustomRenderElements::Surface)
            );

            return elements;
        }

        // windows border
        elements.extend(self.get_border_render_elements(renderer, input_manager));

        // windows
        for window in workspace_manager.elements() {
            let location = match self.animations.get_mut(window) {
                Some(animation) => {
                    match animation.state {
                        AnimationState::NotStarted => {
                            let rec = animation.start();
                            window.send_rect(rec);
                            rec.loc
                        }
                        AnimationState::Running => {
                            animation.tick();
                            let rec = animation.current_value();
                            window.send_rect(rec);
                            rec.loc
                        }
                        _ => break,
                    }
                }
                None => {
                    let window_rec = window.get_rect();
                    window_rec.loc
                }
            };

            let render_loc = (location - window.geometry().loc).to_physical_precise_round(output_scale);

            elements.extend(window
                .render_elements::<WaylandSurfaceRenderElement<R>>(
                    renderer,
                    render_loc,
                    Scale::from(output_scale),
                    0.85,
                ).into_iter().map(CustomRenderElements::Surface)
            );
        }

        // layer shell bottom and background
        for layer in [Layer::Bottom, Layer::Background] {
            for layer_surface in layer_map.layers_on(layer) {
                let layout_rec = layer_map.layer_geometry(layer_surface).unwrap();
                elements.extend(
                    layer_surface.render_elements::<WaylandSurfaceRenderElement<R>>(
                        renderer,
                        (layout_rec.loc + output_geo.loc).to_physical_precise_round(output_scale),
                        Scale::from(output_scale),
                        1.0,
                    ).into_iter().map(CustomRenderElements::Surface),
                );
            }
        }

        elements
    }

    pub fn get_cursor_render_elements<R: MondrianRenderer>(
        &self,
        renderer: &mut R,
        output_manager: &OutputManager,
        cursor_manager: &mut CursorManager,
        input_manager: &InputManager,
    ) -> Vec<CustomRenderElements<R>> {
        let _span = tracy_client::span!("get_cursor_render_elements");

        cursor_manager.check_cursor_image_surface_alive();

        let output = output_manager.current_output();
        let output_scale = output.current_scale();

        let output_geo = match output_manager.output_geometry(&output) {
            Some(g) => g,
            None => {
                warn!("Failed to get output {:?} geometry", output);
                return vec![];
            }
        };
        let output_pos = output_geo.loc;

        let pointer = input_manager.get_pointer();
        let pointer = match pointer {
            Some(k) => k,
            None => {
                return vec![];
            }
        };

        let pointer_pos = pointer.current_location();
        let pointer_pos = pointer_pos - output_pos.to_f64();

        let cursor_scale = output_scale.integer_scale();
        let render_cursor = cursor_manager.get_render_cursor(cursor_scale);

        let output_scale = Scale::from(output_scale.fractional_scale());

        let pointer_render_elements: Vec<CustomRenderElements<R>> = match render_cursor {
            RenderCursor::Hidden => vec![],
            RenderCursor::Surface { hotspot, surface } => {
                let real_pointer_pos =
                    (pointer_pos - hotspot.to_f64()).to_physical_precise_round(output_scale);

                render_elements_from_surface_tree(
                    renderer,
                    &surface,
                    real_pointer_pos,
                    output_scale,
                    1.0,
                    Kind::Cursor,
                )
            }
            RenderCursor::Named {
                icon,
                scale,
                cursor,
            } => {
                let (idx, frame) = cursor.frame(self.start_time.elapsed().as_millis() as u32);
                let hotspot = XCursor::hotspot(frame).to_logical(scale);
                let pointer_pos =
                    (pointer_pos - hotspot.to_f64()).to_physical_precise_round(output_scale);

                let texture = cursor_manager
                    .cursor_texture_cache
                    .get(icon, scale, &cursor, idx);
                let mut pointer_elements = vec![];
                let pointer_element = match MemoryRenderBufferRenderElement::from_buffer(
                    renderer,
                    pointer_pos,
                    &texture,
                    None,
                    None,
                    None,
                    Kind::Cursor,
                ) {
                    Ok(element) => Some(element),
                    Err(err) => {
                        warn!("error importing a cursor texture: {err:?}");
                        None
                    }
                };
                if let Some(element) = pointer_element {
                    pointer_elements.push(CustomRenderElements::NamedPointer(element));
                }
                pointer_elements
            }
        };
        pointer_render_elements
    }

    pub fn get_border_render_elements<R: MondrianRenderer>(
        &self,
        renderer: &mut R,
        input_manager: &InputManager,
    ) -> Vec<CustomRenderElements<R>> {
        let _span = tracy_client::span!("get_border_render_elements");

        let mut elements: Vec<CustomRenderElements<R>> = vec![];

        if let Some(KeyboardFocusTarget::Window(window)) = input_manager.get_keyboard_focus() {
            let window_rec = match self.animations.get(&window) {
                Some(animation) => animation.current_value(),
                None => window.get_rect(),
            };

            let program = renderer
                .as_gles_renderer()
                .egl_context()
                .user_data()
                .get::<BorderShader>()
                .unwrap()
                .0
                .clone();

            let point = window_rec.size.to_point();

            // Colors are 24 bits with 8 bits for each red, green, blue value.
            // To get each color, shift the bits over by the offset and zero
            // out the other colors. The bitwise AND 255 does this because it will
            // zero out everything but the last 8 bits. This is where the color
            // has been shifted to.

            let border_color: Color32F = Color32F::from([0.0, 0.0, 1.0, 1.0]);
            let border_thickness = 5.0;

            elements.push(CustomRenderElements::Shader(ShaderRenderElement::Border(
                BorderRenderElement::new(
                    program,
                    window_rec,
                    None,
                    1.0,
                    vec![
                        Uniform::new("u_resolution", (point.x as f32, point.y as f32)),
                        Uniform::new(
                            "border_color",
                            (border_color.r(), border_color.g(), border_color.b()),
                        ),
                        Uniform::new("border_thickness", border_thickness),
                        Uniform::new(
                            "u_time",
                            self.start_time.elapsed().as_secs_f32() % (2.0 * 3.1415926),
                        ), // TODO: just a test
                        Uniform::new("corner_radius", 10.0),
                    ],
                    Kind::Unspecified,
                ),
            )));
        }

        elements
    }

    pub fn _get_background_render_elements<R: MondrianRenderer>(
        &self,
        renderer: &mut R,
        output_manager: &OutputManager,
    ) -> Vec<CustomRenderElements<R>> {
        let mut elements: Vec<CustomRenderElements<R>> = vec![];

        let program = renderer
            .as_gles_renderer()
            .egl_context()
            .user_data()
            .get::<Background>()
            .unwrap()
            .0
            .clone();

        let output_geo = output_manager
            .output_geometry(output_manager.current_output())
            .unwrap();
        let point = output_geo.size.to_point();

        elements.push(CustomRenderElements::Shader(
            ShaderRenderElement::Background(BackgroundRenderElement::new(
                program,
                output_geo,
                None,
                1.0,
                vec![
                    Uniform::new("u_resolution", (point.x as f32, point.y as f32)),
                    Uniform::new(
                        "u_time",
                        self.start_time.elapsed().as_secs_f32() % (2.0 * 3.1415926),
                    ), // TODO: just a test
                ],
                Kind::Unspecified,
            )),
        ));

        elements
    }

    pub fn add_animation(
        &mut self,
        window: Window,
        from: Rectangle<i32, Logical>,
        to: Rectangle<i32, Logical>,
        duration: Duration,
        animation_type: AnimationType,
    ) {
        let animation = Animation::new(from, to, duration, animation_type);
        self.animations.insert(window, animation);
    }

    pub fn refresh(&mut self, output_manager: &OutputManager) {
        let output = output_manager.current_output();

        if let Some(fullscreen_data) = output
            .user_data()
            .get::<FullscreenSurface>()
        {
            if let Some((window, layer_surfaces)) = fullscreen_data.get() {
                if !window.alive() {

                    let mut map = layer_map_for_output(output);
                    for layer_surface in &layer_surfaces {
                        map.map_layer(layer_surface).unwrap();
                    }
                    fullscreen_data.clear();
                }
            }
        }

        // clean dead animations
        self.animations
            .retain(|_, animation| !matches!(animation.state, AnimationState::Completed));
    }
}
