import Foundation

struct LoginRequest: Encodable {
    let token: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let tokenType: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}
