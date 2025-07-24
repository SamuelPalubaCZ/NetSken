//
//  ScanOptionsView.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Cocoa

protocol ScanOptionsViewDelegate: AnyObject {
    func scanOptionsView(_ view: ScanOptionsView, didStartScan options: [String: Any])
}

class ScanOptionsView: NSView {
    
    weak var delegate: ScanOptionsViewDelegate?
    
    private let title: String
    private let description: String
    private let options: [ScanOption]
    private var optionControls: [String: NSControl] = [:]
    
    private var containerView: NSStackView!
    private var startButton: NSButton!
    
    init(title: String, description: String, options: [ScanOption]) {
        self.title = title
        self.description = description
        self.options = options
        
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        containerView = NSStackView()
        containerView.orientation = .vertical
        containerView.spacing = 12
        containerView.alignment = .leading
        containerView.distribution = .fill
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        setupHeader()
        setupOptions()
        setupStartButton()
        
        // Set intrinsic content size
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: 500).isActive = true
    }
    
    private func setupHeader() {
        // Title
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = NSColor.labelColor
        containerView.addArrangedSubview(titleLabel)
        
        // Description
        let descriptionLabel = NSTextField(wrappingLabelWithString: description)
        descriptionLabel.font = NSFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = NSColor.secondaryLabelColor
        containerView.addArrangedSubview(descriptionLabel)
        
        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.titlePosition = .noTitle
        containerView.addArrangedSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
    }
    
    private func setupOptions() {
        for option in options {
            let optionView = createOptionView(for: option)
            containerView.addArrangedSubview(optionView)
        }
    }
    
    private func createOptionView(for option: ScanOption) -> NSView {
        let optionContainer = NSStackView()
        optionContainer.orientation = .horizontal
        optionContainer.spacing = 12
        optionContainer.alignment = .centerY
        
        // Label
        let label = NSTextField(labelWithString: option.title + ":")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        optionContainer.addArrangedSubview(label)
        
        // Control based on option type
        let control = createControl(for: option)
        optionControls[option.key] = control
        optionContainer.addArrangedSubview(control)
        
        // Add spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        optionContainer.addArrangedSubview(spacer)
        
        return optionContainer
    }
    
    private func createControl(for option: ScanOption) -> NSControl {
        switch option.type {
        case .textField:
            let textField = NSTextField()
            textField.stringValue = option.defaultValue as? String ?? ""
            textField.placeholderString = option.placeholder
            textField.controlSize = .regular
            textField.frame.size.width = 200
            return textField
            
        case .dropdown:
            let popup = NSPopUpButton()
            if let options = option.options {
                popup.addItems(withTitles: options)
                if let defaultValue = option.defaultValue as? String,
                   let index = options.firstIndex(of: defaultValue) {
                    popup.selectItem(at: index)
                }
            }
            return popup
            
        case .checkbox:
            let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            checkbox.state = (option.defaultValue as? Bool == true) ? .on : .off
            return checkbox
        }
    }
    
    private func setupStartButton() {
        startButton = NSButton(title: "Start \(title)", target: self, action: #selector(startScan(_:)))
        startButton.bezelStyle = .rounded
        startButton.controlSize = .regular
        startButton.keyEquivalent = "\r"
        
        let buttonContainer = NSView()
        buttonContainer.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            startButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            startButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        containerView.addArrangedSubview(buttonContainer)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
    }
    
    @objc private func startScan(_ sender: NSButton) {
        let scanOptions = collectOptions()
        delegate?.scanOptionsView(self, didStartScan: scanOptions)
    }
    
    private func collectOptions() -> [String: Any] {
        var result: [String: Any] = [:]
        
        for option in options {
            guard let control = optionControls[option.key] else { continue }
            
            switch option.type {
            case .textField:
                if let textField = control as? NSTextField {
                    result[option.key] = textField.stringValue
                }
            case .dropdown:
                if let popup = control as? NSPopUpButton {
                    result[option.key] = popup.titleOfSelectedItem ?? ""
                }
            case .checkbox:
                if let checkbox = control as? NSButton {
                    result[option.key] = checkbox.state == .on
                }
            }
        }
        
        return result
    }
}

// MARK: - ScanOption Model
struct ScanOption {
    let key: String
    let title: String
    let type: OptionType
    let options: [String]?
    let placeholder: String?
    let defaultValue: Any?
    
    init(key: String, title: String, type: OptionType, options: [String]? = nil, placeholder: String? = nil, defaultValue: Any? = nil) {
        self.key = key
        self.title = title
        self.type = type
        self.options = options
        self.placeholder = placeholder
        self.defaultValue = defaultValue
    }
}

enum OptionType {
    case textField
    case dropdown
    case checkbox
}