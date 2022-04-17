#![allow(non_snake_case)]

use std::rc::Rc;
use std::cell::RefCell;
use std::ffi::{CStr, CString};
use std::mem::ManuallyDrop;
use std::os::raw::c_char;

use pax_cartridge_runtime;

use core_graphics::context::CGContext;
use piet_coregraphics::{CoreGraphicsContext};

use pax_core::{InstanceMap, PaxEngine};

#[repr(C)]
pub struct PaxChassisMacosBridgeContainer {
    _engine: *mut PaxEngine<CoreGraphicsContext<'static>>,
}

//Exposed to Swift via paxchassismacos.h
#[no_mangle]
pub extern "C" fn pax_init(logger: extern "C" fn(*const c_char)) -> *mut PaxChassisMacosBridgeContainer {

    //Initialize a ManuallyDrop-contained PaxEngine, so that a pointer to that
    //engine can be passed back to Swift via the C (FFI) bridge
    //This could presumably be cleaned up but currently the engine will exist
    //on the heap for the lifetime of the containing process.

    // let x = |msg:&str| {  }



    let msg = CString::new("Hello from rust!!").unwrap();
    unsafe {(logger)(msg.as_ptr())};

    let instance_map : Rc<RefCell<InstanceMap<CoreGraphicsContext<'static>>>> = Rc::new(RefCell::new(std::collections::HashMap::new()));
    let root_component_instance = pax_cartridge_runtime::instantiate_root_component(Rc::clone(&instance_map));
    let expression_table = pax_cartridge_runtime::instantiate_expression_table();

    let engine : ManuallyDrop<Box<PaxEngine<CoreGraphicsContext<'static>>>> = ManuallyDrop::new(
        Box::new(
           PaxEngine::new(
                root_component_instance,
                expression_table,
                |msg|{
                    // msg.
                    // unsafe {*logger(msg.into())}
                },
                (1.0, 1.0),
                Rc::new(RefCell::new(Default::default()))
           )
        )
    );

    let container = ManuallyDrop::new(Box::new(PaxChassisMacosBridgeContainer {
        _engine: Box::into_raw(ManuallyDrop::into_inner(engine)),
    }));

    Box::into_raw(ManuallyDrop::into_inner(container))
}

//Exposed to Swift via paxchassismacos.h
#[no_mangle]
pub extern fn pax_tick(bridge_container: *mut PaxChassisMacosBridgeContainer, cgContext: *mut CGContext, width: f32, height: f32) { // note that f32 is essentially `CFloat`, per: https://doc.rust-lang.org/std/os/raw/type.c_float.html
    let mut engine = unsafe { Box::from_raw((*bridge_container)._engine) };
    let ctx = unsafe { &mut *cgContext };
    let mut render_context = CoreGraphicsContext::new_y_up(ctx, height as f64, None);
    (*engine).set_viewport_size((width as f64, height as f64));
    (*engine).tick(&mut render_context);

    //This step is necessary to clean up engine, e.g. to drop all of the RefCell::borrow_mut's throughout
    unsafe {(*bridge_container)._engine=  Box::into_raw(engine)}

}
