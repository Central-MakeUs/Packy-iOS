//
//  PhotoElement.swift
//  Packy
//
//  Created by Mason Kim on 1/12/24.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct PhotoElement: View {
    var imageUrl: String?
    @Binding var text: String
    var placeholder: String = "사진 속 추억을 적어주세요"

    private var isPhotoPickable: Bool = false
    private var selectedPhotoData: ((Data?) -> Void)? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    
    private var isShowDeleteButton: Bool = false
    private var deleteButtonAction: (() -> Void)? = nil
    
    init(imageUrl: String? = nil, text: Binding<String>) {
        self.imageUrl = imageUrl
        self._text = text
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if isPhotoPickable {
                photoPickerView
            } else {
                imageView
            }
            
            PhotoTextField(text: $text, placeholder: placeholder)
                .frame(width: 280, height: 46)
        }
        .padding(16)
        .background(.gray200)
        .animation(.spring, value: imageUrl)
    }
}

// MARK: - Inner Functions

private extension PhotoElement {
    func compressImageData(_ data: Data?) async -> Data? {
        guard let data else { return nil }
        let uiImage = UIImage(data: data)
        let compressedImage = await uiImage?.compressTo(expectedSizeInMB: 1)
        let compressedData = try? compressedImage?.toData()
        return compressedData
    }
}

// MARK: - Inner Views

private extension PhotoElement {
    var photoPickerView: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            imageView
        }
        .onChange(of: selectedItem) { photoItem in
            Task {
                let loadedData = try? await photoItem?.loadTransferable(type: Data.self)
                let compressedData = await compressImageData(loadedData)
                selectedPhotoData?(compressedData)
            }
        }
    }
    
    var imageView: some View {
        KFImage(URL(string: imageUrl ?? ""))
            .placeholder {
                placeholderView
            }
            .scaleToFillFrame(width: 280, height: 280)
            .frame(width: 280, height: 280)
            .overlay(alignment: .topTrailing) {
                if isShowDeleteButton {
                    CloseButton(sizeType: .medium, colorType: .dark) {
                        selectedItem = nil
                        deleteButtonAction?()
                    }
                    .padding(12)
                }
            }
    }
    
    var placeholderView: some View {
        Color.white
            .overlay {
                Image(.photo)
            }
    }
}

private struct PhotoTextField: View {
    @Binding var text: String
    let placeholder: String
    
    @FocusState private var isFocused: Bool

    @Environment(\.isEnabled) var isEnabled

    var body: some View {
        TextField("", text: $text)
            .tint(.black)
            .packyFont(.body4)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .overlay {
                if isEnabled {
                    Text(placeholder)
                        .foregroundStyle(.gray500)
                        .font(.packy(.body5))
                        .animation(.spring, value: isFocused)
                        .animation(.spring, value: text.isEmpty)
                        .opacity(!isFocused && text.isEmpty ? 1 : 0)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - View Modifiers

extension PhotoElement {
    func photoPickable(selectedPhotoData: @escaping (Data?) -> Void) -> Self {
        var element = self
        element.isPhotoPickable = true
        element.selectedPhotoData = selectedPhotoData
        return element
    }
    
    func deleteButton(isShown: Bool, action: @escaping () -> Void) -> Self {
        var element = self
        element.isShowDeleteButton = isShown
        element.deleteButtonAction = action
        return element
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PhotoElement(
            imageUrl: nil,
            text: .constant("")
        )
        .photoPickable { data in
            print(data)
        }
        
        PhotoElement(
            imageUrl: Constants.mockImageUrl,
            text: .constant("asdada")
        )
        .deleteButton(isShown: true) {
            print("aaa")
        }
    }
}
