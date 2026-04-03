import Foundation

// agents.json의 각 역할 정의
struct AgentDefinition: Codable {
    let model: String
    let description: String
    let prompt: String?
}

// agents.json 전체 = [역할명: 에이전트 정의]
typealias TeamConfiguration = [String: AgentDefinition]

// description에서 이름과 역할 설명 파싱
// 형식: "이름 — 설명" 또는 "이름 - 설명"
func parseAgentDescription(_ description: String) -> (name: String, roleDesc: String) {
    // em-dash(—) 또는 " - " 구분자 시도
    let separators = [" — ", " — ", " - ", "—"]
    for sep in separators {
        if let range = description.range(of: sep) {
            let name = String(description[description.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let desc = String(description[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return (name: name, roleDesc: desc)
            }
        }
    }
    // 구분자 없으면 description 전체를 이름으로 사용
    return (name: description, roleDesc: "")
}

// TeamConfiguration → [TeamAgent] 변환
func buildTeamAgents(from config: TeamConfiguration) -> [TeamAgent] {
    // 정렬: leader 먼저, 나머지 알파벳 순
    let sortedKeys = config.keys.sorted { a, b in
        if a == "leader" { return true }
        if b == "leader" { return false }
        return a < b
    }

    return sortedKeys.compactMap { role in
        guard let def = config[role] else { return nil }
        let parsed = parseAgentDescription(def.description)
        return TeamAgent(
            id: role,
            model: def.model,
            name: parsed.name,
            roleDescription: parsed.roleDesc,
            emoji: AgentRole.emoji(for: role)
        )
    }
}
