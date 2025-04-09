//
//  AIWorkoutServiceTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
import Foundation
@testable import Smart_Swim

final class AIWorkoutServiceTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: AIWorkoutService!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureService()
    }
    
    override func tearDown() {
        URLProtocol.unregisterClass(MockURLWorkoutProtocol.self)
        sut = nil
        super.tearDown()
    }
    
    func configureService() {
        sut = AIWorkoutService.shared
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLWorkoutProtocol.self]
        URLProtocol.registerClass(MockURLWorkoutProtocol.self)
    }
    
    // MARK: - Tests
    func testGenerateRecommendationSuccess() {
        let mockWorkout = createMockWorkoutSession()
        mockWorkout.mockExerciseSessions = createMockExerciseSessions()
        
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
                        "content": "Your training analysis is great!"
                    },
                    "finish_reason": "stop"
                }
            ]
        }
        """
        let url = "https://api.deepseek.com/v1/chat/completions"
        MockURLWorkoutProtocol.mockResponses = [
            url: (
                Data(successResponse.utf8),
                HTTPURLResponse(
                    url: URL(string: url)!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                nil
            )
        ]
        
        let expectation = self.expectation(description: "Recommendation generated successfully")
        
        sut.generateRecommendation(for: mockWorkout) { result in
            switch result {
            case .success(let recommendation):
                XCTAssertEqual(recommendation, "Your training analysis is great!")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but failed with error: \(error)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationFailure() {
        let mockWorkout = createMockWorkoutSession()
        mockWorkout.mockExerciseSessions = createMockExerciseSessions()
        
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
        let url = "https://api.deepseek.com/v1/chat/completions"
        MockURLWorkoutProtocol.mockResponses = [
            url: (
                Data(errorResponse.utf8),
                HTTPURLResponse(
                    url: URL(string: url)!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!,
                nil
            )
        ]
        
        let expectation = self.expectation(description: "Recommendation generation fails with API error")
        
        sut.generateRecommendation(for: mockWorkout) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case .apiError(let message) = error {
                    XCTAssertTrue(message.contains("Invalid API key"))
                    expectation.fulfill()
                } else {
                    XCTFail("Expected apiError but got: \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationNetworkError() {
        let mockWorkout = createMockWorkoutSession()
        mockWorkout.mockExerciseSessions = createMockExerciseSessions()
        
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let url = "https://api.deepseek.com/v1/chat/completions"
        MockURLWorkoutProtocol.mockResponses = [
            url: (nil, nil, networkError)
        ]
        
        let expectation = self.expectation(description: "Recommendation generation fails with network error")
        
        sut.generateRecommendation(for: mockWorkout) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                if case .networkError(let underlyingError) = error {
                    let nsError = underlyingError as NSError
                    XCTAssertEqual(nsError.domain, NSURLErrorDomain)
                    XCTAssertEqual(nsError.code, NSURLErrorNotConnectedToInternet)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected networkError but got: \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testGenerateRecommendationWithNoExercises() {
        let mockWorkout = createMockWorkoutSession()
        mockWorkout.mockExerciseSessions = []
        
        let expectation = self.expectation(description: "Recommendation generation fails due to no exercises")
        
        sut.generateRecommendation(for: mockWorkout) { result in
            switch result {
            case .success:
                XCTFail("Expected failure due to no exercises but got success")
            case .failure(let error):
                if case .invalidResponse = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidResponse error but got: \(error)")
                }
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - MockURLProtocol
class MockURLWorkoutProtocol: URLProtocol {
    static var mockResponses: [String: (Data?, URLResponse?, Error?)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let urlString = request.url?.absoluteString,
              let (data, response, error) = MockURLWorkoutProtocol.mockResponses[urlString] else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() { }
}
