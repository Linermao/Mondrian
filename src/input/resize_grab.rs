use std::cell::RefCell;

use smithay::{
    desktop::Window,
    input::pointer::{CursorImageStatus, GrabStartData as PointerGrabStartData, PointerGrab},
    reexports::{
        wayland_protocols::xdg::shell::server::xdg_toplevel,
        wayland_server::protocol::wl_surface::WlSurface,
    },
    utils::{Logical, Point, Rectangle, Size},
    wayland::{compositor, shell::xdg::SurfaceCachedState},
};

use crate::{space::workspace::WorkspaceManager, state::NuonuoState};

bitflags::bitflags! {
  #[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
  pub struct ResizeEdge: u32 {
      const TOP          = 0b0001;
      const BOTTOM       = 0b0010;
      const LEFT         = 0b0100;
      const RIGHT        = 0b1000;

      const TOP_LEFT     = Self::TOP.bits() | Self::LEFT.bits();
      const BOTTOM_LEFT  = Self::BOTTOM.bits() | Self::LEFT.bits();

      const TOP_RIGHT    = Self::TOP.bits() | Self::RIGHT.bits();
      const BOTTOM_RIGHT = Self::BOTTOM.bits() | Self::RIGHT.bits();
  }
}

impl From<xdg_toplevel::ResizeEdge> for ResizeEdge {
    #[inline]
    fn from(x: xdg_toplevel::ResizeEdge) -> Self {
        Self::from_bits(x as u32).unwrap()
    }
}

/// State of the resize operation.
///
/// It is stored inside of WlSurface,
/// and can be accessed using [`ResizeSurfaceState::with`]
#[derive(Debug, Clone, Copy, Eq, PartialEq, Default)]
enum ResizeSurfaceState {
    #[default]
    Idle,
    Resizing {
        edges: ResizeEdge,
        /// The initial window size and location.
        initial_rect: Rectangle<i32, Logical>,
    },
    /// Resize is done, we are now waiting for last commit, to do the final move
    WaitingForLastCommit {
        edges: ResizeEdge,
        /// The initial window size and location.
        initial_rect: Rectangle<i32, Logical>,
    },
}

impl ResizeSurfaceState {
    fn with<F, T>(surface: &WlSurface, cb: F) -> T
    where
        F: FnOnce(&mut Self) -> T,
    {
        compositor::with_states(surface, |states| {
            states.data_map.insert_if_missing(RefCell::<Self>::default);
            let state = states.data_map.get::<RefCell<Self>>().unwrap();
            cb(&mut state.borrow_mut())
        })
    }

    fn commit(&mut self) -> Option<(ResizeEdge, Rectangle<i32, Logical>)> {
        match *self {
            Self::Resizing {
                edges,
                initial_rect,
            } => Some((edges, initial_rect)),
            Self::WaitingForLastCommit {
                edges,
                initial_rect,
            } => {
                // The resize is done, let's go back to idle
                *self = Self::Idle;
                Some((edges, initial_rect))
            }
            Self::Idle => None,
        }
    }
}

pub struct ResizeSurfaceGrab {
    start_data: PointerGrabStartData<NuonuoState>,
    window: Window,
    edges: ResizeEdge,
    initial_rect: Rectangle<i32, Logical>,
    last_window_size: Size<i32, Logical>,
}

impl ResizeSurfaceGrab {
    pub fn start(
        start_data: PointerGrabStartData<NuonuoState>,
        window: Window,
        edges: ResizeEdge,
        initial_rect: Rectangle<i32, Logical>,
    ) -> Self {
        ResizeSurfaceState::with(window.toplevel().unwrap().wl_surface(), |state| {
            *state = ResizeSurfaceState::Resizing {
                edges,
                initial_rect,
            };
        });

        Self {
            start_data,
            window,
            edges,
            initial_rect,
            last_window_size: initial_rect.size,
        }
    }
}

impl PointerGrab<NuonuoState> for ResizeSurfaceGrab {
    fn start_data(&self) -> &PointerGrabStartData<NuonuoState> {
        &self.start_data
    }

    fn unset(&mut self, state: &mut NuonuoState) {
        state.cursor_manager.set_cursor_image(
            CursorImageStatus::default_named()
        );
    }

    fn motion(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        _focus: Option<(
            <NuonuoState as smithay::input::SeatHandler>::PointerFocus,
            smithay::utils::Point<f64, Logical>,
        )>,
        event: &smithay::input::pointer::MotionEvent,
    ) {
        handle.motion(data, None, event);

        let mut delta = event.location - self.start_data.location;

        let mut new_window_width = self.initial_rect.size.w;
        let mut new_window_height = self.initial_rect.size.h;

        if self.edges.intersects(ResizeEdge::LEFT | ResizeEdge::RIGHT) {
            if self.edges.intersects(ResizeEdge::LEFT) {
                delta.x = -delta.x
            }
            new_window_width = (self.initial_rect.size.w as f64 + delta.x) as i32;
        }
        if self.edges.intersects(ResizeEdge::TOP | ResizeEdge::BOTTOM) {
            if self.edges.intersects(ResizeEdge::TOP) {
                delta.y = -delta.y;
            }
            new_window_height = (self.initial_rect.size.h as f64 + delta.y) as i32;
        }

        let (min_size, max_size) =
            compositor::with_states(self.window.toplevel().unwrap().wl_surface(), |states| {
                let mut guard = states.cached_state.get::<SurfaceCachedState>();
                let data = guard.current();
                (data.min_size, data.max_size)
            });

        let min_width = min_size.w.max(1);
        let min_height = min_size.h.max(1);

        let max_width = (max_size.w == 0).then(i32::max_value).unwrap_or(max_size.w);
        let max_height = (max_size.h == 0).then(i32::max_value).unwrap_or(max_size.h);

        self.last_window_size = Size::from((
            new_window_width.max(min_width).min(max_width),
            new_window_height.max(min_height).min(max_height),
        ));

        let xdg = self.window.toplevel().unwrap();
        xdg.with_pending_state(|state| {
            state.states.set(xdg_toplevel::State::Resizing);
            state.size = Some(self.last_window_size);
        });

        xdg.send_pending_configure();
    }

