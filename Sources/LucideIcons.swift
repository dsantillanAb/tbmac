import AppKit

public enum LucideIcons {
    private static let rawSVGs: [String: String] = [
        "codex": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
          <path d="M22.2819 9.8211a5.9847 5.9847 0 0 0-.5157-4.9108 6.0462 6.0462 0 0 0-6.5098-2.9A6.0651 6.0651 0 0 0 4.9807 4.1818a5.9847 5.9847 0 0 0-3.9977 2.9 6.0462 6.0462 0 0 0 .7427 7.0966 5.98 5.98 0 0 0 .511 4.9107 6.051 6.051 0 0 0 6.5146 2.9001A5.9847 5.9847 0 0 0 13.2599 24a6.0557 6.0557 0 0 0 5.7718-4.2058 5.9894 5.9894 0 0 0 3.9977-2.9001 6.0557 6.0557 0 0 0-.7475-7.0729zm-9.022 12.6081a4.4755 4.4755 0 0 1-2.8764-1.0408l.1419-.0804 4.7783-2.7582a.7948.7948 0 0 0 .3927-.6813v-6.7369l2.02 1.1686a.071.071 0 0 1 .038.052v5.5826a4.504 4.504 0 0 1-4.4945 4.4944zm-9.6607-4.1254a4.4708 4.4708 0 0 1-.5346-3.0137l.142.0852 4.783 2.7582a.7712.7712 0 0 0 .7806 0l5.8428-3.3685v2.3324a.0804.0804 0 0 1-.0332.0615L9.74 19.9502a4.4992 4.4992 0 0 1-6.1408-1.6464zM2.3408 7.8956a4.485 4.485 0 0 1 2.3655-1.9728V11.6a.7664.7664 0 0 0 .3879.6765l5.8144 3.3543-2.0201 1.1685a.0757.0757 0 0 1-.071 0l-4.8303-2.7865A4.504 4.504 0 0 1 2.3408 7.872zm16.5963 3.8558L13.1038 8.364 15.1192 7.2a.0757.0757 0 0 1 .071 0l4.8303 2.7913a4.4944 4.4944 0 0 1-.6765 8.1042v-5.6772a.79.79 0 0 0-.407-.667zm2.0107-3.0231l-.142-.0852-4.7735-2.7818a.7759.7759 0 0 0-.7854 0L9.409 9.2297V6.8974a.0662.0662 0 0 1 .0284-.0615l4.8303-2.7866a4.4992 4.4992 0 0 1 6.6802 4.66zM8.3065 12.863l-2.02-1.1638a.0804.0804 0 0 1-.038-.0567V6.0742a4.4992 4.4992 0 0 1 7.3757-3.4537l-.142.0805L8.704 5.459a.7948.7948 0 0 0-.3927.6813zm1.0976-2.3654l2.602-1.4998 2.6069 1.4998v2.9994l-2.5974 1.4997-2.6067-1.4997Z" fill="currentColor"/>
        </svg>
        """,
        "bot": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 8V4H8" />
          <rect width="16" height="12" x="4" y="8" rx="2" />
          <path d="M2 14h2" />
          <path d="M20 14h2" />
          <path d="M15 13v2" />
          <path d="M9 13v2" />
        </svg>
        """,
        "brain": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 18V5" />
          <path d="M15 13a4.17 4.17 0 01-3-4 4.17 4.17 0 01-3 4" />
          <path d="M17.707 6.294A3 3 0 1012 5a3 3 0 10-5.707 1.294" />
          <path d="M17.996 5.125a4 4 0 012.526 5.77" />
          <path d="M18 18a4 4 0 002-7.465" />
          <path d="M19.967 17.482a4 4 0 11-7.967.517 4 4 0 11-7.967-.517" />
          <path d="M6 18a4 4 0 01-2-7.465" />
          <path d="M6.004 5.125a4 4 0 00-2.526 5.77" />
        </svg>
        """,
        "messageSquare": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 17a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 2.202A.71.71 0 0 1 2 21.286V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2z" />
        </svg>
        """,
        "terminal": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 19h8" />
          <path d="m4 17 6-6-6-6" />
        </svg>
        """,
        "check": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 6 9 17l-5-5" />
        </svg>
        """,
        "checkCheck": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M18 6 7 17l-5-5" />
          <path d="m22 10-7.5 7.5L13 16" />
        </svg>
        """,
        "shieldAlert": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z" />
          <path d="M12 8v4" />
          <path d="M12 16h.01" />
        </svg>
        """,
        "copy": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
          <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
        </svg>
        """,
        "x": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M18 6 6 18" />
          <path d="m6 6 12 12" />
        </svg>
        """,
        "activity": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2" />
        </svg>
        """,
        "play": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z" />
        </svg>
        """,
        "folder": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" />
        </svg>
        """,
        "sparkles": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z" />
          <path d="M20 2v4" />
          <path d="M22 4h-4" />
          <circle cx="4" cy="20" r="2" />
        </svg>
        """,
        "watch": """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="6" />
          <polyline points="12 10 12 12 13 13" />
          <path d="m16.13 7.66-.81-4.05a2 2 0 0 0-2-1.61h-2.68a2 2 0 0 0-2 1.61l-.78 4.05" />
          <path d="m7.88 16.36.8 4a2 2 0 0 0 2 1.61h2.72a2 2 0 0 0 2-1.61l.81-4.05" />
        </svg>
        """
    ]
    
