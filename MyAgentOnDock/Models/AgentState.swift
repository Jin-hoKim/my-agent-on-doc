import Foundation

// 에이전트의 현재 상태
enum AgentState: Equatable {
    case idle           // 대기 중
    case thinking       // 사용자 프롬프트 처리 중
    case streaming      // SSE 스트리밍 응답 수신 중
    case responding     // 응답 완료 후 처리 중
    case error(String)  // 에러 발생

    var isWorking: Bool {
        switch self {
        case .thinking, .streaming, .responding: return true
        default: return false
        }
    }

    var statusText: String {
        switch self {
        case .idle: return "대기 중"
        case .thinking: return "생각하는 중..."
        case .streaming: return "답변 중..."
        case .responding: return "응답 중..."
        case .error(let msg): return "오류: \(msg)"
        }
    }
}
