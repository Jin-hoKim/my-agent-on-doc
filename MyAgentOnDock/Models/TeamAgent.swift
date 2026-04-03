import Foundation

// 팀 에이전트 개별 정보
struct TeamAgent: Identifiable, Codable {
    let id: String          // 역할명 (agents.json key)
    let model: String       // opus/sonnet/haiku
    let name: String        // description에서 추출한 이름
    let roleDescription: String // — 뒤의 역할 설명
    let emoji: String       // 역할별 매핑 이모지
    var isActive: Bool = false
    var pid: String? = nil

    // 모델 약어 표시
    var modelBadge: String {
        switch model.lowercased() {
        case let m where m.contains("opus"): return "O"
        case let m where m.contains("sonnet"): return "S"
        case let m where m.contains("haiku"): return "H"
        default: return model.prefix(1).uppercased()
        }
    }
}
