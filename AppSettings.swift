//
//  AppSettings.swift (PRIORITY 1 PERFORMANCE FIX)
//  LED MESSENGER
//
//  🚨 CRITICAL FIX: Moved all file I/O operations off main thread
//  ✅ PERFORMANCE: Eliminated main thread hangs and slow launches
//  Updated: June 22, 2025 - Emergency Performance Repair
//

import Foundation
import Observation
import OSLog

// Private logger instance
private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.ledmessenger", category: "App")

// 🚨 CRITICAL FIX: Removed @MainActor to allow background file operations
@Observable
public final class AppSettings: @unchecked Sendable {
    
    // MARK: - Device Environment Integration
    
    /// Device environment for device-specific configuration
    private let deviceEnvironment: DeviceEnvironment
    
    // MARK: - Device-Aware Default Values
    
    private struct Defaults {
        static func oscHost(for deviceType: DeviceType) -> String {
            return ""
        }
        
        static func oscPort(for deviceType: DeviceType) -> UInt16 {
            return 2269
        }
        
        static let layer: Int = 3
        static let startSlot: Int = 1
        static let clipCount: Int = 3
        
        static func autoClearAfter(for deviceType: DeviceType) -> TimeInterval {
            switch deviceType {
            case .iPhone: return 180
            case .iPad: return 180
            case .macCatalyst, .mac: return 300
            }
        }
        
        static let forceCaps = true
        static let lineBreakMode = 2
        
        static func charsPerLine(for deviceType: DeviceType) -> Double {
            switch deviceType {
            case .iPhone: return 12.0
            case .iPad: return 12.0
            case .macCatalyst, .mac: return 12.0
            }
        }
        
        static let defaultLabelType = 0
        static let customLabelPrefix = ""
        static let webhookUrl = ""
        static let oscTextDelay: TimeInterval = 0.2
    }
    
    // MARK: - Background File I/O Actor (NEW - Performance Fix)
    
    private actor FileIOManager {
        private let deviceType: DeviceType
        
        init(deviceType: DeviceType) {
            self.deviceType = deviceType
        }
        
        /// Background file operations - OFF MAIN THREAD
        var settingsURL: URL {
            get async {
                let base = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                ).first!
                
                let dir = base.appendingPathComponent("LEDMessenger", isDirectory: true)
                
                // ✅ FIXED: Directory creation on background actor
                do {
                    try FileManager.default.createDirectory(
                        at: dir, 
                        withIntermediateDirectories: true
                    )
                } catch {
                    logger.error("Failed to create settings directory: \(error)")
                }
                
                let filename = "AppSettings-\(deviceType.rawValue).json"
                return dir.appendingPathComponent(filename)
            }
        }
        
        /// Load settings data from file - OFF MAIN THREAD
        func loadSettingsData() async throws -> Data {
            let url = await settingsURL
            // ✅ FIXED: File reading on background actor
            return try Data(contentsOf: url)
        }
        
        /// Save settings data to file - OFF MAIN THREAD  
        func saveSettingsData(_ data: Data) async throws {
            let url = await settingsURL
            // ✅ FIXED: File writing on background actor
            try data.write(to: url, options: .atomic)
        }
        
