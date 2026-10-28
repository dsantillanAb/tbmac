import Foundation

public protocol CodexSessionMonitorDelegate: AnyObject {
    func codexMonitor(_ monitor: CodexSessionMonitor, didChangeState state: CodexActivityState)
    func codexMonitor(_ monitor: CodexSessionMonitor, didReceiveMessage message: String)
    func codexMonitor(_ monitor: CodexSessionMonitor, didExecuteTool action: String)
    func codexMonitor(_ monitor: CodexSessionMonitor, didUpdateTokens count: Int)
}

public final class CodexSessionMonitor {
    public weak var delegate: CodexSessionMonitorDelegate?
    
    private let parser = CodexParser()
    private var currentFilePath: String?
    private var fileOffset: UInt64 = 0
    private var pollTimer: Timer?
    private let fileManager = FileManager.default
    
    public private(set) var currentState: CodexActivityState = .idle
    public private(set) var lastUserPrompt: String = ""
    public private(set) var lastAssistantMessage: String = ""
    public private(set) var lastMessage: String = "Codex listo. Esperando prompt..."
    public private(set) var lastToolAction: String = "Ninguna"
    public private(set) var totalTokens: Int = 0
    
    private let baseSessionsPath: String
    
    public init(sessionsDirectory: String? = nil) {
        if let customDir = sessionsDirectory {
            self.baseSessionsPath = customDir
        } else {
            let home = fileManager.homeDirectoryForCurrentUser.path
            self.baseSessionsPath = (home as NSString).appendingPathComponent(".codex/sessions")
        }
    }
    
