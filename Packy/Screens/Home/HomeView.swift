//
//  HomeView.swift
//  Packy
//
//  Created Mason Kim on 1/7/24.
//

import SwiftUI
import ComposableArchitecture

// MARK: - View

struct HomeView: View {
    private let store: StoreOf<HomeFeature>
    @ObservedObject private var viewStore: ViewStoreOf<HomeFeature>

    init(store: StoreOf<HomeFeature>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }

    var body: some View {
        VStack(spacing: 16) {
            navigationBar
                .padding(.top, 8)

            RoundedRectangle(cornerRadius: 24)
                .fill(.black)
                .frame(height: 320)

            VStack(spacing: 24) {
                HStack {
                    Text("주고받은 선물박스")
                        .packyFont(.heading2)
                        .foregroundStyle(.gray900)

                    Spacer()

                    // TODO: 네비게이션 링크로 대체
                    // NavigationLink("더보기", state: )
                    Button("더보기") {

                    }
                    .buttonStyle(.text)
                }
                .padding(.horizontal, 24)


                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(1...10, id: \.self) { index in
                            BoxInfoCell(
                                boxUrl: "https://picsum.photos/200",
                                sender: "hello",
                                boxTitle: String(repeating: "선물", count: index)
                            )
                        }
                    }
                }
                .safeAreaPadding(.horizontal, 24)
                .scrollIndicators(.hidden)
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
            )


            Spacer()
        }
        .padding(.horizontal, 16)
        .background(.gray100)
        .task {
            await viewStore
                .send(._onAppear)
                .finish()
        }
    }
}

// MARK: - Inner Views

private extension HomeView {
    var navigationBar: some View {
        HStack {
            Image(.logo)

            Spacer()

            // TODO: 네비게이션 링크로 대체
            Button {} label: {
                // NavigationLink(state: ) {
                Image(.setting)
            }
        }
        .frame(height: 48)
    }
}

private struct BoxInfoCell: View {
    var boxUrl: String
    var sender: String
    var boxTitle: String

    var body: some View {
        VStack(spacing: 0) {
            NetworkImage(url: boxUrl)
                .mask(RoundedRectangle(cornerRadius: 8))
                .frame(height: 138)
                .padding(.bottom, 12)

            Text("From: \(sender)")
                .packyFont(.body6)
                .foregroundStyle(.purple500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            Text(boxTitle)
                .packyFont(.body3)
                .foregroundStyle(.gray900)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .frame(width: 120)
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        store: .init(
            initialState: .init(),
            reducer: {
                HomeFeature()
                    ._printChanges()
            }
        )
    )
}
