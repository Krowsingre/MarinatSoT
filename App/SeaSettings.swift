import Foundation
import MarinCore

/// Options for looking at the sea in a chosen state.
///
/// Normally the sea follows the phone's clock and the day's own weather. For testing,
/// the app can be launched with arguments such as `-seaHour 19 -seaWeather storm`.
struct SeaSettings {
    var hourOverride: Double?
    var weatherOverride: Weather?
    var timeScale: Double = 1
    /// How far along the sea the boat starts.
    var worldX: Double = 0
    /// Start with the line already cast.
    var startFishing = false
    /// Start with the boat already sailing.
    var startSailing = false
    /// Bring a bottle to the line almost at once.
    var quickBite = false
    /// Open with a landed bottle on screen.
    var demoCatch = false
    /// Open with the composing page on screen.
    var demoCompose = false
    /// Open on the home screen. Testing can skip it with `-seaHome 0`.
    var showHome = true
    /// Show the sea at a chosen level of magic, 0 ... 1, whatever has been written.
    var magicOverride: Double?

    static func fromLaunchArguments(_ defaults: UserDefaults = .standard) -> SeaSettings {
        var settings = SeaSettings()
        if let text = defaults.string(forKey: "seaHour"), let hour = Double(text) {
            settings.hourOverride = hour
        }
        if let text = defaults.string(forKey: "seaWeather") {
            settings.weatherOverride = Weather(rawValue: text)
        }
        if let text = defaults.string(forKey: "seaTimeScale"), let scale = Double(text), scale > 0 {
            settings.timeScale = scale
        }
        if let text = defaults.string(forKey: "seaWorldX"), let x = Double(text) {
            settings.worldX = x
        }
        settings.startFishing = defaults.string(forKey: "seaFishing") == "1"
        settings.startSailing = defaults.string(forKey: "seaSailing") == "1"
        settings.quickBite = defaults.string(forKey: "seaBite") == "1"
        settings.demoCatch = defaults.string(forKey: "seaCatch") == "1"
        settings.demoCompose = defaults.string(forKey: "seaCompose") == "1"
        settings.showHome = defaults.string(forKey: "seaHome") != "0"
        if let text = defaults.string(forKey: "seaMagic"), let magic = Double(text) {
            settings.magicOverride = min(max(magic, 0), 1)
        }
        return settings
    }
}
