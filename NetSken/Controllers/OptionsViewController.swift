//
//  OptionsViewController.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

class OptionsViewController: NSViewController {
    
    // UI Elements
    private var scrollView: NSScrollView!
    private var contentView: NSView!
    private var settingsStackView: NSStackView!
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0).cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupContentView()
        setupSettingsUI()
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
        
        settingsStackView = NSStackView()
        settingsStackView.orientation = .vertical
        settingsStackView.spacing = 25
        settingsStackView.alignment = .leading
        settingsStackView.distribution = .fill
        
        contentView.addSubview(settingsStackView)
        settingsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            settingsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            settingsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            settingsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            settingsStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -60)
        ])
    }
    
    private func setupSettingsUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "NetSken Options & Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = NSColor.labelColor
        settingsStackView.addArrangedSubview(titleLabel)
        
        // General Settings Section
        setupGeneralSettings()
        
        // Scanning Settings Section
        setupScanningSettings()
        
        // Network Settings Section
        setupNetworkSettings()
        
        // Reporting Settings Section
        setupReportingSettings()
        
        // About Section
        setupAboutSection()
        
        updateContentViewHeight()
    }
    
    private func setupGeneralSettings() {
        let sectionView = createSectionView(title: "General Settings")
        
        // Auto-refresh interval
        let refreshContainer = createSettingContainer()
        let refreshLabel = NSTextField(labelWithString: "Auto-refresh interval:")
        refreshLabel.font = NSFont.systemFont(ofSize: 13)
        let refreshPopup = NSPopUpButton()
        refreshPopup.addItems(withTitles: ["30 seconds", "1 minute", "5 minutes", "10 minutes", "Never"])
        refreshPopup.selectItem(at: 2) // Default to 5 minutes
        
        refreshContainer.addArrangedSubview(refreshLabel)
        refreshContainer.addArrangedSubview(refreshPopup)
        sectionView.addArrangedSubview(refreshContainer)
        
        // Show system notifications
        let notificationCheckbox = NSButton(checkboxWithTitle: "Show system notifications for critical findings", target: self, action: #selector(notificationSettingChanged(_:)))
        notificationCheckbox.state = .on
        sectionView.addArrangedSubview(notificationCheckbox)
        
        // Dark mode
        let darkModeCheckbox = NSButton(checkboxWithTitle: "Follow system appearance", target: self, action: #selector(appearanceSettingChanged(_:)))
        darkModeCheckbox.state = .on
        sectionView.addArrangedSubview(darkModeCheckbox)
        
        settingsStackView.addArrangedSubview(sectionView)
    }
    
    private func setupScanningSettings() {
        let sectionView = createSectionView(title: "Scanning Settings")
        
        // Default scan timeout
        let timeoutContainer = createSettingContainer()
        let timeoutLabel = NSTextField(labelWithString: "Default scan timeout:")
        timeoutLabel.font = NSFont.systemFont(ofSize: 13)
        let timeoutField = NSTextField()
        timeoutField.stringValue = "300"
        timeoutField.placeholderString = "seconds"
        timeoutField.controlSize = .regular
        timeoutField.frame.size.width = 100
        
        timeoutContainer.addArrangedSubview(timeoutLabel)
        timeoutContainer.addArrangedSubview(timeoutField)
        sectionView.addArrangedSubview(timeoutContainer)
        
        // Maximum concurrent scans
        let concurrentContainer = createSettingContainer()
        let concurrentLabel = NSTextField(labelWithString: "Maximum concurrent scans:")
        concurrentLabel.font = NSFont.systemFont(ofSize: 13)
        let concurrentStepper = NSStepper()
        concurrentStepper.minValue = 1
        concurrentStepper.maxValue = 10
        concurrentStepper.integerValue = 3
        let concurrentValueLabel = NSTextField(labelWithString: "3")
        concurrentValueLabel.font = NSFont.systemFont(ofSize: 13)
        concurrentStepper.target = self
        concurrentStepper.action = #selector(concurrentScansChanged(_:))
        
        concurrentContainer.addArrangedSubview(concurrentLabel)
        concurrentContainer.addArrangedSubview(concurrentStepper)
        concurrentContainer.addArrangedSubview(concurrentValueLabel)
        sectionView.addArrangedSubview(concurrentContainer)
        
        // Save scan history
        let historyCheckbox = NSButton(checkboxWithTitle: "Save scan history to database", target: self, action: #selector(historySettingChanged(_:)))
        historyCheckbox.state = .on
        sectionView.addArrangedSubview(historyCheckbox)
        
        settingsStackView.addArrangedSubview(sectionView)
    }
    
    private func setupNetworkSettings() {
        let sectionView = createSectionView(title: "Network Settings")
        
        // Default target range
        let targetContainer = createSettingContainer()
        let targetLabel = NSTextField(labelWithString: "Default target range:")
        targetLabel.font = NSFont.systemFont(ofSize: 13)
        let targetField = NSTextField()
        targetField.stringValue = "192.168.1.0/24"
        targetField.placeholderString = "IP range or CIDR"
        targetField.controlSize = .regular
        targetField.frame.size.width = 150
        
        targetContainer.addArrangedSubview(targetLabel)
        targetContainer.addArrangedSubview(targetField)
        sectionView.addArrangedSubview(targetContainer)
        
        // Network interface
        let interfaceContainer = createSettingContainer()
        let interfaceLabel = NSTextField(labelWithString: "Network interface:")
        interfaceLabel.font = NSFont.systemFont(ofSize: 13)
        let interfacePopup = NSPopUpButton()
        interfacePopup.addItems(withTitles: ["Auto-detect", "en0 (Wi-Fi)", "en1 (Ethernet)", "utun0 (VPN)"])
        interfacePopup.selectItem(at: 0)
        
        interfaceContainer.addArrangedSubview(interfaceLabel)
        interfaceContainer.addArrangedSubview(interfacePopup)
        sectionView.addArrangedSubview(interfaceContainer)
        
        // Use system proxy
        let proxyCheckbox = NSButton(checkboxWithTitle: "Use system proxy settings", target: self, action: #selector(proxySettingChanged(_:)))
        proxyCheckbox.state = .off
        sectionView.addArrangedSubview(proxyCheckbox)
        
        settingsStackView.addArrangedSubview(sectionView)
    }
    
    private func setupReportingSettings() {
        let sectionView = createSectionView(title: "Reporting Settings")
        
        // Default export format
        let formatContainer = createSettingContainer()
        let formatLabel = NSTextField(labelWithString: "Default export format:")
        formatLabel.font = NSFont.systemFont(ofSize: 13)
        let formatPopup = NSPopUpButton()
        formatPopup.addItems(withTitles: ["PDF", "CSV", "JSON", "XML"])
        formatPopup.selectItem(at: 0)
        
        formatContainer.addArrangedSubview(formatLabel)
        formatContainer.addArrangedSubview(formatPopup)
        sectionView.addArrangedSubview(formatContainer)
        
        // Include screenshots
        let screenshotCheckbox = NSButton(checkboxWithTitle: "Include network diagram in reports", target: self, action: #selector(screenshotSettingChanged(_:)))
        screenshotCheckbox.state = .on
        sectionView.addArrangedSubview(screenshotCheckbox)
        
        // Auto-generate reports
        let autoReportCheckbox = NSButton(checkboxWithTitle: "Auto-generate reports after scans", target: self, action: #selector(autoReportSettingChanged(_:)))
        autoReportCheckbox.state = .off
        sectionView.addArrangedSubview(autoReportCheckbox)
        
        settingsStackView.addArrangedSubview(sectionView)
    }
    
    private func setupAboutSection() {
        let sectionView = createSectionView(title: "About NetSken")
        
        // Version info
        let versionLabel = NSTextField(labelWithString: "Version 1.0.0 (Build 1)")
        versionLabel.font = NSFont.systemFont(ofSize: 13)
        versionLabel.textColor = NSColor.secondaryLabelColor
        sectionView.addArrangedSubview(versionLabel)
        
        // Description
        let descriptionLabel = NSTextField(wrappingLabelWithString: "NetSken is a comprehensive network security scanner designed for macOS. It integrates powerful tools like Nmap, OpenVAS, and Nikto to provide professional network discovery and vulnerability assessment capabilities.")
        descriptionLabel.font = NSFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        sectionView.addArrangedSubview(descriptionLabel)
        
        // Buttons
        let buttonContainer = NSStackView()
        buttonContainer.orientation = .horizontal
        buttonContainer.spacing = 10
        
        let checkUpdatesButton = NSButton(title: "Check for Updates", target: self, action: #selector(checkForUpdates(_:)))
        let viewLicenseButton = NSButton(title: "View License", target: self, action: #selector(viewLicense(_:)))
        
        buttonContainer.addArrangedSubview(checkUpdatesButton)
        buttonContainer.addArrangedSubview(viewLicenseButton)
        sectionView.addArrangedSubview(buttonContainer)
        
        settingsStackView.addArrangedSubview(sectionView)
    }
    
    private func createSectionView(title: String) -> NSStackView {
        let sectionView = NSStackView()
        sectionView.orientation = .vertical
        sectionView.spacing = 10
        sectionView.alignment = .leading
        
        // Section title
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = NSColor.labelColor
        sectionView.addArrangedSubview(titleLabel)
        
        // Separator line
        let separator = NSBox()
        separator.boxType = .separator
        separator.titlePosition = .noTitle
        sectionView.addArrangedSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalToConstant: 500).isActive = true
        
        return sectionView
    }
    
    private func createSettingContainer() -> NSStackView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.spacing = 10
        container.alignment = .centerY
        return container
    }
    
    private func updateContentViewHeight() {
        let totalHeight = settingsStackView.fittingSize.height + 60
        contentView.frame = NSRect(x: 0, y: 0, width: scrollView.frame.width, height: max(totalHeight, scrollView.frame.height))
    }
    
    // MARK: - Action Methods
    @objc private func notificationSettingChanged(_ sender: NSButton) {
        // Save notification setting
        UserDefaults.standard.set(sender.state == .on, forKey: "ShowNotifications")
    }
    
    @objc private func appearanceSettingChanged(_ sender: NSButton) {
        // Save appearance setting
        UserDefaults.standard.set(sender.state == .on, forKey: "FollowSystemAppearance")
    }
    
    @objc private func concurrentScansChanged(_ sender: NSStepper) {
        // Update concurrent scans value label
        if let containerView = sender.superview as? NSStackView,
           let valueLabel = containerView.arrangedSubviews.last as? NSTextField {
            valueLabel.stringValue = "\(sender.integerValue)"
        }
        UserDefaults.standard.set(sender.integerValue, forKey: "MaxConcurrentScans")
    }
    
    @objc private func historySettingChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "SaveScanHistory")
    }
    
    @objc private func proxySettingChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "UseSystemProxy")
    }
    
    @objc private func screenshotSettingChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "IncludeDiagramInReports")
    }
    
    @objc private func autoReportSettingChanged(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "AutoGenerateReports")
    }
    
    @objc private func checkForUpdates(_ sender: NSButton) {
        // TODO: Implement update checking
        let alert = NSAlert()
        alert.messageText = "Check for Updates"
        alert.informativeText = "You are running the latest version of NetSken."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func viewLicense(_ sender: NSButton) {
        // TODO: Show license information
        let alert = NSAlert()
        alert.messageText = "NetSken License"
        alert.informativeText = "NetSken is released under the MIT License. See the LICENSE file for more details."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}