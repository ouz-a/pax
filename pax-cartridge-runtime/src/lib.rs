use std::borrow::{Borrow, BorrowMut};
use std::cell::RefCell;
use std::collections::HashMap;
use std::ops::Deref;
use std::rc::Rc;
use pax_core::{ComponentInstance, PropertyExpression, RenderNodePtrList, RenderTreeContext, ExpressionContext, PaxEngine, RenderNode, InstanceMap, HandlerRegistry, InstantiationArgs};
use pax_core::pax_properties_coproduct::{PropertiesCoproduct, TypesCoproduct};
use pax_core::repeat::{RepeatInstance};

use pax_runtime_api::{ArgsCoproduct, Property, PropertyLiteral, Transform};

//generate dependencies, pointing to userland cartridge (same logic as in PropertiesCoproduct)
use pax_example::pax_types::{RootProperties};
use pax_example::pax_types::pax_std::primitives::{GroupProperties, RectangleProperties};
use pax_example::pax_types::pax_std::types::{Color, StrokeProperties, Size};

//dependency paths below come from pax_primitive macro, where these crate+module paths are passed as parameters:
use pax_std_primitives::{RectangleInstance, GroupInstance };


pub fn instantiate_expression_table() -> HashMap<String, Box<dyn Fn(ExpressionContext) -> TypesCoproduct>> {
    let mut map : HashMap<String, Box<dyn Fn(ExpressionContext) -> TypesCoproduct>> = HashMap::new();

    //literal string IDs to be generated by compiler

    //note that type coercion should happen here, too:
    //(must know symbol name as well as source & destination types)
    //(compiler can keep a dict of operand types)

    map.insert("a".to_string(), Box::new(|ec: ExpressionContext| -> TypesCoproduct {
        let (datum, i) = if let PropertiesCoproduct::RepeatItem(datum, i) = &*(*(*(*ec.stack_frame).borrow().get_scope()).borrow().properties).borrow() {
            let x = (*ec.engine).borrow();
            (*x.runtime).borrow().log(&format!("expressing i: {}", i));
            (Rc::clone(datum), *i)
        } else { unreachable!() };

        #[allow(non_snake_case)]
        let __AT__frames_elapsed = ec.engine.frames_elapsed as f64;
        let i = i as f64;

        return TypesCoproduct::Transform(
            Transform::align(0.5, 0.5) *
            Transform::origin( Size::Percent(50.0), Size::Percent(50.0)) *
            Transform::rotate(__AT__frames_elapsed * i / 100.0) *
            Transform::translate( i * 10.0, i * 10.0) *
            Transform::rotate(__AT__frames_elapsed / 50.0)

        )
        // } else {unreachable!()};

    }));


    map.insert("c".to_string(), Box::new(|ec: ExpressionContext| -> TypesCoproduct {
        #[allow(non_snake_case)]
        let __AT__frames_elapsed = ec.engine.frames_elapsed as f64;
        #[allow(non_snake_case)]
        let self__DOT__rotation = if let PropertiesCoproduct::Root(p) = &*(*(*(*ec.stack_frame).borrow().get_scope()).borrow().properties).borrow() {
            *p.current_rotation.get()
        } else { unreachable!() };

        //TODO: how to determine that StrokeProperties is compound and requires
        //      wrapping in PropertyLiteral values?
        TypesCoproduct::Stroke(
            StrokeProperties {
                color: Box::new(PropertyLiteral (Color::hlca((__AT__frames_elapsed as isize % 360) as f64, 100.0,100.0,1.0) )),
                width: Box::new(PropertyLiteral (45.0)),
            }
        )
    }));

    map
}

