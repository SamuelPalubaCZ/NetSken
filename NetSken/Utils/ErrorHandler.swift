//
//  ErrorHandler.swift
//  NetSken
//
//  Centralized error handling and logging for NetSken application
//

import Foundation
import OSLog
import Cocoa
import Combine

// MARK: - NetSken Error Types

enum NetSkenError: Error, LocalizedError, CustomStringConvertible {
    case networkError(message: String, underlyingError: Error?)
    case apiError(statusCode: Int, message: String)
    case scanError(scanId: String?, message: String)
    case validationError(field: String, message: String)
    case configurationError(key: String, message: String)
    case databaseError(operation: String, message: String)
    case securityToolError(tool: String, message: String)
    case authenticationError(message: String)
    case permissionError(permission: String, message: String)
    case fileSystemError(path: String, message: String)
    case parsingError(data: String, message: String)
    case timeoutError(operation: String, timeout: TimeInterval)
    case unknownError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message, _):
            return "Network Error: \(message)"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .scanError(let scanId, let message):
            let scanInfo = scanId != nil ? " (Scan: \(scanId!))" : ""
            return "Scan Error\(scanInfo): \(message)"
        case .validationError(let field, let message):
            return "Validation Error (\(field)): \(message)"
        case .configurationError(let key, let message):
            return "Configuration Error (\(key)): \(message)"
        case .databaseError(let operation, let message):
            return "Database Error (\(operation)): \(message)"
        case .securityToolError(let tool, let message):
            return "Security Tool Error (\(tool)): \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .permissionError(let permission, let message):
            return "Permission Error (\(permission)): \(message)"
        case .fileSystemError(let path, let message):
            return "File System Error (\(path)): \(message)"
        case .parsingError(let data, let message):
            return "Parsing Error (\(data)): \(message)"
        case .timeoutError(let operation, let timeout):
            return "Timeout Error (\(operation)): Operation timed out after \(timeout) seconds"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
    
    var description: String {
        return errorDescription ?? "NetSken Error"
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .networkError(_, _):
            return "Unable to connect to the network. Please check your internet connection and try again."
        case .apiError(let statusCode, _):
            if statusCode >= 500 {
                return "Server error occurred. Please try again later."
            } else {
                return "Request failed. Please check your input and try again."
            }
        case .scanError(_, _):
            return "Scan operation failed. Please check your network settings and try again."
        case .validationError(_, let message):
            return message
        case .configurationError(_, _):
            return "Configuration error detected. Please check application settings."
        case .databaseError(_, _):
            return "Database error occurred. Please restart the application."
        case .securityToolError(let tool, _):
            return "Security tool '\(tool)' is not available or failed to execute. Please check installation."
        case .authenticationError(_):
            return "Authentication failed. Please check your credentials."
        case .permissionError(let permission, _):
            return "Permission required: \(permission). Please grant the necessary permissions."
        case .fileSystemError(_, _):
            return "File system error occurred. Please check file permissions and available disk space."
        case .parsingError(_, _):
            return "Data parsing error occurred. The received data format is invalid."
        case .timeoutError(let operation, _):
            return "Operation '\(operation)' timed out. Please try again."
        case .unknownError(_):
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError(_, _), .apiError(_, _), .timeoutError(_, _):
            return .medium
        case .scanError(_, _), .securityToolError(_, _):
            return .high
        case .validationError(_, _), .parsingError(_, _):
            return .low
        case .configurationError(_, _), .databaseError(_, _):
            return .high
        case .authenticationError(_), .permissionError(_, _):
            return .medium
        case .fileSystemError(_, _):
            return .medium
        case .unknownError(_):
            return .high
        }
    }
}

enum ErrorSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: NSColor {
        switch self {
        case .low:
            return NSColor.systemYellow
        case .medium:
            return NSColor.systemOrange
        case .high:
            return NSColor.systemRed
        case .critical:
            return NSColor.systemPurple
        }
    }
}

// MARK: - Error Handler

class ErrorHandler {
    
