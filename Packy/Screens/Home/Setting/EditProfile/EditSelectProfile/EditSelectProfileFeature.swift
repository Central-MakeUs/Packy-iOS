//
//  EditSelectProfileFeature.swift
//  Packy
//
//  Created Mason Kim on 2/19/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct EditSelectProfileFeature: Reducer {

    struct State: Equatable {
        var selectedImageUrl: String
        var profileImages: [ProfileImage] = []
    }

    enum Action {
        // MARK: User Action
        case backButtonTapped
        case confirmButtonTapped
        case selectProfile(ProfileImage)

        // MARK: Inner Business Action
        case _onTask

        // MARK: Inner SetState Action
        case _setProfileImages([ProfileImage])
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.designClient) var designClient

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case ._onTask:
                return fetchProfileImages()

            case .backButtonTapped, .confirmButtonTapped:
                return .run { _ in
                    await dismiss()
                }

            case let .selectProfile(profileImage):
                state.selectedImageUrl = profileImage.imageUrl
                return .none

            case let ._setProfileImages(profileImages):
                state.profileImages = profileImages
                return .none
            }
        }
    }

    private func fetchProfileImages() -> Effect<Action> {
        .run { send in
            do {
                let profileImages = try await designClient.fetchProfileImages()
                await send(._setProfileImages(profileImages))
            } catch {
                print(error)
            }
        }
    }
}
