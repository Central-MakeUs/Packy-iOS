//
//  AppConstants.swift
//  Packy
//
//  Created by Mason Kim on 2/4/24.
//

import Foundation

enum Constants {
    static var serverUrl {

    }
    
    static let devServerUrl = URL(string: "https://dev.packyforyou.shop/api/v1/")!
    static let releaseServerUrl = URL(string: "https://prod.packyforyou.shop/")!

    static var mockImageUrl: String { "https://picsum.photos/\(Int.random(in: 150...250))" }

    static var appVersion: String {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary,
              let currentVersion: String = infoDictionary["CFBundleShortVersionString"] as? String else {
            return "버전 정보를 불러올 수 없습니다."
        }
        return currentVersion
    }

    static let makeBoxAnimationDuration: TimeInterval = 4.5
    static let openBoxAnimationDuration: TimeInterval = 2.3
    static let textInteractionDuration: TimeInterval = 2
}
