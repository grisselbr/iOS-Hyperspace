//
//  BackendService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation
import Result

public class BackendService {
    
    // MARK: - Properties
    
    private let networkService: NetworkServiceProtocol
    
    // MARK: - Init
    
    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    deinit {
        networkService.cancelAllTasks()
    }
}

// MARK: - BackendService Conformance to BackendServiceProtocol

extension BackendService: BackendServiceProtocol {
    public func execute<T: NetworkRequest, U>(request: T, completion: @escaping BackendServiceCompletion<U>) where T.ResponseType == U {
        networkService.execute(request: request.urlRequest) { [weak self] (result) in
            switch result {
            case .success(let result):
                self?.handleResponseData(result.data, for: request, completion: completion)
            case .failure(let result):
                DispatchQueue.main.async {
                    completion(.failure(.networkError(result.error, result.response)))
                }
            }
        }
    }
    
    public func cancelTask(for request: URLRequest) {
        networkService.cancelTask(for: request)
    }
    
    private func handleResponseData<T: NetworkRequest, U>(_ data: Data, for request: T, completion: @escaping BackendServiceCompletion<U>) where T.ResponseType == U {
        let transformResult = request.transformData(data)
        
        DispatchQueue.main.async {
            switch transformResult {
            case .success(let transformedObject):
                completion(.success(transformedObject))
            case .failure(let error):
                completion(.failure(.dataTransformationError(error)))
            }
        }
    }
}
