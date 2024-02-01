//
//  Photo.swift
//  Packy
//
//  Created by Mason Kim on 1/27/24.
//

import Foundation

struct Photo: Codable, Equatable {
    let photoUrl: String
    let description: String
    let sequence: Int
}

// MARK: - Mock Data

extension Photo {
    static var mock: Self {
        return .init(
            photoUrl: "https://picsum.photos/220",
            description: "우리 같이 놀러갔던 날 :)",
            sequence: 1
        )
    }
}
