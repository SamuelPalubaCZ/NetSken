//
//  DeviceModel.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Foundation
import Cocoa

// MARK: - Device Types
enum DeviceType: String, CaseIterable, Codable {
    case router = "router"
    case computer = "computer"
    case mobile = "mobile"
    case printer = "printer"
    case server = "server"
    case iot = "iot"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .router: return "Router"
        case .computer: return "Computer"
        case .mobile: return "Mobile Device"
        case .printer: return "Printer"
        case .server: return "Server"
        case .iot: return "IoT Device"
        case .unknown: return "Unknown Device"
        }
    }
}

// MARK: - Device Status
enum DeviceStatus: String, CaseIterable, Codable {
    case online = "online"
    case offline = "offline"
    case warning = "warning"
    case critical = "critical"
    case scanning = "scanning"
    
    var displayName: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        case .warning: return "Warning"
        case .critical: return "Critical"
        case .scanning: return "Scanning"
        }
    }
}

// MARK: - DeviceModel
class DeviceModel: NSObject, Codable {
    let identifier: String
    let ipAddress: String
    let macAddress: String
    let hostname: String
    let deviceType: DeviceType
    let vendor: String
    var status: DeviceStatus
    var vulnerabilities: [VulnerabilityModel]
    var openPorts: [PortModel]
    var lastSeen: Date
    var osInfo: String?
    
    // UI positioning (for network diagram)
    var position: CGPoint = .zero
    
    init(identifier: String,
         ipAddress: String,
         macAddress: String,
         hostname: String,
         deviceType: DeviceType,
         vendor: String,
         status: DeviceStatus,
         vulnerabilities: [VulnerabilityModel] = [],
         openPorts: [PortModel] = [],
         lastSeen: Date = Date(),
         osInfo: String? = nil) {
        
        self.identifier = identifier
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.hostname = hostname
        self.deviceType = deviceType
        self.vendor = vendor
        self.status = status
        self.vulnerabilities = vulnerabilities
        self.openPorts = openPorts
        self.lastSeen = lastSeen
        self.osInfo = osInfo
        
        super.init()
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case identifier, ipAddress, macAddress, hostname
        case deviceType, vendor, status, vulnerabilities
        case openPorts, lastSeen, osInfo
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        identifier = try container.decode(String.self, forKey: .identifier)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        macAddress = try container.decode(String.self, forKey: .macAddress)
        hostname = try container.decode(String.self, forKey: .hostname)
        deviceType = try container.decode(DeviceType.self, forKey: .deviceType)
        vendor = try container.decode(String.self, forKey: .vendor)
        status = try container.decode(DeviceStatus.self, forKey: .status)
        vulnerabilities = try container.decode([VulnerabilityModel].self, forKey: .vulnerabilities)
        openPorts = try container.decode([PortModel].self, forKey: .openPorts)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
        osInfo = try container.decodeIfPresent(String.self, forKey: .osInfo)
        
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(identifier, forKey: .identifier)
        try container.encode(ipAddress, forKey: .ipAddress)
        try container.encode(macAddress, forKey: .macAddress)
        try container.encode(hostname, forKey: .hostname)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(vendor, forKey: .vendor)
        try container.encode(status, forKey: .status)
        try container.encode(vulnerabilities, forKey: .vulnerabilities)
        try container.encode(openPorts, forKey: .openPorts)
        try container.encode(lastSeen, forKey: .lastSeen)
        try container.encodeIfPresent(osInfo, forKey: .osInfo)
    }
    
    // MARK: - Computed Properties
    var isOnline: Bool {
        return status == .online || status == .warning || status == .critical
    }
    
    var riskLevel: RiskLevel {
        if status == .critical || !vulnerabilities.filter({ $0.severity == .critical }).isEmpty {
            return .critical
        } else if status == .warning || !vulnerabilities.filter({ $0.severity == .high }).isEmpty {
            return .high
        } else if !vulnerabilities.filter({ $0.severity == .medium }).isEmpty {
            return .medium
        } else {
            return .low
        }
    }
    
    var displayText: String {
        return hostname.isEmpty ? ipAddress : hostname
    }
}

// MARK: - Risk Level
enum RiskLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: NSColor {
        switch self {
        case .low: return NSColor.systemGreen
        case .medium: return NSColor.systemYellow
        case .high: return NSColor.systemOrange
        case .critical: return NSColor.systemRed
        }
    }
}

