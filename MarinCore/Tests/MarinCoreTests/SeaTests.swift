import XCTest
@testable import MarinCore

final class SeaClockTests: XCTestCase {
    func testPhasesThroughTheDay() {
        XCTAssertEqual(SeaClock.phase(atHour: 0), .night)
        XCTAssertEqual(SeaClock.phase(atHour: 4.99), .night)
        XCTAssertEqual(SeaClock.phase(atHour: 5), .dawn)
        XCTAssertEqual(SeaClock.phase(atHour: 7), .day)
        XCTAssertEqual(SeaClock.phase(atHour: 12), .day)
        XCTAssertEqual(SeaClock.phase(atHour: 18), .dusk)
        XCTAssertEqual(SeaClock.phase(atHour: 20), .night)
        XCTAssertEqual(SeaClock.phase(atHour: 23.9), .night)
    }

    func testHoursWrapAround() {
        XCTAssertEqual(SeaClock.normalized(24), 0, accuracy: 1e-9)
        XCTAssertEqual(SeaClock.normalized(25.5), 1.5, accuracy: 1e-9)
        XCTAssertEqual(SeaClock.normalized(-1), 23, accuracy: 1e-9)
        XCTAssertEqual(SeaClock.phase(atHour: 36), .day)
    }

    func testDaylightStaysInRangeAndPeaksAtNoon() {
        var hour = 0.0
        while hour < 24 {
            let light = SeaClock.daylight(atHour: hour)
            XCTAssertGreaterThanOrEqual(light, 0)
            XCTAssertLessThanOrEqual(light, 1)
            hour += 0.25
        }
        XCTAssertEqual(SeaClock.daylight(atHour: 12), 1)
        XCTAssertEqual(SeaClock.daylight(atHour: 0), 0)
        XCTAssertGreaterThan(SeaClock.daylight(atHour: 6), 0)
        XCTAssertLessThan(SeaClock.daylight(atHour: 6), 1)
    }

    func testHourForDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 12, hour: 15, minute: 30))!
        XCTAssertEqual(SeaClock.hour(for: date, calendar: calendar), 15.5, accuracy: 1e-6)
    }
}

final class WeatherTests: XCTestCase {
    func testSameDayAlwaysHasSameWeather() {
        for day in 0 ..< 50 {
            XCTAssertEqual(WeatherForecast.weather(onDay: day), WeatherForecast.weather(onDay: day))
        }
    }

    func testStormsAreOccasional() {
        let days = 2000
        var counts: [Weather: Int] = [:]
        for day in 0 ..< days {
            counts[WeatherForecast.weather(onDay: day), default: 0] += 1
        }
        let storms = counts[.storm, default: 0]
        XCTAssertGreaterThan(storms, 0)
        XCTAssertLessThan(Double(storms) / Double(days), 0.15)
        XCTAssertGreaterThan(Double(counts[.clear, default: 0]) / Double(days), 0.35)
        for weather in Weather.allCases {
            XCTAssertGreaterThan(counts[weather, default: 0], 0, "\(weather) never happens")
        }
    }

    func testStormIsTheRoughestWeather() {
        XCTAssertGreaterThan(Weather.storm.waveScale, Weather.rain.waveScale)
        XCTAssertGreaterThan(Weather.rain.waveScale, Weather.clear.waveScale)
        XCTAssertEqual(Weather.clear.rain, 0)
    }
}

final class SkyTests: XCTestCase {
    private func distance(_ a: RGB, _ b: RGB) -> Double {
        abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b)
    }

    func testSkyIsContinuousAcrossMidnight() {
        let before = Sky.palette(atHour: 23.999)
        let after = Sky.palette(atHour: 0.001)
        XCTAssertLessThan(distance(before.skyTop, after.skyTop), 0.01)
        XCTAssertLessThan(distance(before.waterDeep, after.waterDeep), 0.01)
        XCTAssertEqual(Sky.palette(atHour: 24), Sky.palette(atHour: 0))
    }

    func testSkyNeverJumps() {
        var hour = 0.0
        var previous = Sky.palette(atHour: hour)
        while hour < 24 {
            hour += 0.05
            let next = Sky.palette(atHour: hour)
            XCTAssertLessThan(distance(previous.horizon, next.horizon), 0.12, "jump near hour \(hour)")
            previous = next
        }
    }

    func testNoonIsBrighterThanMidnightAndStarsComeOutAtNight() {
        let noon = Sky.palette(atHour: 12)
        let midnight = Sky.palette(atHour: 0)
        XCTAssertGreaterThan(noon.skyTop.b, midnight.skyTop.b)
        XCTAssertEqual(noon.stars, 0)
        XCTAssertEqual(midnight.stars, 1)
    }

    func testStormDullsTheSkyAndHidesStars() {
        let clear = Sky.palette(atHour: 12, storminess: 0)
        let storm = Sky.palette(atHour: 12, storminess: 1)
        XCTAssertLessThan(storm.skyTop.b, clear.skyTop.b)
        XCTAssertEqual(Sky.palette(atHour: 0, storminess: 1).stars, 0)
    }
}
