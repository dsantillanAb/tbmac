import AppKit

public final class TouchTickerView: NSView {
    public var text: String = "Codex listo" {
        didSet {
            updateTextMetrics()
        }
    }
    
    public var textColor: NSColor = .white {
        didSet { needsDisplay = true }
    }
    
    private var textOffset: CGFloat = 0
    private var totalTextWidth: CGFloat = 0
    private var scrollTimer: Timer?
    private var isUserDragging: Bool = false
    private var isPaused: Bool = false
    private var pauseCooldown: Int = 20 // frames to pause before starting scroll
    private var currentPauseCount: Int = 0
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor(white: 0.14, alpha: 0.95).cgColor
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor(white: 0.28, alpha: 0.6).cgColor
        
        startTicker()
    }
    
    deinit {
        scrollTimer?.invalidate()
    }
    
    private func startTicker() {
        scrollTimer?.invalidate()
        // Run ticker at ~30 FPS for smooth rendering with almost 0 CPU
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func updateTextMetrics() {
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attrs)
        totalTextWidth = size.width
        textOffset = 0
        currentPauseCount = 0
        needsDisplay = true
    }
    
    private func tick() {
        guard !isUserDragging, !isPaused else { return }
        let availableWidth = bounds.width - 20
        guard totalTextWidth > availableWidth else {
            // Text fits inside, no need to scroll
            if textOffset != 0 {
                textOffset = 0
                needsDisplay = true
            }
            return
        }
        
        if currentPauseCount < pauseCooldown {
            currentPauseCount += 1
            return
        }
        
        // Scroll left by 1.2 points
        textOffset -= 1.2
        
        // Loop back when text has scrolled completely out of view
        if -textOffset > totalTextWidth + 40 {
            textOffset = 20
            currentPauseCount = 0
        }
        
        needsDisplay = true
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let font = NSFont.systemFont(ofSize: 13, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let yPos = (bounds.height - 17) / 2
        let drawX = 10 + textOffset
        
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        attrStr.draw(at: NSPoint(x: drawX, y: yPos))
    }
    
    // Direct Touch Bar Finger Gestures!
    public override func touchesBegan(with event: NSEvent) {
        isUserDragging = true
    }
    
    public override func touchesMoved(with event: NSEvent) {
        let touches = event.touches(matching: .moved, in: self)
        if let touch = touches.first {
            let prev = touch.previousLocation(in: self)
            let curr = touch.location(in: self)
            let delta = curr.x - prev.x
            textOffset += delta
            needsDisplay = true
        }
    }
    
    public override func touchesEnded(with event: NSEvent) {
        isUserDragging = false
    }
    
    public override func touchesCancelled(with event: NSEvent) {
        isUserDragging = false
    }
    
    public override func mouseDown(with event: NSEvent) {
        // Toggle pause on tap
        isPaused.toggle()
        if !isPaused {
            needsDisplay = true
        }
    }
}
