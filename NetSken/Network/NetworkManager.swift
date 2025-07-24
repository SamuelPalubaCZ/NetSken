//
//  NetworkManager.swift
//  NetSken
//
//  Created by Samuel Paluba on 24.07.2025.
//

import Foundation

class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:8000/api"
    private var urlSession: URLSession
    
    // Backend process management
    private var backendProcess: Process?
    private var isBackendRunning = false
    
    override init() {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 300.0
        self.urlSession = URLSession(configuration: config)
        
        super.init()
        
        // Start backend on initialization
        startBackendProcess()
    }
    
    deinit {
        stopBackendProcess()
    }
    
    // MARK: - Backend Process Management
    private func startBackendProcess() {
        guard !isBackendRunning else { return }
        
        // TODO: Start embedded Python backend process
        // For now, assume backend is running externally
        isBackendRunning = true
        
        print("NetworkManager: Backend process started")
    }
    
    private func stopBackendProcess() {
        guard isBackendRunning else { return }
        
        backendProcess?.terminate()
        backendProcess = nil
        isBackendRunning = false
        
        print("NetworkManager: Backend process stopped")
    }
    
    // MARK: - API Methods
    func getDevices(completion: @escaping (Result<[DeviceModel], Error>) -> Void) {
        let endpoint = "/devices"
        performRequest(endpoint: endpoint, method: "GET", completion: completion)
    }
    
    func startNetworkScan(targetRange: String, completion: @escaping (Result<ScanSession, Error>) -> Void) {
        let endpoint = "/scan/start"
        let parameters = ["target_range": targetRange]
        performRequest(endpoint: endpoint, method: "POST", parameters: parameters, completion: completion)
    }
    
    func getScanStatus(sessionId: String, completion: @escaping (Result<ScanStatus, Error>) -> Void) {
        let endpoint = "/scan/status/\(sessionId)"
        performRequest(endpoint: endpoint, method: "GET", completion: completion)
    }
    
    func startNmapScan(target: String, options: [String: Any], completion: @escaping (Result<ScanSession, Error>) -> Void) {
        let endpoint = "/scan/nmap"
        var parameters = options
        parameters["target"] = target
        performRequest(endpoint: endpoint, method: "POST", parameters: parameters, completion: completion)
    }
    
    func startOpenVASScan(target: String, options: [String: Any], completion: @escaping (Result<ScanSession, Error>) -> Void) {
        let endpoint = "/scan/openvas"
        var parameters = options
        parameters["target"] = target
        performRequest(endpoint: endpoint, method: "POST", parameters: parameters, completion: completion)
    }
    
    func startNiktoScan(target: String, options: [String: Any], completion: @escaping (Result<ScanSession, Error>) -> Void) {
        let endpoint = "/scan/nikto"
        var parameters = options
        parameters["target"] = target
        performRequest(endpoint: endpoint, method: "POST", parameters: parameters, completion: completion)
    }
    
    func getVulnerabilities(deviceId: String? = nil, completion: @escaping (Result<[VulnerabilityModel], Error>) -> Void) {
        var endpoint = "/vulnerabilities"
        if let deviceId = deviceId {
            endpoint += "?device_id=\(deviceId)"
        }
        performRequest(endpoint: endpoint, method: "GET", completion: completion)
    }
    
    func getScanHistory(limit: Int = 50, completion: @escaping (Result<[ScanSession], Error>) -> Void) {
        let endpoint = "/history?limit=\(limit)"
        performRequest(endpoint: endpoint, method: "GET", completion: completion)
    }
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable>(
        endpoint: String,
        method: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add parameters for POST requests
        if let parameters = parameters, method != "GET" {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                completion(.failure(NetworkError.encodingError(error)))
                return
            }
        }
        
        urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(NetworkError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(NetworkError.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(NetworkError.decodingError(error)))
                }
            }
        }.resume()
    }
}

// MARK: - Network Models
struct ScanSession: Codable {
    let id: String
    let targetRange: String
    let scanType: String
    let status: String
    let createdAt: Date
    let completedAt: Date?
    let progress: Double
    let deviceCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, targetRange = "target_range", scanType = "scan_type"
        case status, createdAt = "created_at", completedAt = "completed_at"
        case progress, deviceCount = "device_count"
    }
}

struct ScanStatus: Codable {
    let sessionId: String
    let status: String
    let progress: Double
    let currentTask: String?
    let estimatedTimeRemaining: Int?
    let devicesFound: Int
    let vulnerabilitiesFound: Int
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id", status, progress
        case currentTask = "current_task"
        case estimatedTimeRemaining = "estimated_time_remaining"
        case devicesFound = "devices_found"
        case vulnerabilitiesFound = "vulnerabilities_found"
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case noData
    case encodingError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noData:
            return "No data received"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deviceDiscovered = Notification.Name("DeviceDiscovered")
    static let vulnerabilityFound = Notification.Name("VulnerabilityFound")
    static let scanCompleted = Notification.Name("ScanCompleted")
    static let scanProgress = Notification.Name("ScanProgress")
}