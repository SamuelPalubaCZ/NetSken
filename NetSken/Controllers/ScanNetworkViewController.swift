//
//  ScanNetworkViewController.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

class ScanNetworkViewController: NSViewController {
    
    private var networkDiagramView: NetworkDiagramView?
    private var networkManager: NetworkManager?
    
    override func loadView() {
        // Create the main view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0).cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNetworkManager()
        setupNetworkDiagramView()
        loadInitialData()
    }
    
    private func setupNetworkManager() {
        networkManager = NetworkManager.shared
    }
    
    private func setupNetworkDiagramView() {
        // Create network diagram view
        networkDiagramView = NetworkDiagramView()
        
        guard let diagramView = networkDiagramView else { return }
        
        // Add to view hierarchy
        view.addSubview(diagramView)
        
        // Setup constraints
        diagramView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            diagramView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            diagramView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            diagramView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            diagramView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Set delegate
        diagramView.delegate = self
    }
    
    private func loadInitialData() {
        // Load sample data matching the screenshot
        let sampleDevices = createSampleDevices()
        networkDiagramView?.updateDevices(sampleDevices)
    }
    
    private func createSampleDevices() -> [DeviceModel] {
        var devices: [DeviceModel] = []
        
        // Router (gateway)
        let router = DeviceModel(
            identifier: "router-1",
            ipAddress: "192.168.1.1",
            macAddress: "00:11:22:33:44:55",
            hostname: "Router",
            deviceType: .router,
            vendor: "Unknown",
            status: .online
        )
        devices.append(router)
        
        // MacBook
        let macbook = DeviceModel(
            identifier: "macbook-1",
            ipAddress: "192.168.1.10",
            macAddress: "aa:bb:cc:dd:ee:ff",
            hostname: "MacBook",
            deviceType: .computer,
            vendor: "Apple",
            status: .online
        )
        devices.append(macbook)
        
        // Printer
        let printer = DeviceModel(
            identifier: "printer-1",
            ipAddress: "192.168.1.20",
            macAddress: "11:22:33:44:55:66",
            hostname: "Printer",
            deviceType: .printer,
            vendor: "HP",
            status: .online
        )
        devices.append(printer)
        
        // iPhone (Critical status)
        let iphone = DeviceModel(
            identifier: "iphone-1",
            ipAddress: "192.168.1.30",
            macAddress: "77:88:99:aa:bb:cc",
            hostname: "iPhone",
            deviceType: .mobile,
            vendor: "Apple",
            status: .critical
        )
        devices.append(iphone)
        
        // Server
        let server = DeviceModel(
            identifier: "server-1",
            ipAddress: "192.168.1.40",
            macAddress: "dd:ee:ff:00:11:22",
            hostname: "Server",
            deviceType: .server,
            vendor: "Dell",
            status: .online
        )
        devices.append(server)
        
        return devices
    }
}

// MARK: - NetworkDiagramViewDelegate
extension ScanNetworkViewController: NetworkDiagramViewDelegate {
    
    func networkDiagramView(_ view: NetworkDiagramView, didSelectDevice device: DeviceModel) {
        // Handle device selection
        print("Selected device: \(device.hostname)")
        
        // Show device details or perform action
        showDeviceDetails(device)
    }
    
    func networkDiagramView(_ view: NetworkDiagramView, didDoubleClickDevice device: DeviceModel) {
        // Handle device double-click
        print("Double-clicked device: \(device.hostname)")
        
        // Perform detailed scan or show properties
        performDetailedScan(device)
    }
    
    private func showDeviceDetails(_ device: DeviceModel) {
        // TODO: Show device details panel or popover
    }
    
    private func performDetailedScan(_ device: DeviceModel) {
        // TODO: Trigger detailed vulnerability scan
    }
}