pub fn instantiate_root_component(instance_map: Rc<RefCell<InstanceMap>>) -> Rc<RefCell<ComponentInstance>> {
    ComponentInstance::instantiate(
        InstantiationArgs{
            properties: PropertiesCoproduct::Root(RootProperties {
                num_clicks: Box::new(PropertyLiteral(0) ),
                current_rotation: Box::new(PropertyLiteral(0.0)),
                deeper_struct: Default::default(),
            }),
            handler_registry: None,
            instance_map: Rc::clone(&instance_map),
            transform: Transform::default_wrapped(),
            size: None,
            children: Some(Rc::new(RefCell::new(vec![
                GroupInstance::instantiate(InstantiationArgs {
                    properties: PropertiesCoproduct::Empty,
                    handler_registry: None,
                    instance_map: Rc::clone(&instance_map),
                    transform: Transform::default_wrapped(),
                    size: None,
                    adoptees: None,
                    data_list: None,
                    compute_properties_fn: None,
                    children: Some(Rc::new(RefCell::new(vec![
                        // RectangleInstance::instantiate(InstantiationArgs {
                        //     properties: PropertiesCoproduct::Rectangle(RectangleProperties{
                        //         stroke: Box::new(PropertyExpression {id: "c".into(), cached_value: Default::default()}),
                        //         fill: Box::new(PropertyLiteral (Color::rgba(1.0, 1.0, 0.0, 1.0)))
                        //     }),
                        //     handler_registry: None,
                        //     instance_map: Rc::clone(&instance_map),
                        //     transform: Transform::default_wrapped(),
                        //     size: Some([PropertyLiteral(Size::Pixel(200.0)).into(),PropertyLiteral(Size::Pixel(200.0)).into()]),
                        //     children: None,
                        //     adoptees: None,
                        //     data_list: None,
                        //     compute_properties_fn: None
                        // }),
                        RepeatInstance::instantiate(InstantiationArgs {
                            properties: PropertiesCoproduct::Empty,
                            handler_registry: None,
                            instance_map: Rc::clone(&instance_map),
                            transform: Transform::default_wrapped(),
                            size: None,
                            children: Some(Rc::new(RefCell::new(vec![
                                RectangleInstance::instantiate(InstantiationArgs {
                                    properties: PropertiesCoproduct::Rectangle(RectangleProperties{
                                        stroke: Box::new(PropertyLiteral (StrokeProperties {
                                            color: Box::new(PropertyLiteral(Color::rgba(1.0, 0.0, 1.0, 1.0))),
                                            width: Box::new(PropertyLiteral(5.0))
                                        })),
                                        fill: Box::new(PropertyLiteral (Color::rgba(1.0, 1.0, 0.0, 1.0)))
                                    }),
                                    handler_registry: None,
                                    instance_map: Rc::clone(&instance_map),
                                    transform: Rc::new(RefCell::new(PropertyExpression {
                                        id: "a".to_string(),
                                        cached_value: Default::default(),
                                    })),
                                    size: Some([PropertyLiteral(Size::Pixel(200.0)).into(),PropertyLiteral(Size::Pixel(200.0)).into()]),
                                    children: None,
                                    adoptees: None,
                                    data_list: None,
                                    compute_properties_fn: None
                                }),
                            ]))),
                            adoptees: None,
                            data_list: Some(Box::new(PropertyLiteral((0..100).into_iter().map(|d|{Rc::new(PropertiesCoproduct::i64(d))}).collect() ))),
                            compute_properties_fn: None
                        }), 
                    ]))),
                })
            ]))),
            adoptees: None,
            data_list: None,
            compute_properties_fn: Some(Box::new(|properties, rtc|{
                let mut properties = &mut *properties.as_ref().borrow_mut();
                let mut properties = if let PropertiesCoproduct::Root(p) = properties {p} else {unreachable!()};

                if let Some(new_current_rotation) = rtc.get_computed_value(properties.current_rotation._get_vtable_id()) {
                    let new_value = if let TypesCoproduct::f64(v) = new_current_rotation { v } else { unreachable!() };
                    properties.current_rotation.set(new_value);
                }

                if let Some(new_num_clicks) = rtc.get_computed_value(properties.num_clicks._get_vtable_id()) {
                    let new_value = if let TypesCoproduct::i64(v) = new_num_clicks { v } else { unreachable!() };
                    properties.num_clicks.set(new_value);
                }

                if let Some(new_deeper_struct) = rtc.get_computed_value(properties.deeper_struct._get_vtable_id()) {
                    let new_value = if let TypesCoproduct::DeeperStruct(v) = new_deeper_struct { v } else { unreachable!() };
                    properties.deeper_struct.set(new_value);
                }
            }))
        }
    )
}

//Root => get_instance()


//Rectangle => get_instance()
//Group => get_instance()