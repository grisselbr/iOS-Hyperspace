//
//  NetworkService.swift
//  Hyperspace
//
//  Created by Tyler Milner on 6/26/17.
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

//
//  TODO: Future functionality:
//          - Provide an implementation that uses the URLSession delegate methods.
//          - Look into using an ephemeral URLSession as the default NetworkSession since it requires no cleanup.
//          - Look into initialization using a session configuration rather than a NetworkSession.
//

import Foundation

/// Adopts the NetworkServiceProtocol to perform HTTP communication via the execution of URLRequests.
public class NetworkService {

    // MARK: - Properties

    let session: NetworkSession
    private var networkActivityController: NetworkActivityController?
    private var tasks = [URLRequest: NetworkSessionDataTask]()

    // MARK: - Init

    public init(session: NetworkSession = URLSession.shared, networkActivityController: NetworkActivityController? = nil) {
        self.session = session
        self.networkActivityController = networkActivityController
    }

    public convenience init(session: NetworkSession = URLSession.shared, networkActivityIndicatable: NetworkActivityIndicatable) {
        let networkActivityController = NetworkActivityController(indicator: networkActivityIndicatable)
        self.init(session: session, networkActivityController: networkActivityController)
    }

    deinit {
        cancelAllTasks()
    }
}

// MARK: - NetworkService Conformance to NetworkServiceProtocol

extension NetworkService: NetworkServiceProtocol {

    public func execute(request: URLRequest, completion: @escaping NetworkServiceCompletion) {
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            self?.networkActivityController?.stop()

            guard let response = response as? HTTPURLResponse else {
                // TODO: - CHANGED
                let networkFailure = NetworkServiceHelper.networkServiceFailure(for: error, urlResponse: response)
                completion(.failure(networkFailure))
                return
            }

            let statusCode = response.statusCode
            let headers = response.allHeaderFields as? [String: String]
            let httpResponse = HTTP.Response(code: statusCode, data: data, headers: headers)
            // TODO: - CHANGED
            let networkResult = NetworkServiceHelper.networkServiceResult(for: httpResponse, urlResponse: response)
            completion(networkResult)
        }

        tasks[request] = task
        task.resume()
        networkActivityController?.start()
    }

    public func cancelTask(for request: URLRequest) {
        tasks[request]?.cancel()
    }

    public func cancelAllTasks() {
        tasks.forEach { cancelTask(for: $0.key) }
    }
}
