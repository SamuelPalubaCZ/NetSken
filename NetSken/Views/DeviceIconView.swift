//
//  DeviceIconView.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

protocol DeviceIconViewDelegate: AnyObject {
    func deviceIconView(_ view: DeviceIconView, didSelectDevice device: DeviceModel)
    func deviceIconView(_ view: DeviceIconView, didDoubleClickDevice device: DeviceModel)
}

class DeviceIconView: NSView {
    
    weak var delegate: DeviceIconViewDelegate?
    
    private let device: DeviceModel
    private let iconSize: CGSize = CGSize(width: 60, height: 60)
    private let cornerRadius: CGFloat = 12.0
    
    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    init(device: DeviceModel) {
        self.device = device
        super.init(frame: NSRect(x: 0, y: 0, width: 80, height: 80))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let iconRect = CGRect(
            x: (bounds.width - iconSize.width) / 2,
            y: bounds.height - iconSize.height - 5,
            width: iconSize.width,
            height: iconSize.height
        )
        
        // Draw device icon
        drawDeviceIcon(in: iconRect)
        
        // Draw device label
        drawDeviceLabel()
        
        // Draw IP address
        drawIPAddress()
        
        // Draw status indicator if critical
        if device.status == .critical {
            drawCriticalIndicator()
        }
        
        // Draw selection highlight
        if isSelected {
            drawSelectionHighlight()
        }
    }
    
    private func drawDeviceIcon(in rect: CGRect) {
        let iconColor = getDeviceColor()
        let iconPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // Fill background
        iconColor.setFill()
        iconPath.fill()
        
        // Draw device symbol
        drawDeviceSymbol(in: rect, color: NSColor.white)
        
        // Draw border for critical devices
        if device.status == .critical {
            NSColor.systemRed.setStroke()
            iconPath.lineWidth = 3.0
            iconPath.stroke()
        }
    }
    
    private func drawDeviceSymbol(in rect: CGRect, color: NSColor) {
        color.setFill()
        color.setStroke()
        
        let symbolRect = rect.insetBy(dx: 15, dy: 15)
        
        switch device.deviceType {
        case .router:
            drawRouterSymbol(in: symbolRect)
        case .computer:
            drawComputerSymbol(in: symbolRect)
        case .mobile:
            drawMobileSymbol(in: symbolRect)
        case .printer:
            drawPrinterSymbol(in: symbolRect)
        case .server:
            drawServerSymbol(in: symbolRect)
        case .iot, .unknown:
            drawGenericSymbol(in: symbolRect)
        }
    }
    
    private func drawRouterSymbol(in rect: CGRect) {
        // Draw router symbol (antenna-like shape)
        let path = NSBezierPath()
        
        // Main body
        let bodyRect = CGRect(x: rect.minX + 5, y: rect.minY + 10, width: rect.width - 10, height: 15)
        path.appendRoundedRect(bodyRect, xRadius: 3, yRadius: 3)
        
        // Antennas
        let antenna1Start = CGPoint(x: rect.minX + 8, y: rect.minY + 25)
        let antenna1End = CGPoint(x: rect.minX + 8, y: rect.maxY - 3)
        path.move(to: antenna1Start)
        path.line(to: antenna1End)
        
        let antenna2Start = CGPoint(x: rect.maxX - 8, y: rect.minY + 25)
        let antenna2End = CGPoint(x: rect.maxX - 8, y: rect.maxY - 3)
        path.move(to: antenna2Start)
        path.line(to: antenna2End)
        
        // LED indicator
        let ledRect = CGRect(x: rect.midX - 2, y: rect.minY + 15, width: 4, height: 4)
        path.appendOval(in: ledRect)
        
        path.lineWidth = 2.0
        path.stroke()
        path.fill()
    }
    
