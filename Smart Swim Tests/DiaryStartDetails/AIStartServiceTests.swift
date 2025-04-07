//
//  AIStartServiceTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class AIStartServiceTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: AIStartService!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureAIStartService()
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureAIStartService() {
        sut = AIStartService.shared
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        URLProtocol.registerClass(MockURLProtocol.self)
        
        let session = URLSession(configuration: configuration)
        MockURLSession.shared = session
    }
    
    // MARK: - Recommendation Generation Tests
    func testGenerateRecommendationSuccess() {
        // Arrange
        let mockStart = MockStartEntity()
        let mockLap = MockLapEntity()
        mockStart.laps = NSSet(array: [mockLap])
        
        let successResponse = """
        {
            "id": "123456",
            "object": "chat.completion",
            "created": 1680000000,
            "model": "deepseek-reasoner",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Your swimming technique is excellent!"
                    },
                    "finish_reason": "stop"
                }
            ]
        }
        """
        MockURLProtocol.mockResponses = [
            "https://api.deepseek.com/v1/chat/completions": (
                Data(successResponse.utf8),
                HTTPURLResponse(
                    url: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                nil
            )
        ]
        
        let expectation = self.expectation(description: "API call completed")
        
        // Act
        sut.generateRecommendation(for: mockStart) { result in
            // Assert
            switch result {
            case .success(let recommendation):
                XCTAssertEqual(recommendation, "Your swimming technique is excellent!")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got failure: \(error.localizedDescription)")
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationFailure() {
        // Arrange
        let mockStart = MockStartEntity()
        let mockLap = MockLapEntity()
        mockStart.laps = NSSet(array: [mockLap])
        
        let errorResponse = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "invalid_request_error",
                "param": null,
                "code": "invalid_api_key"
            }
        }
        """
        MockURLProtocol.mockResponses = [
            "https://api.deepseek.com/v1/chat/completions": (
                Data(errorResponse.utf8),
                HTTPURLResponse(
                    url: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                nil
            )
        ]
        
        let expectation = self.expectation(description: "API call completed with error")
        
        // Act
        sut.generateRecommendation(for: mockStart) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case .apiError(let message) = error {
                    XCTAssertTrue(message.contains("Invalid API key"))
                } else {
                    XCTFail("Expected apiError but got \(error)")
                }
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationNetworkError() {
        // Arrange
        let mockStart = MockStartEntity()
        let mockLap = MockLapEntity()
        mockStart.laps = NSSet(array: [mockLap])
        
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        MockURLProtocol.mockResponses = [
            "https://api.deepseek.com/v1/chat/completions": (
                nil,
                nil,
                networkError
            )
        ]
        
        let expectation = self.expectation(description: "API call completed with network error")
        
        // Act
        sut.generateRecommendation(for: mockStart) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case .networkError(let underlyingError) = error {
                    XCTAssertEqual((underlyingError as NSError).domain, NSURLErrorDomain)
                    XCTAssertEqual((underlyingError as NSError).code, NSURLErrorNotConnectedToInternet)
                } else {
                    XCTFail("Expected networkError but got \(error)")
                }
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationWithNoLaps() {
        // Arrange
        let mockStart = MockStartEntity()
        mockStart.mockLaps = nil
        
        let expectation = self.expectation(description: "API call fails with no laps")
        
        // Act
        sut.generateRecommendation(for: mockStart) { result in
            // Assert
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case .invalidResponse = error {
                    // This is what we expect
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidResponse error but got \(error)")
                }
            }
        }
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Helper Classes
class MockStartEntity: StartEntity {
    var mockDate: Date = Date()
    var mockPoolSize: Int16 = 25
    var mockTotalMeters: Int16 = 50
    var mockSwimmingStyle: Int16 = 0
    var mockTotalTime: Double = 60.0
    var mockRecommendation: String?
    var mockLaps: NSSet?
    
    override var date: Date {
        get { return mockDate }
        set { mockDate = newValue }
    }
    
    override var poolSize: Int16 {
        get { return mockPoolSize }
        set { mockPoolSize = newValue }
    }
    
    override var totalMeters: Int16 {
        get { return mockTotalMeters }
        set { mockTotalMeters = newValue }
    }
    
    override var swimmingStyle: Int16 {
        get { return mockSwimmingStyle }
        set { mockSwimmingStyle = newValue }
    }
    
    override var totalTime: Double {
        get { return mockTotalTime }
        set { mockTotalTime = newValue }
    }
    
    override var recommendation: String? {
        get { return mockRecommendation }
        set { mockRecommendation = newValue }
    }
    
    override var laps: NSSet? {
        get { return mockLaps }
        set { mockLaps = newValue }
    }
}

class MockLapEntity: LapEntity {
    var mockLapNumber: Int16 = 1
    var mockLapTime: Double = 30.0
    var mockPulse: Int16 = 150
    var mockStrokes: Int16 = 20
    
    override var lapNumber: Int16 {
        get { return mockLapNumber }
        set { mockLapNumber = newValue }
    }
    
    override var lapTime: Double {
        get { return mockLapTime }
        set { mockLapTime = newValue }
    }
    
    override var pulse: Int16 {
        get { return mockPulse }
        set { mockPulse = newValue }
    }
    
    override var strokes: Int16 {
        get { return mockStrokes }
        set { mockStrokes = newValue }
    }
}

class MockURLProtocol: URLProtocol {
    static var mockResponses: [String: (Data?, URLResponse?, Error?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let url = request.url?.absoluteString,
           let (data, response, error) = MockURLProtocol.mockResponses[url] {
            
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
    }
}

class MockURLSession {
    static var shared: URLSession = .shared
}

extension AIStartService {
    func getURLSession() -> URLSession {
        return MockURLSession.shared
    }
}
