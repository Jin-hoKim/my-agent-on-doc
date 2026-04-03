import Foundation

// 에이전트의 현재 상태 (기능 상태 + 감정 표현 상태)
enum AgentState: Equatable {
    // 기능 상태
    case idle           // 대기 중 (normal face)
    case thinking       // 사용자 프롬프트 처리 중 (loading face)
    case streaming      // SSE 스트리밍 응답 수신 중 (typing face)
    case responding     // 응답 완료 후 처리 중
    case error(String)  // 에러 발생 (error face)

    // 감정 표현 상태
    case voiceMode      // 음성 출력 중 (voice mode)
    case excited        // 흥분/기쁨 (excited face)
    case angry          // 분노/오류 (angry face)
    case winking        // 윙크/성공 (winking face)
    case surprised      // 놀람 (surprised face)
    case loading        // 로딩 중 (loading face - thinking과 구분)
    case pleased        // 만족/완료 (pleased face)
    case sad            // 슬픔/연결오류 (sad face)
    case laughing       // 웃음 (laughing face)
    case snoozing       // 졸음/장시간 대기 (snoozing face)
    case neutral        // 중립 (neutral face)
    case outOfService   // 서비스 불가 (out of service face)
    case lowBattery     // 한도 초과 (low battery face)
    case crazy          // 특이한 요청 (crazy face)
    case heartEyes      // 긍정 피드백 (heart face)
    case newMessage     // 새 메시지 수신 (new message face)
    case unknown        // 알 수 없는 상태 (unknown face)

    var isWorking: Bool {
        switch self {
        case .thinking, .streaming, .responding, .loading, .voiceMode: return true
        default: return false
        }
    }

    var statusText: String {
        switch self {
        // 기능 상태
        case .idle:             return "대기 중"
        case .thinking:         return "생각하는 중..."
        case .streaming:        return "답변 중..."
        case .responding:       return "응답 중..."
        case .error(let msg):   return "오류: \(msg)"
        // 감정 표현 상태
        case .voiceMode:        return "음성 출력 중..."
        case .excited:          return "와우!"
        case .angry:            return "오류 발생"
        case .winking:          return "완료!"
        case .surprised:        return "어머!"
        case .loading:          return "불러오는 중..."
        case .pleased:          return "답변 완료"
        case .sad:              return "연결 오류"
        case .laughing:         return "하하하!"
        case .snoozing:         return "쉬는 중..."
        case .neutral:          return "대기 중"
        case .outOfService:     return "서비스 불가"
        case .lowBattery:       return "한도 초과"
        case .crazy:            return "특이한 요청!"
        case .heartEyes:        return "좋아요!"
        case .newMessage:       return "새 메시지"
        case .unknown:          return "알 수 없음"
        }
    }

    // 감정 표현 상태는 자동으로 idle로 복귀 (초)
    var autoRevertDelay: Double? {
        switch self {
        case .excited:      return 2.0
        case .winking:      return 1.5
        case .surprised:    return 2.0
        case .pleased:      return 2.0
        case .laughing:     return 2.0
        case .angry:        return 3.0
        case .sad:          return 3.0
        case .heartEyes:    return 2.0
        case .newMessage:   return 0.8
        case .crazy:        return 2.0
        default:            return nil
        }
    }
}
