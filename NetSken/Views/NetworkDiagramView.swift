//
//  NetworkDiagramView.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

protocol NetworkDiagramViewDelegate: AnyObject {
    func networkDiagramView(_ view: NetworkDiagramView, didSelectDevice device: DeviceModel)
    func networkDiagramView(_ view: NetworkDiagramView, didDoubleClickDevice device: DeviceModel)
}

class NetworkDiagramView: NSView {
    
    weak var delegate: NetworkDiagramViewDelegate?
    
    private var devices: [DeviceModel] = []
    private var selectedDevice: DeviceModel?
    private var deviceViews: [String: DeviceIconView] = [:]
    private var connectionPaths: [NSBezierPath] = []
    
    // Layout constants matching screenshot
    private let deviceIconSize: CGSize = CGSize(width: 80, height: 80)
    private let connectionLineWidth: CGFloat = 2.0
    private let connectionColor = NSColor.systemGray
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0).cgColor
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove old tracking areas
        trackingAreas.forEach { removeTrackingArea($0) }
        
        // Add new tracking area
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - Public Methods
    func updateDevices(_ newDevices: [DeviceModel]) {
        devices = newDevices
        layoutDevices()
        createDeviceViews()
        needsDisplay = true
    }
    
    private func layoutDevices() {
        guard !devices.isEmpty else { return }
        
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        // Find router (gateway) device
        let router = devices.first { $0.deviceType == .router }
        
        // Position router at top center (matching screenshot)
        router?.position = CGPoint(x: centerX, y: centerY + 150)
        
        // Position other devices in a horizontal line below router
        let otherDevices = devices.filter { $0.deviceType != .router }
        let deviceSpacing: CGFloat = 150
        let totalWidth = CGFloat(otherDevices.count - 1) * deviceSpacing
        let startX = centerX - totalWidth / 2
        
        for (index, device) in otherDevices.enumerated() {
            device.position = CGPoint(
                x: startX + CGFloat(index) * deviceSpacing,
                y: centerY - 50
            )
        }
        
        // Create connection paths
        createConnectionPaths()
    }
    
    private func createConnectionPaths() {
        connectionPaths.removeAll()
        
        guard let router = devices.first(where: { $0.deviceType == .router }) else { return }
        
        let otherDevices = devices.filter { $0.deviceType != .router }
        
        for device in otherDevices {
            let path = NSBezierPath()
            path.move(to: router.position)
            path.line(to: device.position)
            connectionPaths.append(path)
        }
    }
    
    private func createDeviceViews() {
        // Remove existing device views
        deviceViews.values.forEach { $0.removeFromSuperview() }
        deviceViews.removeAll()
        
        // Create new device views
        for device in devices {
            let deviceView = DeviceIconView(device: device)
            deviceView.frame = CGRect(
                x: device.position.x - deviceIconSize.width / 2,
                y: device.position.y - deviceIconSize.height / 2,
                width: deviceIconSize.width,
                height: deviceIconSize.height
            )
            
            deviceView.delegate = self
            addSubview(deviceView)
            deviceViews[device.identifier] = deviceView
        }
    }
    
    // MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Draw connections
        connectionColor.setStroke()
        
        for path in connectionPaths {
            let styledPath = NSBezierPath()
            styledPath.append(path)
            styledPath.lineWidth = connectionLineWidth
            styledPath.stroke()
        }
    }
    
    // MARK: - Mouse Events
    override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        
        // Check if click is on a device
        for (identifier, deviceView) in deviceViews {
            if deviceView.frame.contains(localPoint) {
                if let device = devices.first(where: { $0.identifier == identifier }) {
                    selectDevice(device)
                    return
                }
            }
        }
        
        // Click on empty space - deselect
        selectDevice(nil)
    }
    
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            // Double click
            let localPoint = convert(event.locationInWindow, from: nil)
            
            for (identifier, deviceView) in deviceViews {
                if deviceView.frame.contains(localPoint) {
                    if let device = devices.first(where: { $0.identifier == identifier }) {
                        delegate?.networkDiagramView(self, didDoubleClickDevice: device)
                        return
                    }
                }
            }
        }
    }
    
    private func selectDevice(_ device: DeviceModel?) {
        // Update selection state
        selectedDevice = device
        
        // Update device view selection states
        for (identifier, deviceView) in deviceViews {
            deviceView.isSelected = (identifier == device?.identifier)
        }
        
        // Notify delegate
        if let device = device {
            delegate?.networkDiagramView(self, didSelectDevice: device)
        }
    }
}

// MARK: - DeviceIconViewDelegate
extension NetworkDiagramView: DeviceIconViewDelegate {
    
    func deviceIconView(_ view: DeviceIconView, didSelectDevice device: DeviceModel) {
        selectDevice(device)
    }
    
    func deviceIconView(_ view: DeviceIconView, didDoubleClickDevice device: DeviceModel) {
        delegate?.networkDiagramView(self, didDoubleClickDevice: device)
    }
}