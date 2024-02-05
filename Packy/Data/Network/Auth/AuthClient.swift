//
//  AuthClient.swift
//  Packy
//
//  Created Mason Kim on 1/15/24.
//

import Foundation
import Dependencies
import Moya

// MARK: - Dependency Values

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

// MARK: - AuthClient Client

struct AuthClient {
    /// 회원가입
    var signUp: @Sendable (_ authorization: String, SignUpRequest) async throws -> TokenInfoResponse
    /// 로그인
    var signIn: @Sendable (SignInRequest) async throws -> SignInResponse
    /// 회원 탈퇴
    var withdraw: @Sendable () async throws -> String
    /// 토큰 재발급
    var reissueToken: @Sendable (TokenRequest) async throws -> TokenInfoResponse
    /// 설정 메뉴 링크들 조회
    var fetchSettingMenus: @Sendable () async throws -> SettingMenuResponse
}

extension AuthClient: DependencyKey {
    static let liveValue: Self = {
        let nonTokenProvider = MoyaProvider<AuthEndpoint>.buildNonToken()
        let provider = MoyaProvider<AuthEndpoint>.build()

        return Self(
            signUp: {
                try await nonTokenProvider.request(.signUp(authorization: $0, request: $1))
            },
            signIn: {
                try await nonTokenProvider.request(.signIn(request: $0))
            },
            withdraw: {
                try await provider.request(.withdraw)
            },
            reissueToken: {
                try await nonTokenProvider.request(.reissueToken(request: $0))
            },
            fetchSettingMenus: {
                try await provider.request(.settings)
            }
        )
    }()

    static let previewValue: Self = {
        Self(
            signUp: { _, _ in .mock },
            signIn: { _ in .mock },
            withdraw: { "" },
            reissueToken: { _ in .mock },
            fetchSettingMenus: { .mock }
        )
    }()
}
