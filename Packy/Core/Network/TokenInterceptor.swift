//
//  TokenInterceptor.swift
//  Packy
//
//  Created by Mason Kim on 1/23/24.
//

import Alamofire
import Dependencies
import Foundation

final class TokenInterceptor: RequestInterceptor {

    @Dependency(\.keychain) var keychain
    @Dependency(\.authClient) var authClient

    static let shared = TokenInterceptor()
    private init() { }

    /// AccessToken 헤더에 삽입
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let accessToken = keychain.read(.accessToken) else {
            completion(.success(urlRequest))
            return
        }

        var urlRequest = urlRequest
        urlRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))

        print("🧤 Intercepted Token+Request : ", urlRequest.headers)
    }
    
    /// AccessToken 재발급
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }

        guard let accessToken = keychain.read(.accessToken),
              let refreshToken = keychain.read(.refreshToken) else {
            completion(.doNotRetryWithError(error))
            return
        }
        let tokenRequest = TokenRequest(accessToken: accessToken, refreshToken: refreshToken)

        Task {
            do {
                let tokenResponse = try await authClient.reissueToken(tokenRequest)

                guard let accessToken = tokenResponse.accessToken,
                      let refreshToken = tokenResponse.refreshToken else {
                    completion(.doNotRetryWithError(error))
                    return
                }

                keychain.save(.accessToken, accessToken)
                keychain.save(.refreshToken, refreshToken)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }

}
