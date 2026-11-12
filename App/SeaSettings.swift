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
        return settings
    }
}
