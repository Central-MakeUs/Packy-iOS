//
//  AddGiftBottomSheet.swift
//  Packy
//
//  Created by Mason Kim on 1/24/24.
//

import SwiftUI
import ComposableArchitecture

struct AddGiftBottomSheet: View {
    private let store: StoreOf<AddGiftFeature>
    @ObservedObject var viewStore: ViewStoreOf<AddGiftFeature>

    init(store: StoreOf<AddGiftFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("준비한 선물이 있나요?")
                    .packyFont(.heading1)
                    .foregroundStyle(.gray900)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("선물 이미지를 담아서 친구에게 보여줄 수 있어요")
                    .packyFont(.body4)
                    .foregroundStyle(.gray600)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PhotoPicker(image: viewStore.giftInput.photoData?.image) { data in
                viewStore.send(.selectGiftImage(data))
            }
            .cropAlignment(.top)
            .deleteButton(isShown: viewStore.giftInput.photoData != nil) {
                viewStore.send(.deleteGiftImageButtonTapped)
            }
            .padding(.top, 32)
            .aspectRatio(1, contentMode: .fit)

            Spacer()

            PackyButton(title: "저장", colorType: .black) {
                viewStore.send(.giftSaveButtonTapped)
            }
            .disabled(viewStore.giftInput.photoData == nil)
            .padding(.bottom, 8)

            Button("안 담을래요") {
                viewStore.send(.notSelectGiftButtonTapped)
            }
            .buttonStyle(TextButtonStyle())
            .padding(.bottom, 20)

        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview {
    MakeBoxDetailView(
        store: .init(
            initialState: .init(senderInfo: .mock, boxDesigns: .mock, selectedBox: .mock),
            reducer: {
                MakeBoxDetailFeature()
                    ._printChanges()
            }
        )
    )
}
