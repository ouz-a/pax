//
//  ContentView.swift
//  pax-dev-harness-macos
//
//  Created by Zachary Brown on 4/6/22.
//

import SwiftUI

let FPS = 60.0
let REFRESH_PERIOD = 1.0/FPS //seconds between frames (e.g. 16.667 for 60Hz)

struct ContentView: View {
    var body: some View {
        CanvasViewRepresentable()
            .frame(minWidth: 300, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
    }
}


//see: https://medium.com/codex/swift-c-callback-interoperability-6d57da6c8ee6
//typealias LoggerCallback = @convention(c) (
//    UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
//) -> ()

struct CanvasViewRepresentable: NSViewRepresentable {
    typealias NSViewType = CanvasView
    
    func makeNSView(context: Context) -> CanvasView {
        return CanvasView()
    }
    
    func updateNSView(_ canvas: CanvasView, context: Context) {
    }
}

//func logger(cString: UnsafeMutablePointer<CChar>?) {
//    let outputString = String(cString: cString!)
//    print(outputString)
//}

class CanvasView: NSView {
    
    var contextContainer : OpaquePointer? = nil
    var tickWorkItem : DispatchWorkItem? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current else { return }
        var cgContext = context.cgContext
        
        if contextContainer == nil {
            
//            let callbackClosure : LoggerCallback = { msg in
//                let outputString = String(cString: msg!)
//                print(outputString)
//            }
            
            
            let swiftCallback : @convention(c) (UnsafePointer<CChar>?) -> () = {
                (msg) -> () in
                let outputString = String(cString: msg!)
                print(outputString)
            }
            
            
//            let basicCallback : @convention(c) () -> () = {
//                () -> () in
//                
//                print("unary thunk!")
//            }

            contextContainer = pax_init(swiftCallback)
        } else {
            pax_tick(contextContainer!, &cgContext, CFloat(dirtyRect.width), CFloat(dirtyRect.height))
        }

        //This DispatchWorkItem `cancel()` is required because sometimes `draw` will be triggered externally, which
        //would otherwise create new families of DispatchWorkItems, each ticking up a frenzy, well past the bounds of our target FPS.
        //This cancellation + shared singleton (`tickWorkItem`) ensures that only one DispatchWorkItem is enqueued at a time.
        if tickWorkItem != nil {
            tickWorkItem!.cancel()
        }
        
        tickWorkItem = DispatchWorkItem {
            self.setNeedsDisplay(dirtyRect)
            self.displayIfNeeded()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + REFRESH_PERIOD, execute: tickWorkItem!)
        
    }
}
