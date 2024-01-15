//
//  AuthEndpoint.swift
//  Packy
//
//  Created by Mason Kim on 1/15/24.
//

import Foundation
import Moya

enum AuthEndpoint {
    /// 회원가입
    case signUp(authorization: String, request: SignUpRequest)
    /// 로그인
    case signIn(request: SignInRequest)
    /// 회원 탈퇴
    case withdraw
    /// 토큰 재발급
    case reissueToken(request: TokenRequest)
}

extension AuthEndpoint: TargetType {
    var baseURL: URL {
        return URL(string: "http://packy-dev.ap-northeast-2.elasticbeanstalk.com/api/v1/")!
    }
    
    var path: String {
        switch self {
        case .signUp:          
            return "auth/sign-up"
        case .reissueToken:          
            return "auth/reissue"
        case .signIn(let request):
            return "auth/sign-in/\(request.provider)"
        case .withdraw:
            return "auth/withdraw"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .signUp, .reissueToken, .withdraw:  
            return .post
        case .signIn:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .signUp(_, request):
            return .requestJSONEncodable(request)
        case let .reissueToken(request):
            return .requestJSONEncodable(request)
        case .signIn, .withdraw:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case let .signUp(authorization, _):
            return ["Authorization": authorization]
        case let .signIn(request):
            return ["Authorization": request.authorization]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