        /// Delete settings file - OFF MAIN THREAD
        func deleteSettingsFile() async throws {
            let url = await settingsURL
            // ✅ FIXED: File deletion on background actor
            try FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Enhanced Actor Storage
    
    private actor SettingsStorage {
        var oscHost: String
        var oscPort: UInt16
        var layer: Int = Defaults.layer
        var startSlot: Int = Defaults.startSlot
        var clipCount: Int = Defaults.clipCount
        var autoClearAfter: TimeInterval
        var forceCaps = Defaults.forceCaps
        var lineBreakMode = Defaults.lineBreakMode
        var charsPerLine: Double
        var defaultLabelType = Defaults.defaultLabelType
        var customLabelPrefix = Defaults.customLabelPrefix
        var webhookUrl = Defaults.webhookUrl
        var oscTextDelay: TimeInterval = Defaults.oscTextDelay
        var didLoad = false
        var deviceType: DeviceType
        var hasValidatedConnection = false
        var lastConnectionTest: Date?
        
        init(deviceType: DeviceType) {
            self.deviceType = deviceType
            self.oscHost = Defaults.oscHost(for: deviceType)
            self.oscPort = Defaults.oscPort(for: deviceType)
            self.autoClearAfter = Defaults.autoClearAfter(for: deviceType)
            self.charsPerLine = Defaults.charsPerLine(for: deviceType)
        }
        
        func getSettings() -> (
            host: String, port: UInt16, layer: Int, startSlot: Int, clipCount: Int,
            autoClearAfter: TimeInterval, forceCaps: Bool, lineBreakMode: Int, charsPerLine: Double,
            defaultLabelType: Int, customLabelPrefix: String, webhookUrl: String, oscTextDelay: TimeInterval,
            didLoad: Bool, deviceType: DeviceType, hasValidatedConnection: Bool, lastConnectionTest: Date?
        ) {
            return (oscHost, oscPort, layer, startSlot, clipCount, autoClearAfter, forceCaps, 
                   lineBreakMode, charsPerLine, defaultLabelType, customLabelPrefix, webhookUrl,
                   oscTextDelay, didLoad, deviceType, hasValidatedConnection, lastConnectionTest)
        }
        
        // Update methods
        func updateHost(_ value: String) { oscHost = value }
        func updatePort(_ value: UInt16) { oscPort = value }
        func updateLayer(_ value: Int) { layer = value }
        func updateStartSlot(_ value: Int) { startSlot = value }
        func updateClipCount(_ value: Int) { clipCount = value }
        func updateAutoClearAfter(_ value: TimeInterval) { autoClearAfter = value }
        func updateForceCaps(_ value: Bool) { forceCaps = value }
        func updateLineBreakMode(_ value: Int) { lineBreakMode = value }
        func updateCharsPerLine(_ value: Double) { charsPerLine = value }
        func updateDefaultLabelType(_ value: Int) { defaultLabelType = value }
        func updateCustomLabelPrefix(_ value: String) { customLabelPrefix = value }
        func updateWebhookUrl(_ value: String) { webhookUrl = value }
        func updateOscTextDelay(_ value: TimeInterval) { oscTextDelay = value }
        func setDidLoad(_ value: Bool) { didLoad = value }
        func setValidatedConnection(_ value: Bool) { hasValidatedConnection = value }
        func setLastConnectionTest(_ value: Date?) { lastConnectionTest = value }
        
        func resetToDeviceDefaults() {
            oscHost = Defaults.oscHost(for: deviceType)
            oscPort = Defaults.oscPort(for: deviceType)
            layer = Defaults.layer
            startSlot = Defaults.startSlot
            clipCount = Defaults.clipCount
            autoClearAfter = Defaults.autoClearAfter(for: deviceType)
            forceCaps = Defaults.forceCaps
            lineBreakMode = Defaults.lineBreakMode
            charsPerLine = Defaults.charsPerLine(for: deviceType)
            defaultLabelType = Defaults.defaultLabelType
            customLabelPrefix = Defaults.customLabelPrefix
            webhookUrl = Defaults.webhookUrl
            hasValidatedConnection = false
            lastConnectionTest = nil
        }
    }
    
    // MARK: - Properties
    
    public let id = UUID()
    private let storage: SettingsStorage
    private let fileManager: FileIOManager  // NEW: Background file operations
    public let oscService: OSCServiceProtocol
    private var syncTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    
    // ✅ FIXED: Main-actor isolated published properties for UI binding
    @MainActor
    public private(set) var oscHost: String = ""
    
    @MainActor  
    public private(set) var oscPort: UInt16 = 2269
    
    @MainActor
    public private(set) var layer: Int = 3
    
    @MainActor
    public private(set) var startSlot: Int = 1
    
    @MainActor
    public private(set) var clipCount: Int = 3
    
    @MainActor
    public private(set) var autoClearAfter: TimeInterval = 180
    
    @MainActor
    public private(set) var forceCaps: Bool = true
    
    @MainActor
    public private(set) var lineBreakMode: Int = 2
    
    @MainActor
    public private(set) var charsPerLine: Double = 12.0
    
    @MainActor
    public private(set) var defaultLabelType: Int = 0
    
    @MainActor
    public private(set) var customLabelPrefix: String = ""
    
    @MainActor
    public private(set) var webhookUrl: String = ""
    
    @MainActor
    public private(set) var oscTextDelay: TimeInterval = 0.2
    
    @MainActor
    private var didLoad = false
    
    @MainActor
    public private(set) var hasValidatedConnection = false
    
    @MainActor
    public private(set) var lastConnectionTest: Date?
    
    /// Computed property for the clear clip index
    @MainActor
    public var clearClip: Int {
        return startSlot + clipCount
    }
    
    /// True once JSON has loaded and the current values pass validation
    @MainActor
    public var isConfigured: Bool {
        didLoad && configurationValidated
    }
    
    // MARK: - Initialization (Performance Fixed)
    
    public init(deviceEnvironment: DeviceEnvironment, oscService: OSCServiceProtocol? = nil) {
        self.deviceEnvironment = deviceEnvironment
        self.storage = SettingsStorage(deviceType: deviceEnvironment.deviceType)
        self.fileManager = FileIOManager(deviceType: deviceEnvironment.deviceType)  // NEW
        
        // Calculate device-appropriate defaults
        let defaultHost = Defaults.oscHost(for: deviceEnvironment.deviceType)
        let defaultPort = Defaults.oscPort(for: deviceEnvironment.deviceType)
        let defaultLayer = Defaults.layer
        let defaultStartSlot = Defaults.startSlot
        let defaultClipCount = Defaults.clipCount
        
        logger.info("🔧 AppSettings init for \(deviceEnvironment.deviceType.rawValue)")
        
        // Create device-aware OSC service
        if let service = oscService {
            self.oscService = service
        } else {
            self.oscService = OSCService(
                host: defaultHost,
                port: defaultPort,
                layer: defaultLayer,
                clipCount: defaultClipCount,
                clearClip: defaultStartSlot + defaultClipCount,
                deviceEnvironment: deviceEnvironment
            )
        }
        
        // ✅ PERFORMANCE FIX: Load settings on background queue
        Task.detached { [weak self] in
            await self?.loadSettingsInBackground()
        }
    }
    
    public convenience init(oscService: OSCServiceProtocol? = nil) {
        self.init(deviceEnvironment: DeviceEnvironment(), oscService: oscService)
    }
    
    // MARK: - ✅ PERFORMANCE FIXED: Background File Operations
    
    /// Load settings from file - BACKGROUND OPERATION
    private func loadSettingsInBackground() async {
        do {
            // ✅ FIXED: File I/O on background queue
            let data = try await fileManager.loadSettingsData()
            let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
            
            // Validate settings for device type
            let validatedSettings = validateSettingsForDevice(decoded)
            
            // Update storage (background operation)
            await storage.updateHost(validatedSettings.oscHost)
            await storage.updatePort(validatedSettings.oscPort)
            await storage.updateLayer(validatedSettings.layer)
            await storage.updateStartSlot(validatedSettings.startSlot)
            await storage.updateClipCount(validatedSettings.clipCount)
            await storage.updateAutoClearAfter(validatedSettings.autoClearAfter)
            await storage.updateForceCaps(validatedSettings.forceCaps)
            await storage.updateLineBreakMode(validatedSettings.lineBreakMode)
            await storage.updateCharsPerLine(validatedSettings.charsPerLine)
            await storage.updateDefaultLabelType(validatedSettings.defaultLabelType ?? Defaults.defaultLabelType)
            await storage.updateCustomLabelPrefix(validatedSettings.customLabelPrefix ?? Defaults.customLabelPrefix)
            await storage.updateWebhookUrl(validatedSettings.webhookUrl ?? Defaults.webhookUrl)
            await storage.updateOscTextDelay(validatedSettings.oscTextDelay ?? Defaults.oscTextDelay)
            
            // ✅ FIXED: UI updates on main thread
            await syncPropertiesFromStorageToMainThread()
            
            let clearClip = validatedSettings.startSlot + validatedSettings.clipCount
            
            await oscService.configure(
                OSCConfiguration(
                    host: validatedSettings.oscHost,
                    port: validatedSettings.oscPort,
                    layer: validatedSettings.layer,
                    clipCount: validatedSettings.clipCount,
                    clearClip: clearClip,
                    textDelay: validatedSettings.oscTextDelay ?? Defaults.oscTextDelay
                )
            )
            
            logger.info("✅ Settings loaded successfully from file")
            
        } catch {
            logger.info("Using default settings (file not found or invalid)")
            
            // Configure OSC with device-appropriate defaults
            let settings = await storage.getSettings()
            let clearClip = settings.startSlot + settings.clipCount
            
            await oscService.configure(
                OSCConfiguration(
                    host: settings.host,
                    port: settings.port,
                    layer: settings.layer,
                    clipCount: settings.clipCount,
                    clearClip: clearClip,
                    textDelay: settings.oscTextDelay
                )
            )
            
            await syncPropertiesFromStorageToMainThread()
        }
        
        await storage.setDidLoad(true)
        await MainActor.run { [weak self] in
            self?.didLoad = true
        }
    }
    
    /// Sync properties from storage to main thread - PERFORMANCE OPTIMIZED
    private func syncPropertiesFromStorageToMainThread() async {
        let settings = await storage.getSettings()
        
        // ✅ FIXED: All UI updates on main thread
        await MainActor.run { [weak self] in
            self?.oscHost = settings.host
            self?.oscPort = settings.port
            self?.layer = settings.layer
            self?.startSlot = settings.startSlot
            self?.clipCount = settings.clipCount
            self?.autoClearAfter = settings.autoClearAfter
            self?.forceCaps = settings.forceCaps
            self?.lineBreakMode = settings.lineBreakMode
            self?.charsPerLine = settings.charsPerLine
            self?.defaultLabelType = settings.defaultLabelType
            self?.customLabelPrefix = settings.customLabelPrefix
            self?.webhookUrl = settings.webhookUrl
            self?.oscTextDelay = settings.oscTextDelay
            self?.hasValidatedConnection = settings.hasValidatedConnection
            self?.lastConnectionTest = settings.lastConnectionTest
        }
        
        logger.debug("🔄 Properties synced to main thread")
    }
    
    /// Save settings to file - BACKGROUND OPERATION
    private func persistInBackground() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            let settings = await self.storage.getSettings()
            
            let snap = Snapshot(
                oscHost: settings.host,
                oscPort: settings.port,
                layer: settings.layer,
                startSlot: settings.startSlot,
                clipCount: settings.clipCount,
                autoClearAfter: settings.autoClearAfter,
                forceCaps: settings.forceCaps,
                lineBreakMode: settings.lineBreakMode,
                charsPerLine: settings.charsPerLine,
                defaultLabelType: settings.defaultLabelType,
                customLabelPrefix: settings.customLabelPrefix,
                webhookUrl: settings.webhookUrl,
                oscTextDelay: settings.oscTextDelay
            )
            
            do {
                let data = try JSONEncoder().encode(snap)
                // ✅ FIXED: File writing on background queue
                try await self.fileManager.saveSettingsData(data)
                
                logger.debug("💾 Settings saved to file")
                
                let clearClip = settings.startSlot + settings.clipCount
                
                await self.oscService.configure(
                    OSCConfiguration(
                        host: settings.host,
                        port: settings.port,
                        layer: settings.layer,
                        clipCount: settings.clipCount,
                        clearClip: clearClip,
                        textDelay: settings.oscTextDelay
                    )
                )
                
            } catch {
                logger.error("Failed to save settings: \(error.localizedDescription)")
            }
        }
    }
    
    /// Debounced save with background file I/O
    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !Task.isCancelled {
                self?.persistInBackground()
            }
        }
    }
    
    // MARK: - Device-Specific Validation (Unchanged)
    
    private func validateSettingsForDevice(_ settings: Snapshot) -> Snapshot {
        var validated = settings
        
        switch deviceEnvironment.deviceType {
        case .iPhone:
            if validated.autoClearAfter > 300 {
                validated.autoClearAfter = 120
            }
            if validated.charsPerLine > 8 {
                validated.charsPerLine = 6
            }
            
        case .iPad:
            break
            
        case .macCatalyst, .mac:
            if validated.charsPerLine < 8 {
                validated.charsPerLine = 10
            }
        }
        
        return validated
    }
    
    // MARK: - Device-Aware Formatting (Unchanged)
    
    @MainActor
    public func formatMessage(_ text: String) -> String {
        let formattedText = self.forceCaps ? text.uppercased() : text
        var result = formattedText
        
        let effectiveCharsPerLine: Int
        switch deviceEnvironment.deviceType {
        case .iPhone:
            effectiveCharsPerLine = min(Int(charsPerLine), 6)
        case .iPad:
            effectiveCharsPerLine = Int(charsPerLine)
        case .macCatalyst, .mac:
            effectiveCharsPerLine = max(Int(charsPerLine), 8)
        }
        
        switch lineBreakMode {
        case 0: // No line breaks
            break
            
        case 1: // Break after words
            let wordsPerLineLimit = max(1, effectiveCharsPerLine / 5)
            let words = formattedText.components(separatedBy: " ")
            var lines = [String]()
            var currentLine = [String]()
            var wordCount = 0
            
            for word in words {
                currentLine.append(word)
                wordCount += 1
                
                if wordCount >= wordsPerLineLimit {
                    lines.append(currentLine.joined(separator: " "))
                    currentLine = []
                    wordCount = 0
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
            
            result = lines.joined(separator: "\n")
            
        case 2: // Break after characters
            let charLimit = max(1, effectiveCharsPerLine)
            let words = formattedText.components(separatedBy: " ")
            var lines = [String]()
            var currentLine = ""
            
            for word in words {
                if currentLine.count + word.count + 1 > charLimit && !currentLine.isEmpty {
                    lines.append(currentLine)
                    currentLine = word
                } else if currentLine.isEmpty {
                    currentLine = word
                } else {
                    currentLine += " " + word
                }
            }
            
            if !currentLine.isEmpty {
                lines.append(currentLine)
            }
            
            result = lines.joined(separator: "\n")
            
        default:
            break
        }
        
        return result
    }
    
    // MARK: - Reset and File Management (Performance Fixed)
    
    @MainActor
    public func resetToDefaults() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.resetToDeviceDefaults()
            await self.syncPropertiesFromStorageToMainThread()
            self.persistInBackground()
            
            logger.info("🔄 Reset to device defaults")
        }
    }
    
    @MainActor
    public func deleteSettingsFile() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            do {
                // ✅ FIXED: File deletion on background queue
                try await self.fileManager.deleteSettingsFile()
                logger.info("🗑️ Settings file deleted")
                
                await self.storage.resetToDeviceDefaults()
                await self.syncPropertiesFromStorageToMainThread()
                
            } catch {
                logger.error("Failed to delete settings file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Connection Validation (Performance Optimized)
    
    public func testConnection() async -> Bool {
        let currentHost = await MainActor.run { oscHost }
        let currentPort = await MainActor.run { oscPort }
        
        guard !currentHost.isEmpty && currentPort > 0 else {
            logger.warning("Cannot test connection: Host or port not configured")
            await storage.setValidatedConnection(false)
            await storage.setLastConnectionTest(Date())
            await syncPropertiesFromStorageToMainThread()
            return false
        }
        
        logger.info("🔧 Testing connection to \(currentHost):\(currentPort)...")
        
        do {
            if let oscService = oscService as? OSCService {
                await oscService.forceConnect()
                try await Task.sleep(for: .seconds(2))
                try await oscService.ping()
            } else {
                try await oscService.ping()
            }
            
            await storage.setValidatedConnection(true)
            await storage.setLastConnectionTest(Date())
            await syncPropertiesFromStorageToMainThread()
            debouncedSave()
            
            logger.info("✅ Connection validated successfully")
            return true
            
        } catch {
            logger.error("❌ Connection test failed: \(error.localizedDescription)")
            await storage.setValidatedConnection(false)
            await storage.setLastConnectionTest(Date())
            await syncPropertiesFromStorageToMainThread()
            debouncedSave()
            return false
        }
    }
    
    @MainActor
    public func markConnectionAsValidated() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.setValidatedConnection(true)
            await self.storage.setLastConnectionTest(Date())
            await self.syncPropertiesFromStorageToMainThread()
            self.debouncedSave()
            
            logger.info("✅ Connection marked as validated")
        }
    }
    
    @MainActor
    public func clearConnectionValidation() {
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.setValidatedConnection(false)
            await self.storage.setLastConnectionTest(nil)
            await self.syncPropertiesFromStorageToMainThread()
            self.debouncedSave()
            
            logger.info("🔄 Connection validation cleared")
        }
    }
    
    // MARK: - Public Setters (Performance Optimized)
    
    @MainActor
    public func setOscHost(_ host: String) {
        oscHost = host  // Immediate UI update
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.updateHost(host)
            await self.storage.setValidatedConnection(false)
            await self.storage.setLastConnectionTest(nil)
            self.debouncedSave()
            
            logger.debug("📶 Host changed, connection validation cleared")
        }
    }
    
    @MainActor
    public func setOscPort(_ port: UInt16) {
        oscPort = port  // Immediate UI update
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.updatePort(port)
            await self.storage.setValidatedConnection(false)
            await self.storage.setLastConnectionTest(nil)
            self.debouncedSave()
            
            logger.debug("📶 Port changed, connection validation cleared")
        }
    }
    
    @MainActor
    public func setLayer(_ newLayer: Int) {
        layer = newLayer  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateLayer(newLayer)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setStartSlot(_ newStartSlot: Int) {
        startSlot = newStartSlot  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateStartSlot(newStartSlot)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setClipCount(_ newClipCount: Int) {
        clipCount = newClipCount  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateClipCount(newClipCount)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setAutoClearAfter(_ newAutoClearAfter: TimeInterval) {
        autoClearAfter = newAutoClearAfter  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateAutoClearAfter(newAutoClearAfter)
            self?.persistInBackground()  // Direct save for this setting
        }
    }
    
    @MainActor
    public func setForceCaps(_ newForceCaps: Bool) {
        forceCaps = newForceCaps  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateForceCaps(newForceCaps)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setLineBreakMode(_ newLineBreakMode: Int) {
        lineBreakMode = newLineBreakMode  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateLineBreakMode(newLineBreakMode)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setCharsPerLine(_ newCharsPerLine: Double) {
        charsPerLine = newCharsPerLine  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateCharsPerLine(newCharsPerLine)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setDefaultLabelType(_ newDefaultLabelType: Int) {
        defaultLabelType = newDefaultLabelType  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateDefaultLabelType(newDefaultLabelType)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setCustomLabelPrefix(_ newCustomLabelPrefix: String) {
        customLabelPrefix = newCustomLabelPrefix  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateCustomLabelPrefix(newCustomLabelPrefix)
            self?.debouncedSave()
        }
    }
    
    @MainActor
    public func setWebhookUrl(_ newWebhookUrl: String) {
        webhookUrl = newWebhookUrl  // Immediate UI update
        
        Task.detached { [weak self] in
            await self?.storage.updateWebhookUrl(newWebhookUrl)
            self?.debouncedSave()
        }
    }
    
    // MARK: - Apply Device-Specific Network Settings (NEW - iOS 18)
    
    @MainActor
    public func applyNetworkingSettings(_ networkSettings: NetworkingSettings) {
        // Apply relevant networking settings to AppSettings properties
        // Note: oscTimeout and other networking-specific timeouts could be stored
        // if needed in the future, but for now we focus on OSC text delay
        
        // Map device-specific delays to OSC text delay if appropriate
        let deviceOptimizedDelay: TimeInterval
        switch networkSettings.preferredConnectionType {
        case .ethernet:
            deviceOptimizedDelay = 0.1  // Fast for wired connections
        case .wifi:
            deviceOptimizedDelay = 0.2  // Standard for WiFi
        case .cellular:
            deviceOptimizedDelay = 0.5  // Slower for mobile data
        case .adaptive:
            deviceOptimizedDelay = 0.2  // Default
        }
        
        // Update OSC text delay if it's significantly different
        if abs(oscTextDelay - deviceOptimizedDelay) > 0.05 {
            oscTextDelay = deviceOptimizedDelay  // Immediate UI update
            
            Task.detached { [weak self] in
                await self?.storage.updateOscTextDelay(deviceOptimizedDelay)
                self?.debouncedSave()
            }
            
            logger.info("🔧 Applied device networking settings: \(networkSettings.preferredConnectionType.displayName), delay: \(deviceOptimizedDelay)s")
        }
        
        // Future: Could add more networking-specific settings here as needed
        // For example: connection timeouts, retry attempts, etc.
        
        logger.debug("📶 Device networking settings applied for \(networkSettings.preferredConnectionType.displayName)")
    }
    
    // MARK: - Convenience Methods (Performance Optimized)
    
    @MainActor
    public func updateNetworkConfig(host: String, port: UInt16) {
        oscHost = host      // Immediate UI updates
        oscPort = port
        hasValidatedConnection = false
        lastConnectionTest = nil
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.updateHost(host)
            await self.storage.updatePort(port)
            await self.storage.setValidatedConnection(false)
            await self.storage.setLastConnectionTest(nil)
            self.debouncedSave()
            
            logger.debug("📶 Network config updated")
        }
    }
    
    @MainActor
    public func updateClipConfig(layer: Int, startSlot: Int, clipCount: Int) {
        self.layer = layer          // Immediate UI updates
        self.startSlot = startSlot
        self.clipCount = clipCount
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.updateLayer(layer)
            await self.storage.updateStartSlot(startSlot)
            await self.storage.updateClipCount(clipCount)
            self.debouncedSave()
            
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("SettingsChanged"), object: nil)
            }
        }
    }
    
    @MainActor
    public func updateLabelConfig(defaultLabelType: Int, customLabelPrefix: String) {
        self.defaultLabelType = defaultLabelType      // Immediate UI updates
        self.customLabelPrefix = customLabelPrefix
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.storage.updateDefaultLabelType(defaultLabelType)
            await self.storage.updateCustomLabelPrefix(customLabelPrefix)
            self.debouncedSave()
            
            logger.debug("📝 Label config updated: type=\(defaultLabelType), prefix='\(customLabelPrefix)'")
        }
    }
    
    // MARK: - Private Helper Methods
    
    @MainActor
    private var configurationValidated: Bool {
        !oscHost.isEmpty &&
        (1...255).contains(startSlot) &&
        layer >= 1 &&
        (startSlot + clipCount) <= 255 &&
        hasValidatedConnection
    }
    
    @MainActor
    public func forceSave() {
        persistInBackground()
    }
    
    // MARK: - Codable Snapshot (Unchanged)
    
    private struct Snapshot: Codable {
        var oscHost: String
        var oscPort: UInt16
        var layer: Int
        var startSlot: Int
        var clipCount: Int
        var autoClearAfter: TimeInterval
        var forceCaps: Bool
        var lineBreakMode: Int
        var charsPerLine: Double
        var defaultLabelType: Int?
        var customLabelPrefix: String?
        var webhookUrl: String?
        var oscTextDelay: TimeInterval?
        
        init(oscHost: String, oscPort: UInt16, layer: Int, startSlot: Int, clipCount: Int,
             autoClearAfter: TimeInterval, forceCaps: Bool, lineBreakMode: Int, charsPerLine: Double,
             defaultLabelType: Int? = nil, customLabelPrefix: String? = nil, webhookUrl: String? = nil,
             oscTextDelay: TimeInterval? = nil) {
            self.oscHost = oscHost
            self.oscPort = oscPort
            self.layer = layer
            self.startSlot = startSlot
            self.clipCount = clipCount
            self.autoClearAfter = autoClearAfter
            self.forceCaps = forceCaps
            self.lineBreakMode = lineBreakMode
            self.charsPerLine = charsPerLine
            self.defaultLabelType = defaultLabelType
            self.customLabelPrefix = customLabelPrefix
            self.webhookUrl = webhookUrl
            self.oscTextDelay = oscTextDelay
        }
    }
}