//
//  AdvancedScansViewController.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

class AdvancedScansViewController: NSViewController {
    
    // UI Elements
    private var scrollView: NSScrollView!
    private var contentView: NSView!
    private var scanOptionsStackView: NSStackView!
    
    // Scan Options
    private var nmapOptionsView: ScanOptionsView!
    private var openvasOptionsView: ScanOptionsView!
    private var niktoOptionsView: ScanOptionsView!
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0).cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupContentView()
        setupScanOptions()
    }
    
    private func setupScrollView() {
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupContentView() {
        contentView = NSView()
        scrollView.documentView = contentView
        
        // Setup stack view for scan options
        scanOptionsStackView = NSStackView()
        scanOptionsStackView.orientation = .vertical
        scanOptionsStackView.spacing = 20
        scanOptionsStackView.alignment = .leading
        scanOptionsStackView.distribution = .fill
        
        contentView.addSubview(scanOptionsStackView)
        scanOptionsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanOptionsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            scanOptionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scanOptionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scanOptionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            scanOptionsStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -60)
        ])
    }
    
    private func setupScanOptions() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Advanced Network Security Scans")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        scanOptionsStackView.addArrangedSubview(titleLabel)
        
        // Nmap Options
        nmapOptionsView = ScanOptionsView(
            title: "Nmap Port Scanning",
            description: "Advanced network discovery and port scanning with custom scripts",
            options: createNmapOptions()
        )
        nmapOptionsView.delegate = self
        scanOptionsStackView.addArrangedSubview(nmapOptionsView)
        
        // OpenVAS Options
        openvasOptionsView = ScanOptionsView(
            title: "OpenVAS Vulnerability Assessment",
            description: "Comprehensive vulnerability scanning and assessment",
            options: createOpenVASOptions()
        )
        openvasOptionsView.delegate = self
        scanOptionsStackView.addArrangedSubview(openvasOptionsView)
        
        // Nikto Options
        niktoOptionsView = ScanOptionsView(
            title: "Nikto Web Server Scanning",
            description: "Web server vulnerability and misconfiguration detection",
            options: createNiktoOptions()
        )
        niktoOptionsView.delegate = self
        scanOptionsStackView.addArrangedSubview(niktoOptionsView)
        
        // Update content view height
        updateContentViewHeight()
    }
    
    private func createNmapOptions() -> [ScanOption] {
        return [
            ScanOption(
                key: "scan_type",
                title: "Scan Type",
                type: .dropdown,
                options: ["TCP SYN", "TCP Connect", "UDP", "Comprehensive"],
                defaultValue: "TCP SYN"
            ),
            ScanOption(
                key: "port_range",
                title: "Port Range",
                type: .textField,
                placeholder: "1-65535",
                defaultValue: "1-1000"
            ),
            ScanOption(
                key: "timing",
                title: "Timing Template",
                type: .dropdown,
                options: ["T0 (Paranoid)", "T1 (Sneaky)", "T2 (Polite)", "T3 (Normal)", "T4 (Aggressive)", "T5 (Insane)"],
                defaultValue: "T3 (Normal)"
            ),
            ScanOption(
                key: "os_detection",
                title: "OS Detection",
                type: .checkbox,
                defaultValue: true
            ),
            ScanOption(
                key: "service_version",
                title: "Service Version Detection",
                type: .checkbox,
                defaultValue: true
            ),
            ScanOption(
                key: "scripts",
                title: "NSE Scripts",
                type: .textField,
                placeholder: "default,vuln,safe",
                defaultValue: "default"
            )
        ]
    }
    
    private func createOpenVASOptions() -> [ScanOption] {
        return [
            ScanOption(
                key: "scan_config",
                title: "Scan Configuration",
                type: .dropdown,
                options: ["Discovery", "Full and fast", "Full and deep", "System Discovery"],
                defaultValue: "Full and fast"
            ),
            ScanOption(
                key: "alive_test",
                title: "Alive Test",
                type: .dropdown,
                options: ["ICMP Ping", "TCP-ACK Service Ping", "TCP-SYN Service Ping", "ARP Ping"],
                defaultValue: "ICMP Ping"
            ),
            ScanOption(
                key: "max_checks",
                title: "Maximum Checks",
                type: .textField,
                placeholder: "4",
                defaultValue: "4"
            ),
            ScanOption(
                key: "max_hosts",
                title: "Maximum Hosts",
                type: .textField,
                placeholder: "20",
                defaultValue: "20"
            )
        ]
    }
    
    private func createNiktoOptions() -> [ScanOption] {
        return [
            ScanOption(
                key: "scan_tuning",
                title: "Scan Tuning",
                type: .dropdown,
                options: ["All Tests", "Interesting Files", "Misconfiguration", "Information Disclosure", "Injection"],
                defaultValue: "All Tests"
            ),
            ScanOption(
                key: "evasion",
                title: "Evasion Techniques",
                type: .dropdown,
                options: ["None", "Random URI encoding", "Directory self-reference", "Premature URL ending"],
                defaultValue: "None"
            ),
            ScanOption(
                key: "timeout",
                title: "Timeout (seconds)",
                type: .textField,
                placeholder: "10",
                defaultValue: "10"
            ),
            ScanOption(
                key: "user_agent",
                title: "Custom User Agent",
                type: .textField,
                placeholder: "Mozilla/5.0...",
                defaultValue: ""
            )
        ]
    }
    
    private func updateContentViewHeight() {
        let totalHeight = scanOptionsStackView.fittingSize.height + 60
        contentView.frame = NSRect(x: 0, y: 0, width: scrollView.frame.width, height: max(totalHeight, scrollView.frame.height))
    }
}

// MARK: - ScanOptionsViewDelegate
extension AdvancedScansViewController: ScanOptionsViewDelegate {
    
    func scanOptionsView(_ view: ScanOptionsView, didStartScan options: [String: Any]) {
        // Handle scan start based on the view
        if view == nmapOptionsView {
            startNmapScan(with: options)
        } else if view == openvasOptionsView {
            startOpenVASScan(with: options)
        } else if view == niktoOptionsView {
            startNiktoScan(with: options)
        }
    }
    
    private func startNmapScan(with options: [String: Any]) {
        print("Starting Nmap scan with options: \(options)")
        // TODO: Implement Nmap scan through NetworkManager
    }
    
    private func startOpenVASScan(with options: [String: Any]) {
        print("Starting OpenVAS scan with options: \(options)")
        // TODO: Implement OpenVAS scan through NetworkManager
    }
    
    private func startNiktoScan(with options: [String: Any]) {
        print("Starting Nikto scan with options: \(options)")
        // TODO: Implement Nikto scan through NetworkManager
    }
}