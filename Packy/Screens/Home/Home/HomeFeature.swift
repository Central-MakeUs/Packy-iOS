//
//  HomeFeature.swift
//  Packy
//
//  Created Mason Kim on 2/4/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct HomeFeature: Reducer {

    struct State: Equatable {
        var giftBoxes: [SentReceivedGiftBox] = []
        var isShowDetailLoading: Bool = false
    }

    enum Action {
        // MARK: User Action
        case tappedGiftBox(boxId: Int)
        case viewMoreButtonTapped

        // MARK: Inner Business Action
        case _onTask

        // MARK: Inner SetState Action
        case _setGiftBoxes([SentReceivedGiftBox])
        case _setShowDetailLoading(Bool)

        // MARK: Delegate Action
        enum Delegate {
            case moveToBoxDetail(ReceivedGiftBox)
            case moveToMyBox
        }
        case delegate(Delegate)
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.boxClient) var boxClient

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case ._onTask:
                return fetchGiftBoxes()

            case let .tappedGiftBox(boxId):
                state.isShowDetailLoading = true
                return .run { send in
                    do {
                        let giftBox = try await boxClient.openGiftBox(boxId)
                        await send(.delegate(.moveToBoxDetail(giftBox)))
                        await send(._setShowDetailLoading(false))
                    } catch {
                        print("🐛 \(error)")
                    }
                }

            case .viewMoreButtonTapped:
                return .send(.delegate(.moveToMyBox))

            case let ._setGiftBoxes(giftBoxes):
                state.giftBoxes = giftBoxes
                return .none

            case let ._setShowDetailLoading(isLoading):
                state.isShowDetailLoading = isLoading
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension HomeFeature {
    func fetchGiftBoxes() -> Effect<Action> {
        .run { send in
            do {
                let giftBoxesData = try await boxClient.fetchGiftBoxes(.init())
                await send(._setGiftBoxes(giftBoxesData.giftBoxes))
            } catch {
                print("🐛 \(error)")
            }
        }
    }
}