    fn relative_motion(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        focus: Option<(
            <NuonuoState as smithay::input::SeatHandler>::PointerFocus,
            smithay::utils::Point<f64, Logical>,
        )>,
        event: &smithay::input::pointer::RelativeMotionEvent,
    ) {
        handle.relative_motion(data, focus, event);
    }

    fn button(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::ButtonEvent,
    ) {
        handle.button(data, event);

        // The button is a button code as defined in the
        // Linux kernel's linux/input-event-codes.h header file, e.g. BTN_LEFT.
        const BTN_LEFT: u32 = 0x110;

        if !handle.current_pressed().contains(&BTN_LEFT) {
            handle.unset_grab(self, data, event.serial, event.time, true);

            let xdg = self.window.toplevel().unwrap();
            xdg.with_pending_state(|state| {
                state.states.unset(xdg_toplevel::State::Resizing);
                state.size = Some(self.last_window_size);
            });

            xdg.send_pending_configure();

            ResizeSurfaceState::with(xdg.wl_surface(), |state| {
                *state = ResizeSurfaceState::WaitingForLastCommit {
                    edges: self.edges,
                    initial_rect: self.initial_rect,
                };
            });
        }
    }

    fn axis(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        details: smithay::input::pointer::AxisFrame,
    ) {
        handle.axis(data, details);
    }

    fn frame(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
    ) {
        handle.frame(data);
    }

    fn gesture_swipe_begin(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GestureSwipeBeginEvent,
    ) {
        handle.gesture_swipe_begin(data, event);
    }

    fn gesture_swipe_update(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GestureSwipeUpdateEvent,
    ) {
        handle.gesture_swipe_update(data, event);
    }

    fn gesture_swipe_end(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GestureSwipeEndEvent,
    ) {
        handle.gesture_swipe_end(data, event);
    }

    fn gesture_pinch_begin(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GesturePinchBeginEvent,
    ) {
        handle.gesture_pinch_begin(data, event);
    }

    fn gesture_pinch_update(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GesturePinchUpdateEvent,
    ) {
        handle.gesture_pinch_update(data, event);
    }

    fn gesture_pinch_end(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GesturePinchEndEvent,
    ) {
        handle.gesture_pinch_end(data, event);
    }

    fn gesture_hold_begin(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GestureHoldBeginEvent,
    ) {
        handle.gesture_hold_begin(data, event);
    }

    fn gesture_hold_end(
        &mut self,
        data: &mut NuonuoState,
        handle: &mut smithay::input::pointer::PointerInnerHandle<'_, NuonuoState>,
        event: &smithay::input::pointer::GestureHoldEndEvent,
    ) {
        handle.gesture_hold_end(data, event);
    }
}

pub fn handle_commit(workspace_manager: &mut WorkspaceManager, surface: &WlSurface) -> Option<()> {
    let window = workspace_manager
        .current_workspace()
        .elements()
        .find(|w| w.toplevel().unwrap().wl_surface() == surface)
        .cloned()?;

    let mut window_loc = workspace_manager.current_workspace().element_location(&window);
    let geometry = window.geometry();

    let new_loc: Point<Option<i32>, Logical> = ResizeSurfaceState::with(surface, |state| {
        state
            .commit()
            .and_then(|(edges, initial_rect)| {
                // If the window is being resized by top or left, its location must be adjusted
                // accordingly.
                edges.intersects(ResizeEdge::TOP_LEFT).then(|| {
                    let new_x = edges
                        .intersects(ResizeEdge::LEFT)
                        .then_some(initial_rect.loc.x + (initial_rect.size.w - geometry.size.w));
                    let new_y = edges
                        .intersects(ResizeEdge::TOP)
                        .then_some(initial_rect.loc.y + (initial_rect.size.h - geometry.size.h));
                    (new_x, new_y).into()
                })
            })
            .unwrap_or_default()
    });

    if let Some(new_x) = new_loc.x {
        window_loc.x = new_x;
    }
    if let Some(new_y) = new_loc.y {
        window_loc.y = new_y;
    }

    if new_loc.x.is_some() || new_loc.y.is_some() {
        // If TOP or LEFT side of the window got resized, we have to move it
        workspace_manager.current_workspace_mut().map_element(window, window_loc, false);
    }
    Some(())
}

