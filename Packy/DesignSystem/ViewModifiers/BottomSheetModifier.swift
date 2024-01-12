//
//  BottomSheetModifier.swift
//  Packy
//
//  Created by Mason Kim on 1/11/24.
//

import SwiftUI

extension View {
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent>,
        sheetContent: @escaping () -> Content
    ) -> some View {
        modifier(
            BottomSheetModifier(isPresented: isPresented, detents: detents, sheetContent: sheetContent)
        )
    }
}

struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let sheetContent: () -> SheetContent

    func body(content baseContent: Content) -> some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .zIndex(1)
                .opacity(isPresented ? 0.6 : 0)
                .animation(.spring, value: isPresented)

            baseContent
                .sheet(isPresented: $isPresented) {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            CloseButton(colorType: .light) {
                                isPresented = false
                            }
                        }
                        .padding(.top, 8)
                        
                        self.sheetContent()
                    }
                    .padding(.horizontal, 24)
                    .presentationCornerRadius(24)
                    .presentationDetents(detents)
                    .interactiveDismissDisabled()
                }
        }
    }
}