    private func drawComputerSymbol(in rect: CGRect) {
        // Draw laptop symbol
        let path = NSBezierPath()
        
        // Screen
        let screenRect = CGRect(x: rect.minX + 2, y: rect.midY, width: rect.width - 4, height: rect.height / 2 - 2)
        path.appendRoundedRect(screenRect, xRadius: 2, yRadius: 2)
        
        // Keyboard base
        let baseRect = CGRect(x: rect.minX, y: rect.minY + 2, width: rect.width, height: rect.height / 2 - 4)
        path.appendRoundedRect(baseRect, xRadius: 2, yRadius: 2)
        
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func drawMobileSymbol(in rect: CGRect) {
        // Draw mobile phone symbol
        let path = NSBezierPath()
        
        // Phone body
        let phoneRect = rect.insetBy(dx: 8, dy: 2)
        path.appendRoundedRect(phoneRect, xRadius: 4, yRadius: 4)
        
        // Screen
        let screenRect = phoneRect.insetBy(dx: 3, dy: 6)
        path.appendRoundedRect(screenRect, xRadius: 2, yRadius: 2)
        
        // Home button
        let buttonRect = CGRect(x: phoneRect.midX - 3, y: phoneRect.minY + 2, width: 6, height: 3)
        path.appendRoundedRect(buttonRect, xRadius: 1, yRadius: 1)
        
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func drawPrinterSymbol(in rect: CGRect) {
        // Draw printer symbol
        let path = NSBezierPath()
        
        // Main body
        let bodyRect = CGRect(x: rect.minX + 2, y: rect.minY + 8, width: rect.width - 4, height: rect.height - 16)
        path.appendRoundedRect(bodyRect, xRadius: 2, yRadius: 2)
        
        // Paper tray
        let trayRect = CGRect(x: rect.minX, y: rect.minY + 2, width: rect.width, height: 8)
        path.appendRoundedRect(trayRect, xRadius: 1, yRadius: 1)
        
        // Control panel
        let controlRect = CGRect(x: rect.minX + 6, y: rect.maxY - 8, width: rect.width - 12, height: 4)
        path.appendRoundedRect(controlRect, xRadius: 1, yRadius: 1)
        
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func drawServerSymbol(in rect: CGRect) {
        // Draw server symbol (stacked rectangles)
        let path = NSBezierPath()
        
        let unitHeight = rect.height / 3
        
        for i in 0..<3 {
            let unitRect = CGRect(
                x: rect.minX + 2,
                y: rect.minY + CGFloat(i) * unitHeight + 2,
                width: rect.width - 4,
                height: unitHeight - 2
            )
            path.appendRoundedRect(unitRect, xRadius: 2, yRadius: 2)
            
            // LED indicators
            let ledRect = CGRect(x: rect.maxX - 8, y: unitRect.midY - 1, width: 2, height: 2)
            path.appendOval(in: ledRect)
        }
        
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func drawGenericSymbol(in rect: CGRect) {
        // Draw generic device symbol
        let path = NSBezierPath()
        path.appendRoundedRect(rect.insetBy(dx: 4, dy: 4), xRadius: 4, yRadius: 4)
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func drawDeviceLabel() {
        let labelRect = CGRect(
            x: 0,
            y: 25,
            width: bounds.width,
            height: 16
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let labelText = device.displayText
        labelText.draw(in: labelRect, withAttributes: attributes)
    }
    
    private func drawIPAddress() {
        let ipRect = CGRect(
            x: 0,
            y: 8,
            width: bounds.width,
            height: 14
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        device.ipAddress.draw(in: ipRect, withAttributes: attributes)
    }
    
    private func drawCriticalIndicator() {
        let criticalRect = CGRect(
            x: bounds.width - 50,
            y: bounds.height - 15,
            width: 45,
            height: 12
        )
        
        // Background
        NSColor.systemRed.setFill()
        let path = NSBezierPath(roundedRect: criticalRect, xRadius: 6, yRadius: 6)
        path.fill()
        
        // Text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        "Critical".draw(in: criticalRect, withAttributes: attributes)
    }
    
    private func drawSelectionHighlight() {
        let highlightRect = bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(roundedRect: highlightRect, xRadius: 8, yRadius: 8)
        
        NSColor.controlAccentColor.withAlphaComponent(0.3).setFill()
        path.fill()
        
        NSColor.controlAccentColor.setStroke()
        path.lineWidth = 2.0
        path.stroke()
    }
    
    private func getDeviceColor() -> NSColor {
        switch device.deviceType {
        case .router:
            return NSColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0) // Blue #4A90E2
        case .computer:
            return NSColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1.0) // Orange #F5A623
        case .mobile:
            return NSColor(red: 0.95, green: 0.39, blue: 0.27, alpha: 1.0) // Red-orange
        case .printer:
            return NSColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0) // Green #50C878
        case .server:
            return NSColor(red: 0.31, green: 0.78, blue: 0.47, alpha: 1.0) // Green #50C878
        case .iot, .unknown:
            return NSColor.systemGray
        }
    }
    
    // MARK: - Mouse Events
    override func mouseDown(with event: NSEvent) {
        delegate?.deviceIconView(self, didSelectDevice: device)
    }
    
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            delegate?.deviceIconView(self, didDoubleClickDevice: device)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Add hover effect
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        layer?.shadowRadius = 4
        layer?.shadowOpacity = 0.2
    }
    
    override func mouseExited(with event: NSEvent) {
        // Remove hover effect
        layer?.shadowOpacity = 0
    }
}