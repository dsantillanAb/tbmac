import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate, CodexSessionMonitorDelegate, TouchBarManagerDelegate, MenuBarControllerDelegate {
    private var monitor: CodexSessionMonitor!
    private var touchBarManager: TouchBarManager!
    private var menuBarController: MenuBarController!
    
    private var simulationWorkItems: [DispatchWorkItem] = []
    private var isSimulating: Bool = false
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        touchBarManager = TouchBarManager.shared
        touchBarManager.delegate = self
        
        menuBarController = MenuBarController()
        menuBarController.delegate = self
        
        monitor = CodexSessionMonitor()
        monitor.delegate = self
        monitor.start()
        
        touchBarManager.updateMessage(monitor.lastMessage)
        menuBarController.updateLastMessage(monitor.lastMessage)
        
        KeyboardShortcutManager.shared.start()
        
        print("Codex Touch Bar Companion launched successfully!")
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        KeyboardShortcutManager.shared.stop()
        monitor?.stop()
        touchBarManager?.dismissTouchBar()
    }
    
    // MARK: - CodexSessionMonitorDelegate
    public func codexMonitor(_ monitor: CodexSessionMonitor, didChangeState state: CodexActivityState) {
        touchBarManager.updateState(state)
        menuBarController.updateState(state)
    }
    
    public func codexMonitor(_ monitor: CodexSessionMonitor, didReceiveMessage message: String) {
        touchBarManager.updateMessage(message)
        menuBarController.updateLastMessage(message)
    }
    
    public func codexMonitor(_ monitor: CodexSessionMonitor, didExecuteTool action: String) {
        menuBarController.updateToolAction(action)
    }
    
    public func codexMonitor(_ monitor: CodexSessionMonitor, didUpdateTokens count: Int) {
        touchBarManager.updateTokens(count)
        menuBarController.updateTokens(count)
    }
    
    // MARK: - TouchBarManagerDelegate
    public func touchBarDidRequestCopy() {
        copyTextToClipboard(monitor.lastMessage)
    }
    
    public func touchBarDidApprove(choice: String) {
        print("Approval response sent: \(choice)")
        
        // If simulation was running, immediately proceed!
        if isSimulating {
            simulationWorkItems.forEach { $0.cancel() }
            simulationWorkItems.removeAll()
            
            if choice.contains("no") {
                monitor.simulateActivity(step: 0)
                isSimulating = false
            } else {
                // Immediately advance to Step 5 (Completed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.monitor.simulateActivity(step: 5)
                }
                let resetItem = DispatchWorkItem { [weak self] in
                    self?.monitor.simulateActivity(step: 0)
                    self?.isSimulating = false
                }
                simulationWorkItems.append(resetItem)
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: resetItem)
            }
        }
    }
    
    // MARK: - MenuBarControllerDelegate
    public func menuBarDidToggleTouchBar() {
        touchBarManager.toggleModalTouchBar()
    }
    
    public func menuBarDidRequestSimulation() {
        print("Starting Codex simulation with Dashboard renewal flow...")
        isSimulating = true
        simulationWorkItems.forEach { $0.cancel() }
        simulationWorkItems.removeAll()
        touchBarManager.presentTouchBar()
        
        // Step 1: User prompt arrives
        monitor.simulateActivity(step: 1)
        
        let item2 = DispatchWorkItem { [weak self] in self?.monitor.simulateActivity(step: 2) }
        let item3 = DispatchWorkItem { [weak self] in self?.monitor.simulateActivity(step: 3) }
        let item4 = DispatchWorkItem { [weak self] in self?.monitor.simulateActivity(step: 4) }
        let item5 = DispatchWorkItem { [weak self] in self?.monitor.simulateActivity(step: 5) }
        let item0 = DispatchWorkItem { [weak self] in
            self?.monitor.simulateActivity(step: 0)
            self?.isSimulating = false
        }
        
        simulationWorkItems = [item2, item3, item4, item5, item0]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: item2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: item3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.5, execute: item4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 25.0, execute: item5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 31.0, execute: item0)
    }
    
    public func menuBarDidRequestCopyLastMessage() {
        copyTextToClipboard(monitor.lastMessage)
    }
    
    private func copyTextToClipboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
