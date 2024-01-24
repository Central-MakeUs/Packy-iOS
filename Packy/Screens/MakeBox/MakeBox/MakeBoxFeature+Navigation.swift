//
//  MakeBoxFeature+Navigation.swift
//  Packy
//
//  Created Mason Kim on 1/14/24.
//

import ComposableArchitecture

// MARK: - Navigation Path

@Reducer
struct MakeBoxNavigationPath {
    enum State: Equatable {
        case boxChoice(BoxChoiceFeature.State)
        case startGuide(BoxStartGuideFeature.State)
    }

    enum Action {
        case boxChoice(BoxChoiceFeature.Action)
        case startGuide(BoxStartGuideFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.boxChoice, action: \.boxChoice) { BoxChoiceFeature() }
        Scope(state: \.startGuide, action: \.startGuide) { BoxStartGuideFeature() }
    }
}

// MARK: - Navigation Reducer

extension MakeBoxFeature {
    var navigationReducer: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .path(action):
                switch action {
                case let .element(id: _, action: .boxChoice(.delegate(.moveToBoxStartGuide(data)))):
                    state.path.append(.startGuide(.init(senderInfo: data.senderInfo, selectedBox: data.selectedBoxIndex, boxDesigns: data.boxDesigns)))
                    return .none

                case .element:
                    return .none

                default:
                    return .none
                }

            default:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            MakeBoxNavigationPath()
        }
    }
}
