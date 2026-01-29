import Foundation

struct Tag: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let slug: String
    let category: String?
}
