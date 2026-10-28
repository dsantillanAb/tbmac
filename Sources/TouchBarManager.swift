import AppKit

public protocol TouchBarManagerDelegate: AnyObject {
    func touchBarDidRequestCopy()
    func touchBarDidApprove(choice: String)
}

public final class TouchBarManager: NSObject, NSTouchBarDelegate {
    public static let shared = TouchBarManager()
    public weak var delegate: TouchBarManagerDelegate?
    
    // Identifiers
    private let trayIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.tray")
    private let closeItemIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.close")
    private let statusItemIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.status")
    private let tickerItemIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.ticker")
    private let tokensItemIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.tokens")
    private let copyItemIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.copy")
    
    // Approval Identifiers
    private let approvalYesIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.approval.yes")
    private let approvalAlwaysIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.approval.always")
    private let approvalNoIdentifier = NSTouchBarItem.Identifier("com.touchbarai.codex.approval.no")
    
    // Private DFR function types
    private typealias DFRElementSetControlStripPresenceFunc = @convention(c) (CFString, Bool) -> Void
    private typealias DFRSystemModalShowsCloseBoxFunc = @convention(c) (Bool) -> Void
    private typealias PresentModalPlacementFunc = @convention(c) (AnyClass, Selector, NSTouchBar, Int64, NSTouchBarItem.Identifier?) -> Void
    private typealias DismissModalFunc = @convention(c) (AnyClass, Selector, NSTouchBar) -> Void
    
    private var setControlStripPresence: DFRElementSetControlStripPresenceFunc?
    private var setShowsCloseBox: DFRSystemModalShowsCloseBoxFunc?
    private var isDFRAvailable = false
    
    // UI elements
    private var modalTouchBar: NSTouchBar?
    private var trayTouchBarItem: NSCustomTouchBarItem?
    private var trayButton: NSButton?
    
    private var statusButton: NSButton?
    private var tickerView: TouchTickerView?
    private var tokensButton: NSButton?
    private var copyButton: NSButton?
    
    // Approval buttons
    private var approvalYesButton: NSButton?
    private var approvalAlwaysButton: NSButton?
    private var approvalNoButton: NSButton?
    
    public var autoPresentOnActivity: Bool = true
    private var isModalPresented: Bool = false
    public private(set) var isWaitingForApproval: Bool = false
    
    private var spinTimer: Timer?
    private var spinAngle: Double = 0.0
    
    override init() {
        super.init()
        loadDFRFoundation()
        setupTouchBar()
        registerControlStripItem()
    }
    
    private func loadDFRFoundation() {
        let dfrPath = "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation"
        guard let handle = dlopen(dfrPath, RTLD_LAZY) else {
            print("Notice: DFRFoundation not loaded. Running in standard AppKit mode.")
            return
        }
        
        if let symPresence = dlsym(handle, "DFRElementSetControlStripPresenceForIdentifier") {
            setControlStripPresence = unsafeBitCast(symPresence, to: DFRElementSetControlStripPresenceFunc.self)
        }
        if let symClose = dlsym(handle, "DFRSystemModalShowsCloseBoxWhenFrontMost") {
            setShowsCloseBox = unsafeBitCast(symClose, to: DFRSystemModalShowsCloseBoxFunc.self)
            setShowsCloseBox?(true)
        }
        isDFRAvailable = true
    }
    
    private func setupTouchBar() {
        let tb = NSTouchBar()
        tb.delegate = self
        tb.defaultItemIdentifiers = [
            closeItemIdentifier,
            statusItemIdentifier,
            tickerItemIdentifier,
            tokensItemIdentifier,
            copyItemIdentifier
        ]
        self.modalTouchBar = tb
    }
    
    private func startSpinning(color: NSColor = .black) {
        stopSpinning()
        spinAngle = 0.0
        let initialIcon = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: color)
        statusButton?.image = initialIcon
        
        spinTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.spinAngle = (self.spinAngle + 20.0).truncatingRemainder(dividingBy: 360.0)
            let icon = LucideIcons.codexRotated(angleDegrees: self.spinAngle, size: NSSize(width: 16, height: 16), color: color)
            self.statusButton?.image = icon
        }
    }
    
    private func stopSpinning() {
        spinTimer?.invalidate()
        spinTimer = nil
    }
    
    private func registerControlStripItem() {
        guard isDFRAvailable else { return }
        
        let item = NSCustomTouchBarItem(identifier: trayIdentifier)
        let btn = NSButton(title: "Codex", target: self, action: #selector(toggleModalTouchBar))
        btn.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .white)
        btn.imagePosition = .imageLeading
        btn.bezelColor = NSColor.systemIndigo
        btn.bezelStyle = .rounded
        item.view = btn
        self.trayButton = btn
        self.trayTouchBarItem = item
        
        let itemClass = NSTouchBarItem.self as AnyObject
        let sel = Selector(("addSystemTrayItem:"))
        if itemClass.responds(to: sel) {
            _ = itemClass.perform(sel, with: item)
            setControlStripPresence?(trayIdentifier.rawValue as CFString, true)
        }
    }
    
    public func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case closeItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "", target: self, action: #selector(dismissTouchBar))
            btn.image = LucideIcons.x(size: NSSize(width: 15, height: 15))
            btn.imagePosition = .imageOnly
            btn.bezelStyle = .rounded
            item.view = btn
            return item
            
        case statusItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "Listo", target: self, action: #selector(toggleModalTouchBar))
            btn.image = LucideIcons.bot(size: NSSize(width: 16, height: 16))
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.bezelColor = NSColor.systemGray
            item.view = btn
            self.statusButton = btn
            return item
            
        case tickerItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let width: CGFloat = isWaitingForApproval ? 440 : 560
            let ticker = TouchTickerView(frame: NSRect(x: 0, y: 0, width: width, height: 30))
            ticker.text = "Codex listo. Esperando prompt..."
            item.view = ticker
            self.tickerView = ticker
            return item
            
        case tokensItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "0", target: nil, action: nil)
            btn.image = LucideIcons.activity(size: NSSize(width: 15, height: 15))
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.isEnabled = false
            item.view = btn
            self.tokensButton = btn
            return item
            
        case copyItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "Copiar", target: self, action: #selector(copyAction))
            btn.image = LucideIcons.copy(size: NSSize(width: 15, height: 15))
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            item.view = btn
            self.copyButton = btn
            return item
            
        case approvalYesIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "Yes", target: self, action: #selector(approveYesAction))
            btn.image = LucideIcons.check(size: NSSize(width: 15, height: 15), color: .white)
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.bezelColor = NSColor.systemGreen
            item.view = btn
            self.approvalYesButton = btn
            return item
            
        case approvalAlwaysIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "Always", target: self, action: #selector(approveAlwaysAction))
            btn.image = LucideIcons.checkCheck(size: NSSize(width: 15, height: 15), color: .white)
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.bezelColor = NSColor.systemIndigo
            item.view = btn
            self.approvalAlwaysButton = btn
            return item
            
        case approvalNoIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let btn = NSButton(title: "No", target: self, action: #selector(approveNoAction))
            btn.image = LucideIcons.x(size: NSSize(width: 14, height: 14), color: .white)
            btn.imagePosition = .imageLeading
            btn.bezelStyle = .rounded
            btn.bezelColor = NSColor.systemRed
            item.view = btn
            self.approvalNoButton = btn
            return item
            
        default:
            return nil
        }
    }
    
    @objc public func toggleModalTouchBar() {
        if isModalPresented {
            dismissTouchBar()
        } else {
            presentTouchBar()
        }
    }
    
    @objc public func presentTouchBar() {
        guard let tb = modalTouchBar else { return }
        
        let tbClass = NSTouchBar.self as AnyObject
        let selPlacement = Selector(("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:"))
        if tbClass.responds(to: selPlacement) {
            let method = class_getClassMethod(NSTouchBar.self, selPlacement)!
            let imp = method_getImplementation(method)
            let call = unsafeBitCast(imp, to: PresentModalPlacementFunc.self)
            call(NSTouchBar.self, selPlacement, tb, 1, trayIdentifier)
            isModalPresented = true
        } else {
            let selSimple = Selector(("presentSystemModalTouchBar:systemTrayItemIdentifier:"))
            if tbClass.responds(to: selSimple) {
                _ = tbClass.perform(selSimple, with: tb, with: trayIdentifier)
                isModalPresented = true
            }
        }
    }
    
    @objc public func dismissTouchBar() {
        guard let tb = modalTouchBar else { return }
        
        let tbClass = NSTouchBar.self as AnyObject
        let selDismiss = Selector(("dismissSystemModalTouchBar:"))
        if tbClass.responds(to: selDismiss) {
            let method = class_getClassMethod(NSTouchBar.self, selDismiss)!
            let imp = method_getImplementation(method)
            let call = unsafeBitCast(imp, to: DismissModalFunc.self)
            call(NSTouchBar.self, selDismiss, tb)
            isModalPresented = false
        }
    }
    
    @objc private func copyAction() {
        delegate?.touchBarDidRequestCopy()
        copyButton?.image = LucideIcons.check(size: NSSize(width: 15, height: 15), color: .systemGreen)
        copyButton?.title = "Copiado"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyButton?.image = LucideIcons.copy(size: NSSize(width: 15, height: 15))
            self?.copyButton?.title = "Copiar"
        }
    }
    
    // Approval actions: send keystroke to frontmost active app (Ghostty / Terminal / VS Code)
    public func approveYes() {
        guard isWaitingForApproval else { return }
        AppLog.log("🎯 [TouchBarManager] approveYes ejecutado desde Touch Bar")
        isWaitingForApproval = false
        delegate?.touchBarDidApprove(choice: "yes")
        approvalYesButton?.title = "✓ Aprobado"
        sendKeystroke(action: "yes")
    }
    
    public func approveAlways() {
        guard isWaitingForApproval else { return }
        AppLog.log("🎯 [TouchBarManager] approveAlways ejecutado desde Touch Bar")
        isWaitingForApproval = false
        delegate?.touchBarDidApprove(choice: "always")
        approvalAlwaysButton?.title = "✓ Siempre"
        sendKeystroke(action: "always")
    }
    
    public func approveNo() {
        guard isWaitingForApproval else { return }
        AppLog.log("🎯 [TouchBarManager] approveNo ejecutado desde Touch Bar")
        isWaitingForApproval = false
        delegate?.touchBarDidApprove(choice: "no")
        approvalNoButton?.title = "✕ Rechazado"
        sendKeystroke(action: "no")
    }
    
    @objc private func approveYesAction() {
        approveYes()
    }
    
    @objc private func approveAlwaysAction() {
        approveAlways()
    }
    
    @objc private func approveNoAction() {
        approveNo()
    }
    
    private func getTargetTerminalApp() -> NSRunningApplication? {
        let dedicatedTerminals = [
            "com.apple.Terminal",
            "com.googlecode.iterm2",
            "com.mitchellh.ghostty"
        ]
        
        // 1. If user is currently focused on any terminal, prioritize THAT active terminal!
        if let front = NSWorkspace.shared.frontmostApplication,
           let bid = front.bundleIdentifier,
           dedicatedTerminals.contains(bid) {
            AppLog.log("🎯 [Target] Terminal activo al frente: \(front.localizedName ?? "") (\(bid)) [PID \(front.processIdentifier)]")
            return front
        }
        
        // 2. Otherwise find which dedicated terminal is running
        for bid in dedicatedTerminals {
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first,
               !app.isTerminated {
                AppLog.log("🎯 [Target] Terminal en segundo plano detectado: \(app.localizedName ?? "") (\(bid)) [PID \(app.processIdentifier)]")
                return app
            }
        }
        
        let fallback = NSWorkspace.shared.frontmostApplication
        AppLog.log("🎯 [Target] Fallback a frontmost: \(fallback?.localizedName ?? "nil") (\(fallback?.bundleIdentifier ?? "nil"))")
        return fallback
    }
    
    private func sendKeystroke(action: String) {
        let targetApp = getTargetTerminalApp()
        let bundleId = targetApp?.bundleIdentifier ?? "com.apple.Terminal"
        let processName = targetApp?.localizedName ?? "Terminal"
        
        AppLog.log("🚀 [Keystroke] Preparando envío de acción '\(action)' a \(processName) (\(bundleId))")
        
        // 1. Activate the target terminal window
        let activateScript = """
        tell application id "\(bundleId)" to activate
        """
        NSAppleScript(source: activateScript)?.executeAndReturnError(nil)
        targetApp?.activate()
        
        // 2. Wait 200ms for window server focus transition
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.postActionKey(action, targetApp: targetApp)
        }
    }
    
    private func postActionKey(_ action: String, targetApp: NSRunningApplication?) {
        let src = CGEventSource(stateID: .combinedSessionState)
        
        func postKey(virtualKey: CGKeyCode, holdMicros: useconds_t = 40000) {
            let down = CGEvent(keyboardEventSource: src, virtualKey: virtualKey, keyDown: true)
            let up = CGEvent(keyboardEventSource: src, virtualKey: virtualKey, keyDown: false)
            down?.flags = []
            up?.flags = []
            down?.post(tap: .cghidEventTap)
            usleep(holdMicros)
            up?.post(tap: .cghidEventTap)
        }
        
        switch action {
        case "y", "yes":
            // Option 1 ('Yes, proceed') is already highlighted by default: sending Return (36) confirms it!
            AppLog.log("⌨️ [Keystroke] Inyectando Return (code 36) para confirmar opción 'Yes'...")
            postKey(virtualKey: 36, holdMicros: 45000)
            
        case "a", "always":
            // Option 2 ('Always'): send '2' (code 19) then Return
            AppLog.log("⌨️ [Keystroke] Inyectando selección '2' + Return para 'Always'...")
            postKey(virtualKey: 19, holdMicros: 35000) // key '2'
            usleep(100000)
            postKey(virtualKey: 36, holdMicros: 45000) // Return
            
        case "n", "no":
            // Option 3 ('No / cancel'): send Escape (code 53)
            AppLog.log("⌨️ [Keystroke] Inyectando Escape (code 53) para cancelar...")
            postKey(virtualKey: 53, holdMicros: 45000)
            
        default:
            postKey(virtualKey: 36, holdMicros: 45000)
        }
        
        AppLog.log("✅ [TouchBarManager] Acción '\(action)' inyectada con éxito a \(targetApp?.localizedName ?? "Terminal")")
    }
    
    // Switch Touch Bar items between Normal Mode and Approval Mode
    private func updateTouchBarLayout(isApproval: Bool) {
        guard let tb = modalTouchBar else { return }
        self.isWaitingForApproval = isApproval
        
        if isApproval {
            tb.defaultItemIdentifiers = [
                closeItemIdentifier,
                statusItemIdentifier,
                tickerItemIdentifier,
                approvalYesIdentifier,
                approvalAlwaysIdentifier,
                approvalNoIdentifier
            ]
        } else {
            tb.defaultItemIdentifiers = [
                closeItemIdentifier,
                statusItemIdentifier,
                tickerItemIdentifier,
                tokensItemIdentifier,
                copyItemIdentifier
            ]
        }
    }
    
    // Updates from Codex Monitor
    public func updateState(_ state: CodexActivityState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .waitingForApproval(let reason, let cmd, _):
                self.stopSpinning()
                self.updateTouchBarLayout(isApproval: true)
                self.statusButton?.title = "Autorizar"
                self.statusButton?.image = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .white)
                self.statusButton?.bezelColor = NSColor.systemOrange
                self.trayButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .systemOrange)
                
                // Show question / reason prominently, followed by the command!
                let displayText: String
                if !cmd.isEmpty && !reason.contains(cmd) {
                    displayText = "\(reason)  ➔ [cmd: \(cmd)]"
                } else {
                    displayText = reason
                }
                self.tickerView?.text = displayText
                
                // Reset approval button titles with shortcut indicators
                self.approvalYesButton?.title = "Yes (fn 8)"
                self.approvalAlwaysButton?.title = "Always (fn 9)"
                self.approvalNoButton?.title = "No (fn 0)"
                
                if self.autoPresentOnActivity && !self.isModalPresented {
                    self.presentTouchBar()
                }
                
            case .thinking:
                self.updateTouchBarLayout(isApproval: false)
                self.statusButton?.title = state.shortBadge
                self.statusButton?.bezelColor = NSColor.systemYellow
                self.trayButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .systemYellow)
                self.startSpinning(color: .black)
                if self.autoPresentOnActivity && !self.isModalPresented {
                    self.presentTouchBar()
                }
                
            case .speaking(let msg):
                self.stopSpinning()
                self.updateTouchBarLayout(isApproval: false)
                self.statusButton?.title = state.shortBadge
                self.statusButton?.image = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .systemTeal)
                self.statusButton?.bezelColor = NSColor.systemTeal
                self.trayButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .systemTeal)
                self.tickerView?.text = msg
                if self.autoPresentOnActivity && !self.isModalPresented {
                    self.presentTouchBar()
                }
                
            case .executing:
                self.stopSpinning()
                self.updateTouchBarLayout(isApproval: false)
                self.statusButton?.title = "Trabajando"
                self.statusButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .white)
                self.statusButton?.bezelColor = NSColor.systemIndigo
                self.trayButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17), color: .white)
                // DO NOT overwrite tickerView with internal command noise (like rg, Read, Search)
                // The Touch Bar keeps showing what Codex is saying / explaining!
                if self.autoPresentOnActivity && !self.isModalPresented {
                    self.presentTouchBar()
                }
                
            case .completed(let msg):
                self.stopSpinning()
                self.updateTouchBarLayout(isApproval: false)
                self.statusButton?.title = state.shortBadge
                self.statusButton?.image = LucideIcons.check(size: NSSize(width: 16, height: 16), color: .systemGreen)
                self.statusButton?.bezelColor = NSColor.systemGreen
                self.trayButton?.image = LucideIcons.check(size: NSSize(width: 17, height: 17), color: .systemGreen)
                if !msg.isEmpty {
                    self.tickerView?.text = msg
                }
                
            case .idle:
                self.stopSpinning()
                self.updateTouchBarLayout(isApproval: false)
                self.statusButton?.title = state.shortBadge
                self.statusButton?.image = LucideIcons.codex(size: NSSize(width: 16, height: 16))
                self.statusButton?.bezelColor = NSColor.systemGray
                self.trayButton?.image = LucideIcons.codex(size: NSSize(width: 17, height: 17))
            }
        }
    }
    
    public func updateMessage(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.tickerView?.text = text
            if self?.autoPresentOnActivity == true && self?.isModalPresented == false {
                self?.presentTouchBar()
            }
        }
    }
    
    public func updateTokens(_ count: Int) {
        DispatchQueue.main.async { [weak self] in
            let formatted: String
            if count > 1000 {
                formatted = String(format: "%.1fk", Double(count) / 1000.0)
            } else {
                formatted = "\(count)"
            }
            self?.tokensButton?.title = formatted
        }
    }
}