    public static func image(named name: String, size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        guard let raw = rawSVGs[name] else {
            return NSImage(size: size)
        }
        
        let strokeValue: String
        let isTemplate: Bool
        
        if let color = color {
            isTemplate = false
            let rgb = color.usingColorSpace(.sRGB) ?? color
            let r = Int(rgb.redComponent * 255)
            let g = Int(rgb.greenComponent * 255)
            let b = Int(rgb.blueComponent * 255)
            strokeValue = String(format: "#%02X%02X%02X", r, g, b)
        } else {
            isTemplate = true
            strokeValue = "#000000"
        }
        
        let svg = raw.replacingOccurrences(of: "currentColor", with: strokeValue)
        guard let data = svg.data(using: .utf8), let img = NSImage(data: data) else {
            return NSImage(size: size)
        }
        
        img.size = size
        img.isTemplate = isTemplate
        return img
    }
    
    // Official Codex / OpenAI Logo
    public static func codex(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "codex", size: size, color: color)
    }
    
    public static func codexRotated(angleDegrees: Double, size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        let base = codex(size: size, color: color)
        let rotated = NSImage(size: size)
        rotated.lockFocus()
        let transform = NSAffineTransform()
        transform.translateX(by: size.width / 2.0, yBy: size.height / 2.0)
        transform.rotate(byDegrees: CGFloat(angleDegrees))
        transform.translateX(by: -size.width / 2.0, yBy: -size.height / 2.0)
        transform.concat()
        base.draw(in: NSRect(origin: .zero, size: size))
        rotated.unlockFocus()
        rotated.isTemplate = base.isTemplate
        return rotated
    }
    
    public static func bot(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "bot", size: size, color: color)
    }
    
    public static func brain(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "brain", size: size, color: color)
    }
    
    public static func messageSquare(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "messageSquare", size: size, color: color)
    }
    
    public static func terminal(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "terminal", size: size, color: color)
    }
    
    public static func check(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "check", size: size, color: color)
    }
    
    public static func checkCheck(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "checkCheck", size: size, color: color)
    }
    
    public static func shieldAlert(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "shieldAlert", size: size, color: color)
    }
    
    public static func copy(size: NSSize = NSSize(width: 18, height: 18), color: NSColor? = nil) -> NSImage {
        return image(named: "copy", size: size, color: color)
    }
    
    public static func x(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "x", size: size, color: color)
    }
    
    public static func activity(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "activity", size: size, color: color)
    }
    
    public static func play(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "play", size: size, color: color)
    }
    
    public static func folder(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "folder", size: size, color: color)
    }
    
    public static func sparkles(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "sparkles", size: size, color: color)
    }
    
    public static func watch(size: NSSize = NSSize(width: 16, height: 16), color: NSColor? = nil) -> NSImage {
        return image(named: "watch", size: size, color: color)
    }
}
