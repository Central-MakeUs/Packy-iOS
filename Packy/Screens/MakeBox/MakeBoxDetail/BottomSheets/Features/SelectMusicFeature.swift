//
//  SelectMusicFeature.swift
//  Packy
//
//  Created by Mason Kim on 1/27/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SelectMusicFeature: Reducer {

    struct MusicInput: Equatable {
        var musicBottomSheetMode: MusicBottomSheetMode = .choice
        var musicSheetDetents: Set<PresentationDetent> = MusicBottomSheetMode.allDetents

        var musicLinkUrlInput: String = ""
        var showInvalidMusicUrlError: Bool = false

        var selectedRecommendedMusic: RecommendedMusic? = nil

        /// 최종 유저가 선택한 음악 url
        var selectedMusicUrl: String? = nil
        var isCompleted: Bool { selectedMusicUrl != nil }
    }

    @ObservableState
    struct State: Equatable {
        var isMusicBottomSheetPresented: Bool = false
        var musicInput: MusicInput = .init()
        var savedMusic: MusicInput = .init()
        var recommendedMusics: [RecommendedMusic] = []
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        case musicSelectButtonTapped
        case musicBottomSheetBackButtonTapped
        case musicChoiceUserSelectButtonTapped
        case musicChoiceRecommendButtonTapped
        case musicLinkConfirmButtonTapped
        case musicSaveButtonTapped
        case musicLinkDeleteButtonTapped
        case musicLinkDeleteButtonInSheetTapped
        case musicBottomSheetCloseButtonTapped
        case closeMusicSheetAlertConfirmTapped

        case _fetchRecommendedMusics
        case _setDetents(Set<PresentationDetent>)
        case _setRecommendedMusics([RecommendedMusic])
        case _setShowInvalidMusicUrlError(Bool)
        case _setSelectedMusicUrl(String)
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.packyAlert) var packyAlert
    @Dependency(\.adminClient) var adminClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case ._fetchRecommendedMusics:
                return fetchRecommendedMusics()

            case .musicSelectButtonTapped:
                state.musicInput = state.savedMusic
                state.isMusicBottomSheetPresented = true
                return .none

            case .binding(\.musicInput.musicLinkUrlInput):
                state.musicInput.showInvalidMusicUrlError = false
                return .none

            case .musicBottomSheetBackButtonTapped:
                guard state.musicInput.musicBottomSheetMode != .choice else { return .none }
                state.musicInput.musicLinkUrlInput = ""
                state.musicInput.selectedRecommendedMusic = nil
                state.musicInput.musicBottomSheetMode = .choice
                return changeDetentsForSmoothAnimation(for: .choice)

            case .musicChoiceUserSelectButtonTapped:
                state.musicInput.musicBottomSheetMode = .userSelect
                return changeDetentsForSmoothAnimation(for: .userSelect)

            case .musicChoiceRecommendButtonTapped:
                state.musicInput.musicBottomSheetMode = .recommend
                return changeDetentsForSmoothAnimation(for: .recommend)

            case .musicLinkConfirmButtonTapped:
                let youtubeLinkUrl = state.musicInput.musicLinkUrlInput
                return .run { send in
                    do {
                        let isValidLink = try await adminClient.validateYoutubeUrl(youtubeLinkUrl)
                        await send(._setShowInvalidMusicUrlError(!isValidLink))

                        guard isValidLink else { return }
                        await send(._setSelectedMusicUrl(youtubeLinkUrl))
                    } catch {
                        await send(._setShowInvalidMusicUrlError(false))
                    }
                }

            case .musicSaveButtonTapped:
                let selectedMusicUrl: String?
                switch state.musicInput.musicBottomSheetMode {
                case .choice:
                    selectedMusicUrl = nil
                case .userSelect:
                    selectedMusicUrl = state.musicInput.musicLinkUrlInput
                case .recommend:
                    // 첫 번째 요소는 가끔 centeredItem 이 안먹기에, nil이면 첫번째 요소로 지정
                    selectedMusicUrl = (state.musicInput.selectedRecommendedMusic ?? state.recommendedMusics.first)?.youtubeUrl
                }
                state.savedMusic = .init(selectedMusicUrl: selectedMusicUrl)
                state.isMusicBottomSheetPresented = false
                return .none

            case .musicLinkDeleteButtonTapped:
                state.savedMusic = .init()
                return .none

            case .musicLinkDeleteButtonInSheetTapped:
                state.musicInput.musicLinkUrlInput = ""
                state.musicInput.selectedMusicUrl = nil
                return .none

            case let ._setRecommendedMusics(recommendedMusics):
                state.recommendedMusics = recommendedMusics
                return .none

            case let ._setDetents(detents):
                state.musicInput.musicSheetDetents = detents
                return .none

            case let ._setShowInvalidMusicUrlError(isError):
                state.musicInput.showInvalidMusicUrlError = isError
                return .none

            case let ._setSelectedMusicUrl(url):
                state.musicInput.selectedMusicUrl = url
                return .none

            case .musicBottomSheetCloseButtonTapped:
                guard state.savedMusic.selectedMusicUrl != state.musicInput.selectedMusicUrl else {
                    state.isMusicBottomSheetPresented = false
                    return .none
                }

                return .run { send in
                    await packyAlert.show(
                        .init(
                            title: "저장하지 않고 나가시겠어요?",
                            description: "입력한 내용이 선물박스에 담기지 않아요",
                            cancel: "취소",
                            confirm: "확인",
                            confirmAction: { await send(.closeMusicSheetAlertConfirmTapped) }
                        )
                    )
                }

            case .closeMusicSheetAlertConfirmTapped:
                state.musicInput = .init()
                state.isMusicBottomSheetPresented = false
                return .none

            default:
                return .none
            }
        }
    }

}

// MARK: - Inner Functions

private extension SelectMusicFeature {
    /// 바텀시트의 detent를 변경함으로서 사이즈를 조절할 때, 가능한 detents들에 전후의 detent가 포함되어 있어야 애니메이션 적용됨
    /// 하지만, 모두 주면 아예 detent 를 변경할 수 있는 형태가 되기에, 0.1 초 후에 detents 변경
    func changeDetentsForSmoothAnimation(for mode: MusicBottomSheetMode) -> Effect<Action> {
        .run { send in
            await send(._setDetents(MusicBottomSheetMode.allDetents))
            try? await clock.sleep(for: .seconds(0.1))
            await send(._setDetents([mode.detent]))
        }
    }

    func fetchRecommendedMusics() -> Effect<Action> {
        .run { send in
            do {
                let recommendedMusics = try await adminClient.fetchRecommendedMusics()
                await send(._setRecommendedMusics(recommendedMusics))
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - MusicBottomSheetMode

enum MusicBottomSheetMode: CaseIterable {
    case choice
    case userSelect
    case recommend

    var detent: PresentationDetent {
        switch self {
        case .choice:
            return .height(383)
        case .userSelect, .recommend:
            return .large
        }
    }

    static var allDetents: Set<PresentationDetent> {
        Set(Self.allCases.map(\.detent))
    }
}
