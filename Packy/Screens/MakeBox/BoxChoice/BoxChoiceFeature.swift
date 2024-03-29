//
//  BoxChoiceFeature.swift
//  Packy
//
//  Created Mason Kim on 1/14/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BoxChoiceFeature: Reducer {

    struct PassingData {
        let senderInfo: BoxSenderInfo
        let selectedBox: BoxDesign?
        let boxDesigns: [BoxDesign]
    }

    @ObservableState
    struct State: Equatable {
        let senderInfo: BoxSenderInfo
        var selectedBox: BoxDesign?
        var selectedMessage: Int = 0
        var isPresentingFinishedMotionView: Bool = false
        var didShowBoxMotion: Bool = false

        var boxDesigns: [BoxDesign] = []

        fileprivate var passingData: PassingData {
            .init(
                senderInfo: senderInfo,
                selectedBox: selectedBox,
                boxDesigns: boxDesigns
            )
        }
    }

    enum Action: BindableAction {
        // MARK: User Action
        case binding(BindingAction<State>)
        case selectBox(BoxDesign)
        case backButtonTapped
        case nextButtonTapped
        case closeButtonTapped

        // MARK: Inner Business Action
        case _onTask

        // MARK: Inner SetState Action
        case _setIsPresentingFinishedMotionView(Bool)
        case _setBoxDesigns([BoxDesign])

        // MARK: Delegate Action
        enum Delegate {
            case moveToMakeBoxDetail(PassingData)
            case closeMakeBox
        }
        case delegate(Delegate)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.adminClient) var adminClient
    @Dependency(\.packyAlert) var packyAlert
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case ._onTask:
                return .run { send in
                    do {
                        let boxDesigns = try await adminClient.fetchBoxDesigns()
                        await send(._setBoxDesigns(boxDesigns), animation: .spring)
                        if let firstBox = boxDesigns.first {
                            await send(.selectBox(firstBox), animation: .spring)
                        }
                    } catch {
                        print(error)
                    }
                }

            case let .selectBox(boxDesign):
                state.selectedBox = boxDesign
                return .none

            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case .nextButtonTapped:
                guard !state.didShowBoxMotion else {
                    return .send(.delegate(.moveToMakeBoxDetail(state.passingData)))
                }
                state.didShowBoxMotion = true
                return showBoxMotion(state.passingData)

            case .closeButtonTapped:
                return .run { send in
                    await packyAlert.show(
                        .init(
                            title: "선물박스 만들기를 종료할까요?",
                            cancel: "취소",
                            confirm: "확인",
                            confirmAction: {
                                await send(.delegate(.closeMakeBox))
                            }
                        )
                    )
                }

            case let ._setIsPresentingFinishedMotionView(isPresented):
                state.isPresentingFinishedMotionView = isPresented
                return .none

            case let ._setBoxDesigns(boxDesigns):
                state.boxDesigns = boxDesigns
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Inner Functions

private extension BoxChoiceFeature {
    func showBoxMotion(_ passingData: PassingData) -> Effect<Action> {
        .run { send in
            await send(._setIsPresentingFinishedMotionView(true))
            try? await clock.sleep(for: .seconds(Constants.makeBoxAnimationDuration))

            await send(.delegate(.moveToMakeBoxDetail(passingData)))

            try? await clock.sleep(for: .seconds(0.1))
            await send(._setIsPresentingFinishedMotionView(false))
        }
    }
}
