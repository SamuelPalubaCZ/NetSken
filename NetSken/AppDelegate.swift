//
//  AppDelegate.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create main window controller
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)
        
        // Make window key and front
        mainWindowController?.window?.makeKeyAndOrderFront(nil)
        
        // Terminate app when all windows are closed
        NSApp.setActivationPolicy(.regular)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}