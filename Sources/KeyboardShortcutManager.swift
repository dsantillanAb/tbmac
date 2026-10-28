import Cocoa
import Carbon

public final class KeyboardShortcutManager {
    public static let shared = KeyboardShortcutManager()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    private init() {}
    
    public func start() {
        stop()
        
        // 1. Global monitor: captures keystrokes when any other app (Terminal, Ghostty, Cursor, etc.) is active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        // 2. Local monitor: captures keystrokes if Codex Touch Bar itself is the active window
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // Consume event
            }
            return event
        }
        
        AppLog.log("⌨️ [ShortcutManager] Atajos activos: fn+8 (Yes), fn+9 (Always), fn+0 (No)")
    }
    
    public func stop() {
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
    }
    
    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags
        let keyCode = event.keyCode
        
        let isFn = flags.contains(.function)
        let isNoCmdCtrl = !flags.contains(.command) && !flags.contains(.control)
        
        guard isNoCmdCtrl else { return false }
        
        // fn + 8 or F8 (keyCode 100) -> YES
        if (isFn && keyCode == 28) || keyCode == 100 {
            guard TouchBarManager.shared.isWaitingForApproval else { return false }
            AppLog.log("⌨️ [Shortcut] Atajo fn+8 / F8 pulsado -> Aprobando 'Yes'")
            DispatchQueue.main.async {
                TouchBarManager.shared.approveYes()
            }
            return true
        }
        
        // fn + 9 or F9 (keyCode 101) -> ALWAYS
        if (isFn && keyCode == 25) || keyCode == 101 {
            guard TouchBarManager.shared.isWaitingForApproval else { return false }
            AppLog.log("⌨️ [Shortcut] Atajo fn+9 / F9 pulsado -> Aprobando 'Always'")
            DispatchQueue.main.async {
                TouchBarManager.shared.approveAlways()
            }
            return true
        }
        
        // fn + 0 or F10 (keyCode 109) -> NO
        if (isFn && keyCode == 29) || keyCode == 109 {
            guard TouchBarManager.shared.isWaitingForApproval else { return false }
            AppLog.log("⌨️ [Shortcut] Atajo fn+0 / F10 pulsado -> Rechazando 'No'")
            DispatchQueue.main.async {
                TouchBarManager.shared.approveNo()
            }
            return true
        }
        
        return false
    }
}
