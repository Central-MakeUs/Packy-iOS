//
//  TermsAgreementFeature.swift
//  Packy
//
//  Created Mason Kim on 1/7/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct TermsAgreementFeature: Reducer {

    @ObservableState
    struct State: Equatable {
        let socialLoginInfo: SocialLoginInfo
        let nickName: String
        let selectedProfileId: Int

        var termsStates: [Terms: Bool] = Terms.allCases.reduce(into: [Terms: Bool]()) {
            $0[$1] = false
        }
        var isAllTermsAgreed: Bool {
            termsStates.allSatisfy { $1 == true }
        }
        var isAllRequiredTermsAgreed: Bool {
            termsStates
                .filter { $0.key.isRequired }
                .allSatisfy { $1 == true }
        }

        var isATTCompleted: Bool = false
        var isATTAuthorized: Bool = false
        var isNotificationAllowed: Bool = false

        var isAllowNotificationBottomSheetPresented: Bool = false
    }

    enum Action: BindableAction {
        // MARK: User Action
        case binding(BindingAction<State>)
        case backButtonTapped
        case agreeTermsButtonTapped(Terms)
        case agreeAllTermsButtonTapped
        case confirmButtonTapped

        case allowNotificationButtonTapped

        // MARK: Inner Business Action
        case _onAppear
        case _signUp

        // MARK: Inner SetState Action
        case _setATTCompleted
        case _setATTAuthorized(Bool)
        case _setNotificationAllowed(Bool)

        // MARK: Delegate Action
        enum Delegate {
            case completedSignUp
        }
        case delegate(Delegate)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userNotification) var userNotification
    @Dependency(\.authClient) var authClient
    @Dependency(\.keychain) var keychain
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case ._onAppear:
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                }

            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case .confirmButtonTapped:
                return .run { send in
                    await ATTManager.requestAuthorization()

                    let isATTAuthorized = ATTManager.isAuthorized
                    await send(._setATTAuthorized(isATTAuthorized))
                    await send(._setATTCompleted)
                }

            case let .agreeTermsButtonTapped(terms):
                state.termsStates[terms]?.toggle()
                return .none

            case .agreeAllTermsButtonTapped:
                let isAllTermsAgreed = state.isAllTermsAgreed
                Terms.allCases.forEach {
                    state.termsStates[$0] = !isAllTermsAgreed
                }
                return .none

            case .allowNotificationButtonTapped:
                return .run { send in
                    let isGranted = try await userNotification.requestAuthorization([.alert, .badge, .sound])
                    await send(.binding(.set(\.isAllowNotificationBottomSheetPresented, false)))
                    await send(._setNotificationAllowed(isGranted))
                    print("🔔 UserNotification isGranted: \(isGranted)")

                    await send(._signUp)
                }


            // TODO: ATT, Push Noti 이미 해제했을 땐 안띄우게 로직 구현 필요
            case ._setATTCompleted:
                /// 알림 권한 부여 하는 릴리즈라면 해당 코드 사용
                // state.isATTCompleted = true
                // state.isAllowNotificationBottomSheetPresented = true
                // return .none

                /// 1차 릴리즈 범위에서는 알림 기능 제거
                state.isATTCompleted = true
                return .run { send in
                    await send(._signUp)
                }


            case let ._setATTAuthorized(isATTAuthorized):
                state.isATTAuthorized = isATTAuthorized
                return .none

            case let ._setNotificationAllowed(isAllowed):
                state.isNotificationAllowed = isAllowed
                return .none

            case ._signUp:
                return .run { [state] send in
                    let request = buildSignUpRequest(from: state)

                    do {
                        let response = try await authClient.signUp(state.socialLoginInfo.authorization, request)

                        guard let accessToken = response.accessToken,
                              let refreshToken = response.refreshToken else { return }

                        keychain.save(.accessToken, accessToken)
                        keychain.save(.refreshToken, refreshToken)

                        await send(.delegate(.completedSignUp), animation: .spring)
                    } catch {
                        // TODO: 에러 핸들링
                        print(error)
                    }
                }

            default:
                return .none
            }
        }
    }

    private func buildSignUpRequest(from state: State) -> SignUpRequest {
        SignUpRequest(
            provider: state.socialLoginInfo.provider,
            nickname: state.nickName,
            profileImg: state.selectedProfileId,
            pushNotification: state.isNotificationAllowed,
            marketingAgreement: state.isATTAuthorized
        )
    }
}
