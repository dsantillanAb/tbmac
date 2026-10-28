import AppKit

public protocol MenuBarControllerDelegate: AnyObject {
    func menuBarDidToggleTouchBar()
    func menuBarDidRequestSimulation()
    func menuBarDidRequestCopyLastMessage()
}

public final class MenuBarController: NSObject {
    public weak var delegate: MenuBarControllerDelegate?
    
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var lastMessageMenuItem: NSMenuItem!
    private var toolActionMenuItem: NSMenuItem!
    private var tokensMenuItem: NSMenuItem!
    private var autoShowMenuItem: NSMenuItem!
    
    private var lastMessageFull: String = ""
    
    public override init() {
        super.init()
        setupMenu()
    }
    
    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = LucideIcons.codex(size: NSSize(width: 17, height: 17))
            button.title = ""
            button.imagePosition = .imageOnly
        }
        
        let menu = NSMenu()
        
        // Header
        let titleItem = NSMenuItem(title: "Codex Touch Bar", action: nil, keyEquivalent: "")
        titleItem.image = LucideIcons.codex(size: NSSize(width: 15, height: 15))
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Status indicators
        statusMenuItem = NSMenuItem(title: "Estado: Inactivo", action: nil, keyEquivalent: "")
        statusMenuItem.image = LucideIcons.codex(size: NSSize(width: 15, height: 15))
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        
        toolActionMenuItem = NSMenuItem(title: "Acción: Ninguna", action: nil, keyEquivalent: "")
        toolActionMenuItem.image = LucideIcons.terminal(size: NSSize(width: 15, height: 15))
        toolActionMenuItem.isEnabled = false
        menu.addItem(toolActionMenuItem)
        
        tokensMenuItem = NSMenuItem(title: "Tokens: 0", action: nil, keyEquivalent: "")
        tokensMenuItem.image = LucideIcons.activity(size: NSSize(width: 15, height: 15))
        tokensMenuItem.isEnabled = false
        menu.addItem(tokensMenuItem)
        
        // Last message with submenu
        lastMessageMenuItem = NSMenuItem(title: "Último mensaje de Codex...", action: nil, keyEquivalent: "")
        lastMessageMenuItem.image = LucideIcons.messageSquare(size: NSSize(width: 15, height: 15))
        let sub = NSMenu()
        let copySub = NSMenuItem(title: "Copiar mensaje completo", action: #selector(copyLastMessage), keyEquivalent: "c")
        copySub.image = LucideIcons.copy(size: NSSize(width: 14, height: 14))
        copySub.target = self
        sub.addItem(copySub)
        lastMessageMenuItem.submenu = sub
        menu.addItem(lastMessageMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Controls
        let showTB = NSMenuItem(title: "Mostrar Touch Bar", action: #selector(showTouchBarAction), keyEquivalent: "t")
        showTB.image = LucideIcons.sparkles(size: NSSize(width: 14, height: 14))
        showTB.target = self
        menu.addItem(showTB)
        
        let hideTB = NSMenuItem(title: "Ocultar Touch Bar", action: #selector(hideTouchBarAction), keyEquivalent: "")
        hideTB.image = LucideIcons.x(size: NSSize(width: 14, height: 14))
        hideTB.target = self
        menu.addItem(hideTB)
        
        autoShowMenuItem = NSMenuItem(title: "Auto-mostrar al trabajar", action: #selector(toggleAutoShow), keyEquivalent: "")
        autoShowMenuItem.image = LucideIcons.check(size: NSSize(width: 14, height: 14))
        autoShowMenuItem.target = self
        autoShowMenuItem.state = .on
        menu.addItem(autoShowMenuItem)
        
        let shortcutsInfo = NSMenuItem(title: "Atajos: fn+8 (Yes) • fn+9 (Always) • fn+0 (No)", action: nil, keyEquivalent: "")
        shortcutsInfo.isEnabled = false
        menu.addItem(shortcutsInfo)
        
        menu.addItem(NSMenuItem.separator())
        
        // Demo & Utilities
        let simItem = NSMenuItem(title: "Probar simulación (Demo)", action: #selector(runSimulation), keyEquivalent: "s")
        simItem.image = LucideIcons.play(size: NSSize(width: 14, height: 14))
        simItem.target = self
        menu.addItem(simItem)
        
        let openSessions = NSMenuItem(title: "Abrir carpeta de sesiones Codex", action: #selector(openSessionsFolder), keyEquivalent: "")
        openSessions.image = LucideIcons.folder(size: NSSize(width: 14, height: 14))
        openSessions.target = self
        menu.addItem(openSessions)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Salir de Codex Touch Bar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func showTouchBarAction() {
        TouchBarManager.shared.presentTouchBar()
    }
    
    @objc private func hideTouchBarAction() {
        TouchBarManager.shared.dismissTouchBar()
    }
    
    @objc private func toggleAutoShow() {
        let newState = (autoShowMenuItem.state == .on) ? NSControl.StateValue.off : NSControl.StateValue.on
        autoShowMenuItem.state = newState
        TouchBarManager.shared.autoPresentOnActivity = (newState == .on)
    }
    
    @objc private func runSimulation() {
        delegate?.menuBarDidRequestSimulation()
    }
    
    @objc private func copyLastMessage() {
        delegate?.menuBarDidRequestCopyLastMessage()
    }
    
    @objc private func openSessionsFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let sessionsDir = (home as NSString).appendingPathComponent(".codex/sessions")
        NSWorkspace.shared.open(URL(fileURLWithPath: sessionsDir))
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    public func updateState(_ state: CodexActivityState) {
        statusMenuItem.title = "Estado: \(state.title)"
        let icon: NSImage
        switch state {
        case .idle:
            icon = LucideIcons.codex(size: NSSize(width: 16, height: 16))
        case .thinking:
            icon = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .systemYellow)
        case .speaking:
            icon = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .systemTeal)
        case .executing:
            icon = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .systemIndigo)
        case .waitingForApproval:
            icon = LucideIcons.codex(size: NSSize(width: 16, height: 16), color: .systemOrange)
        case .completed:
            icon = LucideIcons.check(size: NSSize(width: 16, height: 16), color: .systemGreen)
        }
        statusMenuItem.image = icon
        if let button = statusItem.button {
            button.image = icon
        }
    }
    
    public func updateLastMessage(_ text: String) {
        lastMessageFull = text
        let preview = text.replacingOccurrences(of: "\n", with: " ")
        if preview.count > 40 {
            lastMessageMenuItem.title = String(preview.prefix(37)) + "..."
        } else {
            lastMessageMenuItem.title = preview
        }
    }
    
    public func updateToolAction(_ action: String) {
        toolActionMenuItem.title = "Acción: \(action)"
    }
    
    public func updateTokens(_ count: Int) {
        if count > 1000 {
            tokensMenuItem.title = String(format: "Tokens: %.1fk", Double(count) / 1000.0)
        } else {
            tokensMenuItem.title = "Tokens: \(count)"
        }
    }
}
