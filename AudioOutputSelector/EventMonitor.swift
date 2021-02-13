//
//  EventMonitor.swift
//  AudioOutputSelector
//
//  Created by Gabriel Soria Souza on 13/02/21.
//

import Cocoa

final class EventMonitor {
    
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: ((NSEvent?) -> Void)
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping ((NSEvent?) -> Void)) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        self.stop()
    }
    
    func start() {
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: self.mask, handler: self.handler)
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(self.monitor!)
            monitor = nil
        }
    }
}