    static let shared = ErrorHandler()
    
    private let logger = Logger(subsystem: "com.netsken.app", category: "ErrorHandler")
    private let errorQueue = DispatchQueue(label: "com.netsken.errorhandling", qos: .utility)
    
    private init() {
        setupCrashReporting()
    }
    
    // MARK: - Public Interface
    
    func handle(_ error: Error, context: [String: Any] = [:], showAlert: Bool = true) {
        errorQueue.async { [weak self] in
            self?.processError(error, context: context, showAlert: showAlert)
        }
    }
    
    func handleAPIError(_ data: Data?, response: URLResponse?, error: Error?) -> NetSkenError {
        var errorMessage = "API request failed"
        var statusCode = 0
        
        if let httpResponse = response as? HTTPURLResponse {
            statusCode = httpResponse.statusCode
            
            if let data = data,
               let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                errorMessage = errorResponse.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            }
        } else if let error = error {
            return .networkError(message: error.localizedDescription, underlyingError: error)
        }
        
        let netSkenError = NetSkenError.apiError(statusCode: statusCode, message: errorMessage)
        handle(netSkenError, context: ["response": response as Any, "data": data as Any])
        return netSkenError
    }
    
    func validateInput<T>(_ value: T?, fieldName: String, validator: (T) -> Bool = { _ in true }) throws -> T {
        guard let value = value else {
            throw NetSkenError.validationError(field: fieldName, message: "\(fieldName) is required")
        }
        
        guard validator(value) else {
            throw NetSkenError.validationError(field: fieldName, message: "\(fieldName) is invalid")
        }
        
        return value
    }
    
    func logSecurityEvent(_ event: SecurityEvent, details: [String: Any] = [:]) {
        logger.critical("SECURITY_EVENT: \(event.rawValue) - \(details)")
        
        // In a production app, you might want to send security events to a SIEM system
        // or security monitoring service
    }
    
    // MARK: - Private Methods
    
    private func processError(_ error: Error, context: [String: Any], showAlert: Bool) {
        let netSkenError = convertToNetSkenError(error)
        
        // Log the error
        logError(netSkenError, context: context)
        
        // Show alert if requested
        if showAlert {
            DispatchQueue.main.async {
                self.showErrorAlert(netSkenError, context: context)
            }
        }
        
        // Send error to analytics/crash reporting
        reportError(netSkenError, context: context)
    }
    
    private func convertToNetSkenError(_ error: Error) -> NetSkenError {
        if let netSkenError = error as? NetSkenError {
            return netSkenError
        }
        
        // Convert common errors to NetSkenError
        switch error {
        case let urlError as URLError:
            return .networkError(message: urlError.localizedDescription, underlyingError: urlError)
        case let decodingError as DecodingError:
            return .parsingError(data: "JSON", message: decodingError.localizedDescription)
        case let validationError as ValidationError:
            return .validationError(field: validationError.field, message: validationError.message)
        default:
            return .unknownError(message: error.localizedDescription)
        }
    }
    
    private func logError(_ error: NetSkenError, context: [String: Any]) {
        let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        
        switch error.severity {
        case .low:
            logger.info("[\(error.severity.rawValue)] \(error.description) | Context: \(contextString)")
        case .medium:
            logger.notice("[\(error.severity.rawValue)] \(error.description) | Context: \(contextString)")
        case .high:
            logger.error("[\(error.severity.rawValue)] \(error.description) | Context: \(contextString)")
        case .critical:
            logger.critical("[\(error.severity.rawValue)] \(error.description) | Context: \(contextString)")
        }
    }
    
    private func showErrorAlert(_ error: NetSkenError, context: [String: Any]) {
        let alert = NSAlert()
        alert.messageText = "Error Occurred"
        alert.informativeText = error.userFriendlyMessage
        alert.alertStyle = .warning
        
        // Add buttons based on error type
        alert.addButton(withTitle: "OK")
        
        if case .configurationError(_, _) = error {
            alert.addButton(withTitle: "Open Settings")
        }
        
        if case .securityToolError(_, _) = error {
            alert.addButton(withTitle: "Check Tools")
        }
        
        let response = alert.runModal()
        
        // Handle button responses
        switch response {
        case .alertSecondButtonReturn:
            if case .configurationError(_, _) = error {
                // Open settings
                NotificationCenter.default.post(name: .openSettings, object: nil)
            } else if case .securityToolError(_, _) = error {
                // Open tool configuration
                NotificationCenter.default.post(name: .openToolConfiguration, object: nil)
            }
        default:
            break
        }
    }
    
    private func reportError(_ error: NetSkenError, context: [String: Any]) {
        // In a production app, you would send this to a crash reporting service
        // like Crashlytics, Sentry, or Bugsnag
        
        let errorReport = ErrorReport(
            error: error,
            context: context,
            timestamp: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceModel: getMacModel()
        )
        
        // For now, just log it
        logger.debug("Error report generated: \(errorReport)")
    }
    
    private func setupCrashReporting() {
        // Setup crash reporting and uncaught exception handlers
        NSSetUncaughtExceptionHandler { exception in
            ErrorHandler.shared.logger.critical("Uncaught exception: \(exception)")
            // In production, send this to crash reporting service
        }
    }
    
    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}

