//
//  ArchiveView.swift
//  Packy
//
//  Created Mason Kim on 2/18/24.
//

import SwiftUI
import ComposableArchitecture

// MARK: - View

struct ArchiveView: View {
    private let store: StoreOf<ArchiveFeature>
    @ObservedObject private var viewStore: ViewStoreOf<ArchiveFeature>

    @State private var isFullScreenPresented = false

    init(store: StoreOf<ArchiveFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
                .padding(.top, 16)

            tabSelector
                .padding(.vertical, 16)

            switch viewStore.selectedTab {
            case .photo: 
                PhotoArchiveView(store: store.scope(state: \.photoArchive, action: \.photoArchive))
            case .letter:
                LetterArchiveView(store: store.scope(state: \.letterArchive, action: \.letterArchive))
            case .music:
                MusicArchiveView(store: store.scope(state: \.musicArchive, action: \.musicArchive))
            case .gift:
                GiftArchiveView(store: store.scope(state: \.giftArchive, action: \.giftArchive))
            }
        }
        .dimmedFullScreenCover(isPresented: photoPresentBinding) {
            // 실제 컨텐츠
            VStack {
                Text("여기는 Full Screen Cover입니다.")
                    .foregroundColor(.white)
                Button("닫기") {
                    photoPresentBinding.wrappedValue = false
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .background(.white)
            .frame(height: 200)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.gray100)
        .task {
            await viewStore
                .send(._onTask)
                .finish()
        }
    }
}


// MARK: - Inner Views

private extension ArchiveView {
    var navigationBar: some View {
        Text("모아보기")
            .packyFont(.heading1)
            .foregroundStyle(.gray900)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
    }

    var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(ArchiveTab.allCases, id: \.self) { tab in
                let isSelected = viewStore.selectedTab == tab
                Text(tab.description)
                    .packyFont(isSelected ? .body3 : .body4)
                    .foregroundStyle(isSelected ? .white : .gray900)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isSelected ? .gray900 : .white)
                    )
                    .onTapGesture {
                        viewStore.send(
                            .binding(.set(\.$selectedTab, tab)),
                            animation: .spring
                        )
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}

// MARK: - Inner Properties

private extension ArchiveView {
    var photoPresentBinding: Binding<Bool> {
        .init(
            get: { viewStore.photoArchive.selectedPhoto != nil },
            set: {
                guard $0 == false else { return }
                viewStore.send(.binding(.set(\.photoArchive.$selectedPhoto, nil)))
            }
        )
    }

    var letterPresentBinding: Binding<Bool> {
        .init(
            get: { viewStore.letterArchive.selectedLetter != nil },
            set: {
                guard $0 == false else { return }
                viewStore.send(.binding(.set(\.letterArchive.$selectedLetter, nil)))
            }
        )
    }

    var musicPresentBinding: Binding<Bool> {
        .init(
            get: { viewStore.musicArchive.selectedMusic != nil },
            set: {
                guard $0 == false else { return }
                viewStore.send(.binding(.set(\.musicArchive.$selectedMusic, nil)))
            }
        )
    }

    var giftPresentBinding: Binding<Bool> {
        .init(
            get: { viewStore.giftArchive.selectedGift != nil },
            set: {
                guard $0 == false else { return }
                viewStore.send(.binding(.set(\.giftArchive.$selectedGift, nil)))
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ArchiveView(
        store: .init(
            initialState: .init(),
            reducer: {
                ArchiveFeature()
                    ._printChanges()
            }
        )
    )
}
