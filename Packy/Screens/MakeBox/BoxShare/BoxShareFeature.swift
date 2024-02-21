//
//  BoxShareFeature.swift
//  Packy
//
//  Created Mason Kim on 2/21/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BoxShareFeature: Reducer {

    struct BoxShareData: Equatable {
        let senderName: String
        let receiverName: String
        let boxName: String
        let boxNormalUrl: String
        var kakaoMessageImgUrl: String?
        let boxId: Int
    }

    @dynamicMemberLookup
    struct State: Equatable {
        let data: BoxShareData
        var showCompleteAnimation: Bool

        subscript<T>(dynamicMember keyPath: KeyPath<BoxShareData, T>) -> T {
            data[keyPath: keyPath]
        }
    }

    enum Action {
        // MARK: User Action
        case closeButtonTapped
        case sendButtonTapped
        case sendLaterButtonTapped

        // MARK: Inner Business Action
        case _onTask

        // MARK: Inner SetState Action
        case _setShowCompleteAnimation(Bool)

        // MARK: Child Action
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.kakaoShare) var kakaoShare

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
                // MARK: User Action
            case .closeButtonTapped:
                return .none

            case .sendButtonTapped:
                guard let kakaoMessage = makeKakaoShareMessage(from: state) else { return .none }

                // TODO: 박스 보냈다는 상태 변경
                return .run { send in
                    do {
                        try await kakaoShare.share(kakaoMessage)
                    } catch {
                        print("🐛 \(error)")
                    }
                }

            case .sendLaterButtonTapped:
                return .none

                // MARK: Inner Business Action
            case ._onTask:
                // TODO: 카카오 이미지 가져오는 API 호출
                guard state.showCompleteAnimation else { return .none }
                return .run { send in
                    try? await clock.sleep(for: .seconds(2.6))
                    await send(._setShowCompleteAnimation(false), animation: .spring(duration: 1))
                }

                // MARK: Inner SetState Action

            case let ._setShowCompleteAnimation(showCompleteAnimation):
                state.showCompleteAnimation = showCompleteAnimation
                return .none

                // MARK: Child Action
            }
        }
    }
}

private extension BoxShareFeature {
    func makeKakaoShareMessage(from state: State) -> KakaoShareMessage? {
        return KakaoShareMessage(
            sender: state.senderName,
            receiver: state.receiverName,
            imageUrl: state.kakaoMessageImgUrl ?? state.boxNormalUrl,
            boxId: "\(state.boxId)"
        )
    }
}
