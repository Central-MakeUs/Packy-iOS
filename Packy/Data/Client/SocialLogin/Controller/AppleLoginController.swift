//
//  AppleLoginController.swift
//  Packy
//
//  Created by Mason Kim on 1/8/24.
//

import Foundation
import AuthenticationServices

enum AppleLoginError: LocalizedError {
    case invalidCredential
    case invalidIdentityToken
    case invalidAuthorizationCode
    case transferError(Error)
}

final class AppleLoginController: NSObject, ASAuthorizationControllerDelegate {

    private var continuation: CheckedContinuation<SocialLoginInfo, Error>?

    func login() async throws -> SocialLoginInfo {
        try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()

            if self.continuation == nil {
                self.continuation = continuation
            }
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleLoginError.invalidCredential)
            continuation = nil
            return
        }

        let email = credential.email
        print("🍎 appleLogin email \(email ?? "")")

        let fullName = credential.fullName
        print("🍎 appleLogin fullName \(fullName?.description ?? "")")

        guard let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleLoginError.invalidIdentityToken)
            continuation = nil
            return
        }

        guard let authorizationCode = credential.authorizationCode,
              let codeString = String(data: authorizationCode, encoding: .utf8) else {
            continuation?.resume(throwing: AppleLoginError.invalidAuthorizationCode)
            continuation = nil
            return
        }
        print("🍎 appleLogin token \(token)")
        print("🍎 appleLogin authorizationCode \(codeString)")

        let userIdentifier = credential.user

        print("🍎 appleLogin fullName: \(fullName?.description ?? "")")

        let info = SocialLoginInfo(
            id: userIdentifier,
            authorization: codeString, 
            identityToken: token,
            name: fullName?.givenName,
            email: email,
            provider: .apple
        )
        continuation?.resume(returning: info)
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