    public func start() {
        scanLatestFile()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.checkUpdates()
        }
    }
    
    public func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    private func findLatestRollout() -> String? {
        guard fileManager.fileExists(atPath: baseSessionsPath) else { return nil }
        
        let url = URL(fileURLWithPath: baseSessionsPath)
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        
        var latestDate: Date = .distantPast
        var latestPath: String? = nil
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "jsonl" else { continue }
            if let attrs = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
               attrs.isRegularFile == true,
               let modDate = attrs.contentModificationDate {
                if modDate > latestDate {
                    latestDate = modDate
                    latestPath = fileURL.path
                }
            }
        }
        
        return latestPath
    }
    
    private func scanLatestFile() {
        guard let latest = findLatestRollout() else { return }
        if currentFilePath != latest {
            currentFilePath = latest
            fileOffset = 0
            readPendingLines(isInitialScan: true)
        }
    }
    
    private func checkUpdates() {
        guard let latest = findLatestRollout() else { return }
        
        if currentFilePath != latest {
            currentFilePath = latest
            fileOffset = 0
            readPendingLines(isInitialScan: false)
            return
        }
        
        guard let attrs = try? fileManager.attributesOfItem(atPath: latest),
              let fileSize = attrs[.size] as? UInt64 else { return }
        
        if fileSize > fileOffset {
            readPendingLines(isInitialScan: false)
        }
    }
    
    private func readPendingLines(isInitialScan: Bool) {
        guard let path = currentFilePath else { return }
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? fileHandle.close() }
        
        do {
            try fileHandle.seek(toOffset: fileOffset)
            let data = fileHandle.readDataToEndOfFile()
            fileOffset += UInt64(data.count)
            
            guard let content = String(data: data, encoding: .utf8), !content.isEmpty else { return }
            
            let lines = content.components(separatedBy: "\n")
            for line in lines {
                guard !line.isEmpty else { continue }
                if let event = parser.parseLine(line) {
                    processEvent(event, isInitialScan: isInitialScan)
                }
            }
        } catch {
            // Silently handle
        }
    }
    
    private func processEvent(_ event: ParsedCodexEvent, isInitialScan: Bool) {
        if event.isToolOutput {
            if case .waitingForApproval = currentState {
                currentState = .executing(lastToolAction)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.codexMonitor(self, didChangeState: self.currentState)
                }
            }
        }
        
        // 1. User Prompt
        if let userText = event.userPrompt {
            lastUserPrompt = userText
            // If Codex has not responded yet in this turn, show what the user asked
            let displayPrompt = "Tú: \(userText)"
            lastMessage = displayPrompt
            if !isInitialScan {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.codexMonitor(self, didReceiveMessage: displayPrompt)
                }
            }
        }
        
        // 2. Assistant Speech / Commentary (HIGHEST PRIORITY FOR TICKER)
        if let speech = event.messageText {
            lastAssistantMessage = speech
            lastMessage = speech
            if !isInitialScan {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.codexMonitor(self, didReceiveMessage: speech)
                }
            }
        }
        
        // 3. Tool Action (Sent to menu bar, but DOES NOT overwrite the speech in the Touch Bar ticker!)
        if let action = event.toolAction {
            lastToolAction = action
            if !isInitialScan {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.codexMonitor(self, didExecuteTool: action)
                }
            }
        }
        
        // 4. Tokens
        if let tokens = event.tokens {
            totalTokens = tokens
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.codexMonitor(self, didUpdateTokens: tokens)
            }
        }
        
        // 5. State update
        if let state = event.state {
            currentState = state
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.codexMonitor(self, didChangeState: state)
            }
        }
    }
    
    // Exact simulation flow matching user's real-world scenario
    public func simulateActivity(step: Int) {
        switch step {
        case 1:
            // User prompt arrives
            let prompt = "Tú: vamos renovar el dashboard porque se ve muy simple y genérico, vamos a quitar cuentas bancarias y últimas facturas, vamos a poner renovaciones y asistencia diaria..."
            lastUserPrompt = prompt
            lastMessage = prompt
            currentState = .thinking("Analizando solicitud de renovación del dashboard...")
            delegate?.codexMonitor(self, didChangeState: currentState)
            delegate?.codexMonitor(self, didReceiveMessage: prompt)
            
        case 2:
            // Codex assistant speaks its plan
            let speech = "Voy a revisar el dashboard actual y las fuentes de datos de renovaciones y asistencia. Luego rediseñaré la pantalla para enfocarla en métricas operativas y quitaré las secciones de cuentas bancarias y últimas facturas."
            lastAssistantMessage = speech
            lastMessage = speech
            currentState = .speaking(speech)
            delegate?.codexMonitor(self, didReceiveMessage: speech)
            delegate?.codexMonitor(self, didChangeState: currentState)
            
        case 3:
            // Codex is executing tools in background: reading files, searching code
            // NOTICE: The speech remains on the Touch Bar! It is NOT replaced by "Read dashboard.ejs"
            lastToolAction = "Search app.get('/admin|render('dashboard') in server.js"
            currentState = .executing(lastToolAction)
            delegate?.codexMonitor(self, didExecuteTool: lastToolAction)
            delegate?.codexMonitor(self, didChangeState: currentState)
            
        case 4:
            // Optional approval prompt if escalated permissions needed
            let question = "¿Me permites recargar el servidor en el puerto 3005 para aplicar la nueva vista del dashboard?"
            let cmd = "lsof -nP -iTCP:3005 -sTCP:LISTEN"
            currentState = .waitingForApproval(reason: question, command: cmd, options: ["Yes", "Always", "No"])
            delegate?.codexMonitor(self, didChangeState: currentState)
            
        case 5:
            // Final summary of changes
            let finalMsg = "Dashboard actualizado: quitadas las cuentas bancarias y facturas. Añadidas métricas de renovaciones y asistencia diaria."
            lastMessage = finalMsg
            totalTokens += 530
            delegate?.codexMonitor(self, didUpdateTokens: totalTokens)
            currentState = .completed(finalMsg)
            delegate?.codexMonitor(self, didReceiveMessage: finalMsg)
            delegate?.codexMonitor(self, didChangeState: currentState)
            
        default:
            currentState = .idle
            delegate?.codexMonitor(self, didChangeState: currentState)
        }
    }
}