// MARK: - Supporting Types

struct APIErrorResponse: Codable {
    let error: Bool
    let error_code: String
    let message: String
    let details: [String: AnyCodable]?
}

struct AnyCodable: Codable {
    private let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    func encode(to encoder: Encoder) throws {
        // Implementation for encoding any value
    }
    
    init(from decoder: Decoder) throws {
        // Implementation for decoding any value
        self.value = ""
    }
}

struct ValidationError: Error {
    let field: String
    let message: String
}

struct ErrorReport {
    let error: NetSkenError
    let context: [String: Any]
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    let deviceModel: String
}

extension ErrorReport: CustomStringConvertible {
    var description: String {
        return "Error: \(error.description), Context: \(context), Timestamp: \(timestamp), AppVersion: \(appVersion), OSVersion: \(osVersion), DeviceModel: \(deviceModel)"
    }
}

enum SecurityEvent: String {
    case unauthorizedAccess = "UNAUTHORIZED_ACCESS"
    case privilegeEscalation = "PRIVILEGE_ESCALATION"
    case suspiciousScanActivity = "SUSPICIOUS_SCAN_ACTIVITY"
    case configurationTampering = "CONFIGURATION_TAMPERING"
    case dataExfiltrationAttempt = "DATA_EXFILTRATION_ATTEMPT"
}

// MARK: - Notifications

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let openToolConfiguration = Notification.Name("openToolConfiguration")
    static let errorOccurred = Notification.Name("errorOccurred")
}

// MARK: - Error Handling Extensions

extension Result {
    func handleError(context: [String: Any] = [:], showAlert: Bool = true) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handle(error, context: context, showAlert: showAlert)
            return nil
        }
    }
}

extension Publisher {
    func handleErrors(context: [String: Any] = [:], showAlert: Bool = true) -> AnyPublisher<Output, Never> {
        return self
            .catch { error -> Empty<Output, Never> in
                ErrorHandler.shared.handle(error, context: context, showAlert: showAlert)
                return Empty()
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Error Recovery

protocol ErrorRecoverable {
    func attemptRecovery(from error: NetSkenError) -> Bool
}

class NetworkErrorRecovery: ErrorRecoverable {
    func attemptRecovery(from error: NetSkenError) -> Bool {
        switch error {
        case .networkError(_, _):
            // Attempt to retry network connection
            return retryNetworkConnection()
        case .timeoutError(_, _):
            // Increase timeout and retry
            return retryWithIncreasedTimeout()
        default:
            return false
        }
    }
    
    private func retryNetworkConnection() -> Bool {
        // Implementation for network retry logic
        return false
    }
    
    private func retryWithIncreasedTimeout() -> Bool {
        // Implementation for timeout retry logic
        return false
    }
}