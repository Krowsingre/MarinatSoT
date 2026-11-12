import Foundation
import MarinCore

/// Options for looking at the sea at a chosen time or in chosen weather.
///
/// Normally the sea follows the phone's clock and the day's own weather. For testing,
/// the app can be launched with arguments such as `-seaHour 19 -seaWeather storm`,
/// or `-seaTimeScale 3600` to watch a whole day pass in 24 seconds.
struct SeaSettings {
    var hourOverride: Double?
    var weatherOverride: Weather?
    var timeScale: Double = 1

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
        return settings
    }
}
