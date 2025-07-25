//
//  MainWindowController.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    private var tabViewController: MainTabViewController?
    
    convenience init() {
        // Create window with specific style matching screenshot
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 768),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        setupWindow()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        setupTabViewController()
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        // Window appearance matching screenshot
        window.title = "Network Scanner"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        
        // Center window on screen
        window.center()
        
        // Set minimum size
        window.minSize = NSSize(width: 800, height: 600)
        
        // Background color matching screenshot
        window.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0) // #F5F5F5
        
        // Enable full size content view
        window.titlebarAppearsTransparent = false
        
        // Set window delegate
        window.delegate = self
    }
    
    private func setupTabViewController() {
        guard let window = window else { return }
        
        // Create main tab view controller
        tabViewController = MainTabViewController()
        
        // Set as window's content view controller
        window.contentViewController = tabViewController
    }
}

// MARK: - Window Delegate
extension MainWindowController: NSWindowDelegate {
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(nil)
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(nil)
    }
}