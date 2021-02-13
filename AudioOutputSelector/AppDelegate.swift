//
//  AppDelegate.swift
//  AudioOutputSelector
//
//  Created by Gabriel Soria Souza on 13/02/21.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var window: NSWindow?
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = self.statusItem?.button {
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        let viewController = AudioOutputSelectorViewController()
        viewController.view.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        self.popover.contentViewController = viewController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover(_ sender: Any?) {
        if self.popover.isShown {
            self.closePopover(sender)
        } else {
            self.showPopover(sender)
        }
    }
    
    private func showPopover(_ sender: Any?) {
        if let button = self.statusItem?.button {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    private func closePopover(_ sender: Any?) {
        self.popover.performClose(sender)
    }
}
