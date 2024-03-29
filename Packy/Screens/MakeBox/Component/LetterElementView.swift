//
//  LetterElementView.swift
//  Packy
//
//  Created by Mason Kim on 1/29/24.
//

import SwiftUI
import Kingfisher

struct LetterElementView: View {
    let lettetContent: String
    let letterImageUrl: String
    let screenWidth: CGFloat
    var action: () -> Void = {}

    private let element = BoxElementShape.letter
    private let letterContentWidthRatio: CGFloat = 160 / 180
    private let letterContentHeightRatio: CGFloat = 130 / 150

    var body: some View {
        let size = element.size(fromScreenWidth: screenWidth)
        let letterContentWidth = letterContentWidthRatio * size.width
        let letterContentHeight = letterContentHeightRatio * size.height
        let spacing = letterContentWidth * (20 / 160)

        ZStack {
            Text(lettetContent)
                .packyFont(.body6)
                .foregroundStyle(.gray900)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .frame(width: letterContentWidth, height: letterContentHeight, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                )

            KFImage(URL(string: letterImageUrl))
                .resizable()
                .frame(width: letterContentWidth, height: letterContentHeight, alignment: .top)
                .offset(x: spacing, y: spacing)
        }
        .frame(width: size.width, height: size.height)
        .rotationEffect(.degrees(element.rotationDegree))
        .bouncyTapGesture {
            action()
        }
    }
}

#Preview {
    VStack {
        Spacer()

        LetterElementView(
            lettetContent: "ㅁㅁㅁ",
            letterImageUrl: "https://packy-bucket.s3.ap-northeast-2.amazonaws.com/admin/design/envelope/envelope_1.png",
            screenWidth: 360
        )

        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray)
}
