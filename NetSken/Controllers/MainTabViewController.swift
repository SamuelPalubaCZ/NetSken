//
//  MainTabViewController.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

class MainTabViewController: NSTabViewController {
    
    private var scanNetworkVC: ScanNetworkViewController?
    private var advancedScansVC: AdvancedScansViewController?
    private var optionsVC: OptionsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabView()
        setupTabs()
    }
    
    private func setupTabView() {
        // Configure tab view style to match screenshot
        tabView.tabViewType = .topTabsBezelBorder
        tabView.controlSize = .regular
        
        // Tab view appearance
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0).cgColor
        
        // Remove default background
        tabView.drawsBackground = false
    }
    
    private func setupTabs() {
        // Create view controllers
        scanNetworkVC = ScanNetworkViewController()
        advancedScansVC = AdvancedScansViewController()
        optionsVC = OptionsViewController()
        
        // Create tab view items
        let scanNetworkTab = NSTabViewItem(viewController: scanNetworkVC!)
        scanNetworkTab.label = "Scan Network"
        
        let advancedScansTab = NSTabViewItem(viewController: advancedScansVC!)
        advancedScansTab.label = "Advanced Scans"
        
        let optionsTab = NSTabViewItem(viewController: optionsVC!)
        optionsTab.label = "Options"
        
        // Add tabs to tab view
        addTabViewItem(scanNetworkTab)
        addTabViewItem(advancedScansTab)
        addTabViewItem(optionsTab)
        
        // Select first tab (Scan Network) by default
        tabView.selectTabViewItem(scanNetworkTab)
    }
    
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        return true
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        // Handle tab selection changes if needed
        guard let item = tabViewItem else { return }
        
        // Update any shared state based on selected tab
        switch item.label {
        case "Scan Network":
            // Handle scan network tab selection
            break
        case "Advanced Scans":
            // Handle advanced scans tab selection
            break
        case "Options":
            // Handle options tab selection
            break
        default:
            break
        }
    }
}