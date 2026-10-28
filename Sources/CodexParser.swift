import Foundation

public enum CodexActivityState: Equatable {
    case idle
    case thinking(String)
    case speaking(String)
    case executing(String)
    case waitingForApproval(reason: String, command: String, options: [String])
    case completed(String)
    
    public var title: String {
        switch self {
        case .idle:
            return "Inactivo"
        case .thinking(let detail):
            return "Pensando: \(detail.isEmpty ? "Razonando..." : detail)"
        case .speaking:
            return "Codex dice"
        case .executing(let cmd):
            return "Trabajando: \(cmd)"
        case .waitingForApproval(let reason, let cmd, _):
            return "Requiere aprobación: \(reason.isEmpty ? cmd : reason)"
        case .completed:
            return "Completado"
        }
    }
    
    public var shortBadge: String {
        switch self {
        case .idle:
            return "Listo"
        case .thinking:
            return "Pensando"
        case .speaking:
            return "Respondiendo"
        case .executing:
            return "Trabajando"
        case .waitingForApproval:
            return "Autorizar"
        case .completed:
            return "Listo"
        }
    }
    
    public var iconName: String {
        switch self {
        case .idle:
            return "bot"
        case .thinking:
            return "brain"
        case .speaking:
            return "messageSquare"
        case .executing:
            return "terminal"
        case .waitingForApproval:
            return "shieldAlert"
        case .completed:
            return "check"
        }
    }
}

public struct ParsedCodexEvent {
    public let state: CodexActivityState?
    public let messageText: String?
    public let userPrompt: String?
    public let toolAction: String?
    public let tokens: Int?
    public let isToolOutput: Bool
    public let timestamp: Date?
}

public final class CodexParser {
    public init() {}
    
    private func cleanXmlContext(_ raw: String) -> String {
        var s = raw
        // Remove blocks like <environment_context>...</environment_context>
        let blockPattern = "<([a-zA-Z0-9_-]+)>[\\s\\S]*?</\\1>"
        if let regex = try? NSRegularExpression(pattern: blockPattern, options: []) {
            s = regex.stringByReplacingMatches(in: s, options: [], range: NSRange(location: 0, length: (s as NSString).length), withTemplate: "")
        }
        // Remove individual tags
        let tagPattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: []) {
            s = regex.stringByReplacingMatches(in: s, options: [], range: NSRange(location: 0, length: (s as NSString).length), withTemplate: "")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func parseLine(_ line: String) -> ParsedCodexEvent? {
        guard !line.isEmpty, let data = line.data(using: .utf8) else { return nil }
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        
        let type = json["type"] as? String ?? ""
        let payload = json["payload"] as? [String: Any] ?? [:]
        let payloadType = payload["type"] as? String ?? ""
        
        var state: CodexActivityState? = nil
        var messageText: String? = nil
        var userPrompt: String? = nil
        var toolAction: String? = nil
        var tokens: Int? = nil
        var isToolOutput = false
        
        if type == "response_item" {
            switch payloadType {
            case "message":
                let role = payload["role"] as? String ?? ""
                if role == "assistant" {
                    if let contents = payload["content"] as? [[String: Any]] {
                        var combined = ""
                        for item in contents {
                            if let text = item["text"] as? String {
                                combined += text
                            }
                        }
                        let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            messageText = trimmed
                            state = .speaking(trimmed)
                        }
                    }
                } else if role == "user" {
                    if let contents = payload["content"] as? [[String: Any]] {
                        var combined = ""
                        for item in contents {
                            if let text = item["text"] as? String {
                                combined += text
                            }
                        }
                        let cleaned = cleanXmlContext(combined)
                        if !cleaned.isEmpty {
                            userPrompt = cleaned
                        }
                    }
                }
            case "custom_tool_call", "function_call":
                let name = payload["name"] as? String ?? "herramienta"
                var cmdDetail = name
                var justificationText: String? = nil
                var requiresEscalated = false
                
                if let input = payload["input"] as? String {
                    // Extract justification / reason
                    if let justRange = input.range(of: "justification:\"") {
                        let sub = input[justRange.upperBound...]
                        if let endQuote = sub.firstIndex(of: "\"") {
                            justificationText = String(sub[..<endQuote])
                        }
                    } else if let reasonRange = input.range(of: "reason:\"") {
                        let sub = input[reasonRange.upperBound...]
                        if let endQuote = sub.firstIndex(of: "\"") {
                            justificationText = String(sub[..<endQuote])
                        }
                    } else if let qRange = input.range(of: "question:\"") {
                        let sub = input[qRange.upperBound...]
                        if let endQuote = sub.firstIndex(of: "\"") {
                            justificationText = String(sub[..<endQuote])
                        }
                    }
                    
                    if input.contains("require_escalated") || input.contains("sandbox_permissions") {
                        requiresEscalated = true
                    }
                    
                    if let cmdRange = input.range(of: "cmd:\"") {
                        let sub = input[cmdRange.upperBound...]
                        if let endQuote = sub.firstIndex(of: "\"") {
                            cmdDetail = String(sub[..<endQuote])
                        }
                    } else if input.count < 80 {
                        cmdDetail = input
                    }
                } else if let args = payload["arguments"] as? String {
                    cmdDetail = "\(name): \(args)"
                }
                
                toolAction = cmdDetail
                
                // Only trigger approval if there is an explicit question/justification or escalated permission
                if let justification = justificationText, !justification.isEmpty {
                    state = .waitingForApproval(reason: justification, command: cmdDetail, options: ["Yes", "Always", "No"])
                } else if requiresEscalated {
                    state = .waitingForApproval(reason: "¿Autorizar ejecución en terminal?", command: cmdDetail, options: ["Yes", "Always", "No"])
                } else {
                    // Regular tool call (read, search, edit)
                    state = .executing(cmdDetail)
                }
                
            case "custom_tool_call_output", "function_call_output":
                isToolOutput = true
                
            case "reasoning":
                state = .thinking("Analizando...")
            default:
                break
            }
        } else if type == "event_msg" {
            switch payloadType {
            case "task_started":
                state = .thinking("Iniciando tarea...")
            case "task_complete":
                state = .completed("Listo")
            case "token_count":
                if let info = payload["info"] as? [String: Any],
                   let totalUsage = info["total_token_usage"] as? [String: Any],
                   let total = totalUsage["total_tokens"] as? Int {
                    tokens = total
                }
            case "item_completed":
                isToolOutput = true
            default:
                break
            }
        }
        
        return ParsedCodexEvent(
            state: state,
            messageText: messageText,
            userPrompt: userPrompt,
            toolAction: toolAction,
            tokens: tokens,
            isToolOutput: isToolOutput,
            timestamp: Date()
        )
    }
}
