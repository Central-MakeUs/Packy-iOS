//
//  CarouselView.swift
//  Packy
//
//  Created by Mason Kim on 1/12/24.
//

import SwiftUI


struct CarouselView<Content: View, Item: Identifiable>: View {
    private let itemWidth: CGFloat
    private let itemPadding: CGFloat
    private let contentBuilder: (Item) -> Content
    private let items: [Item]
    private var minifyScale: CGFloat = 1 // 좌우의 효과에 의해 작아진 아이템의 scale

    init(
        items: [Item],
        itemWidth: CGFloat,
        itemPadding: CGFloat,
        @ViewBuilder contentBuilder: @escaping (Item) -> Content
    ) {
        self.items = items
        self.itemWidth = itemWidth
        self.itemPadding = itemPadding
        self.contentBuilder = contentBuilder
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                HStack(spacing: -generatedPaddingByMinifyScale) {
                    ForEach(items) { item in
                        contentBuilder(item)
                            .frame(width: itemWidth)
                            .padding(.horizontal, itemPadding / 2)
                            .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                view
                                    .scaleEffect(phase.isIdentity ? 1 : minifyScale)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .safeAreaPadding(.horizontal, safeAreaPadding(geometryWidth: geometry.size.width))
        }
    }


    private func safeAreaPadding(geometryWidth: CGFloat) -> CGFloat {
        (geometryWidth - itemWidth - itemPadding) / 2
    }

    /// 좌우 아이템 작게 만드는 효과에 의해 생성된 패딩값
    private var generatedPaddingByMinifyScale: CGFloat {
        // 원래 width 500 -> 0.8 배율 -> 작아진 width 400 ...
        // 차이값 100 / 2 인 50 만큼 padding 생김. -> 해당 값만큼 HStack padding 에 빼주면 됨
        let sizeDifference = (1 - minifyScale) * itemWidth
        return sizeDifference / 2
    }
}

extension CarouselView {
    /// 스크롤을 할 때, 좌우의 아이템이 작아지는 효과를 부여
    func minifyScale(_ minifyScale: CGFloat) -> Self {
        var carousel = self
        carousel.minifyScale = minifyScale
        return carousel
    }
}

extension Color: Identifiable {
    public var id: String { self.description }
}

#Preview {
    VStack {
        let colors: [Color] = [.red, .blue, .black, .yellow, .green]

        // 음악 플레이어 스타일
        let itemSize1: CGFloat = 180
        let itemPadding1: CGFloat = 50
        CarouselView(items: colors, itemWidth: itemSize1, itemPadding: itemPadding1) {
            Circle()
                .fill($0)
        }
        .minifyScale(0.8)

        // 앨범 스타일
        let itemSize2: CGFloat = 280
        let itemPadding2: CGFloat = 24
        CarouselView(items: colors, itemWidth: itemSize2, itemPadding: itemPadding2) {
            Rectangle()
                .fill($0)
        }
    }
}