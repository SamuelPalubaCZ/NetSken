//
//  NetworkManagerTests.swift
//  NetSkenTests
//
//  Unit tests for NetworkManager
//

import XCTest
import Combine
@testable import NetSken

class NetworkManagerTests: XCTestCase {
    
    var networkManager: NetworkManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        networkManager = NetworkManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        networkManager = nil
        super.tearDown()
    }
    
    // MARK: - Device Management Tests
    
    func testFetchDevicesSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch devices success")
        let mockResponse = DevicesResponse(
            devices: [
                DeviceModel(
                    id: "device-1",
                    ipAddress: "192.168.1.10",
                    hostname: "test-device",
                    macAddress: "00:11:22:33:44:55",
                    deviceType: .computer,
                    osName: "Windows",
                    osVersion: "10",
                    riskLevel: .medium,
                    lastSeen: Date(),
                    openPorts: 5,
                    vulnerabilityCount: 2
                )
            ],
            totalCount: 1,
            returnedCount: 1
        )
        
        // Mock URLSession
        let mockData = try JSONEncoder().encode(mockResponse)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/devices/")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.fetchDevices()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { response in
                    // Then
                    XCTAssertEqual(response.devices.count, 1)
                    XCTAssertEqual(response.devices.first?.ipAddress, "192.168.1.10")
                    XCTAssertEqual(response.totalCount, 1)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetchDevicesNetworkError() throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch devices network error")
        
        // Mock network error
        MockURLProtocol.mockError = URLError(.networkConnectionLost)
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.fetchDevices()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error is URLError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected error, got success")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCreateDeviceSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Create device success")
        let deviceRequest = DeviceRequest(
            ipAddress: "192.168.1.20",
            hostname: "new-device",
            macAddress: "66:77:88:99:AA:BB",
            deviceType: .computer,
            osName: "Linux",
            osVersion: "Ubuntu 20.04",
            riskLevel: .low
        )
        
        let mockDevice = DeviceModel(
            id: "device-2",
            ipAddress: deviceRequest.ipAddress,
            hostname: deviceRequest.hostname,
            macAddress: deviceRequest.macAddress,
            deviceType: deviceRequest.deviceType,
            osName: deviceRequest.osName,
            osVersion: deviceRequest.osVersion,
            riskLevel: deviceRequest.riskLevel,
            lastSeen: Date(),
            openPorts: 0,
            vulnerabilityCount: 0
        )
        
        let mockData = try JSONEncoder().encode(mockDevice)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/devices/")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.createDevice(deviceRequest)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { device in
                    // Then
                    XCTAssertEqual(device.ipAddress, deviceRequest.ipAddress)
                    XCTAssertEqual(device.hostname, deviceRequest.hostname)
                    XCTAssertNotNil(device.id)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Scan Management Tests
    
    func testStartScanSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Start scan success")
        let scanRequest = ScanRequest(
            scanType: .discovery,
            target: "192.168.1.0/24",
            parameters: ScanParameters(
                timeout: 300,
                scanTechniques: ["ping", "tcp"],
                portRange: "1-1000",
                timing: "normal"
            )
        )
        
        let mockScanSession = ScanSessionModel(
            id: "scan-123",
            scanType: scanRequest.scanType,
            target: scanRequest.target,
            parameters: scanRequest.parameters,
            status: .running,
            createdAt: Date(),
            startedAt: Date(),
            completedAt: nil,
            errorMessage: nil,
            deviceCount: 0,
            vulnerabilityCount: 0,
            progressPercentage: 0
        )
        
        let mockData = try JSONEncoder().encode(mockScanSession)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/scans/")!,
            statusCode: 202,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.startScan(scanRequest)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { scanSession in
                    // Then
                    XCTAssertEqual(scanSession.scanType, scanRequest.scanType)
                    XCTAssertEqual(scanSession.target, scanRequest.target)
                    XCTAssertEqual(scanSession.status, .running)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetScanStatusSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Get scan status success")
        let scanId = "scan-123"
        
        let mockScanSession = ScanSessionModel(
            id: scanId,
            scanType: .discovery,
            target: "192.168.1.0/24",
            parameters: ScanParameters(timeout: 300, scanTechniques: ["ping"], portRange: "1-1000", timing: "normal"),
            status: .completed,
            createdAt: Date(),
            startedAt: Date(),
            completedAt: Date(),
            errorMessage: nil,
            deviceCount: 5,
            vulnerabilityCount: 3,
            progressPercentage: 100
        )
        
        let mockData = try JSONEncoder().encode(mockScanSession)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/scans/\(scanId)")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.getScanStatus(scanId: scanId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { scanSession in
                    // Then
                    XCTAssertEqual(scanSession.id, scanId)
                    XCTAssertEqual(scanSession.status, .completed)
                    XCTAssertEqual(scanSession.deviceCount, 5)
                    XCTAssertEqual(scanSession.vulnerabilityCount, 3)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Vulnerability Tests
    
    func testFetchVulnerabilitiesSuccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Fetch vulnerabilities success")
        
        let mockVulnerability = VulnerabilityModel(
            id: "vuln-1",
            cveId: "CVE-2021-1234",
            title: "Test Vulnerability",
            description: "A test vulnerability for unit testing",
            severity: .critical,
            cvssScore: 9.8,
            sourceTool: "nmap",
            detectedAt: Date(),
            affectedPort: 80,
            affectedService: "http",
            solution: "Update the service to latest version",
            references: ["https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-1234"],
            deviceId: "device-1",
            deviceIp: "192.168.1.10",
            deviceHostname: "test-device",
            scanSessionId: "scan-123"
        )
        
        let mockResponse = VulnerabilitiesResponse(
            vulnerabilities: [mockVulnerability],
            totalCount: 1,
            returnedCount: 1
        )
        
        let mockData = try JSONEncoder().encode(mockResponse)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/vulnerabilities/")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        // When
        networkManager.fetchVulnerabilities()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { response in
                    // Then
                    XCTAssertEqual(response.vulnerabilities.count, 1)
                    let vulnerability = response.vulnerabilities.first!
                    XCTAssertEqual(vulnerability.cveId, "CVE-2021-1234")
                    XCTAssertEqual(vulnerability.severity, .critical)
                    XCTAssertEqual(vulnerability.cvssScore, 9.8)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testAPIErrorHandling() throws {
        // Given
        let expectation = XCTestExpectation(description: "API error handling")
        
        let errorResponse = APIErrorResponse(
            error: true,
            errorCode: "SCAN_ERROR",
            message: "Scan operation failed",
            details: [:],
            path: "/api/scans/"
        )
        
        let mockData = try JSONEncoder().encode(errorResponse)
        MockURLProtocol.mockData = mockData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "http://localhost:8000/api/scans/")!,
            statusCode: 422,
            httpVersion: nil,
            headerFields: nil
        )
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        networkManager.session = URLSession(configuration: config)
        
        let scanRequest = ScanRequest(
            scanType: .discovery,
            target: "invalid_target",
            parameters: ScanParameters(timeout: 300, scanTechniques: ["ping"], portRange: "1-1000", timing: "normal")
        )
        
        // When
        networkManager.startScan(scanRequest)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        if let netSkenError = error as? NetSkenError {
                            if case .apiError(let statusCode, let message) = netSkenError {
                                XCTAssertEqual(statusCode, 422)
                                XCTAssertEqual(message, "Scan operation failed")
                                expectation.fulfill()
                            } else {
                                XCTFail("Expected API error, got: \(netSkenError)")
                            }
                        } else {
                            XCTFail("Expected NetSkenError, got: \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected error, got success")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testFetchDevicesPerformance() throws {
        // This test measures the performance of fetchDevices
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            // Setup mock response
            let mockResponse = DevicesResponse(devices: [], totalCount: 0, returnedCount: 0)
            let mockData = try! JSONEncoder().encode(mockResponse)
            MockURLProtocol.mockData = mockData
            MockURLProtocol.mockResponse = HTTPURLResponse(
                url: URL(string: "http://localhost:8000/api/devices/")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            networkManager.session = URLSession(configuration: config)
            
            networkManager.fetchDevices()
                .sink(
                    receiveCompletion: { _ in expectation.fulfill() },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: URLResponse?
    static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Clean up
    }
    
    // Reset mocks between tests
    static func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
    }
}

// MARK: - Supporting Types for Tests

struct APIErrorResponse: Codable {
    let error: Bool
    let errorCode: String
    let message: String
    let details: [String: String]
    let path: String
}