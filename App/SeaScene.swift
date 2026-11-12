import SpriteKit
import UIKit
import MarinCore

/// The sea: sky above, Marin's boat on the waterline, and the deep below.
///
/// Layers from back to front: sky, stars, sun and moon, clouds, far wave, boat, rain,
/// near wave, the deep, fish, the fishing line, and lightning.
final class SeaScene: SKScene {
    private struct Cloud {
        let node: SKShapeNode
        let speed: CGFloat
        let width: CGFloat
    }

    private struct Fish {
        let node: SKShapeNode
        let speed: CGFloat
    }

    private let settings: SeaSettings
    private var built = false
    private var startTime: TimeInterval?
    private var lastTime: TimeInterval = 0
    private var lastPaint: TimeInterval = -100
    private let startHour: Double

    private let sky = SKSpriteNode()
    private let starLayer = SKNode()
    private let starTexture = Paint.softGlow(diameter: 32)
    private let sun = SKNode()
    private let moon = SKNode()
    private let cloudLayer = SKNode()
    private var clouds: [Cloud] = []
    private let backWave = SKShapeNode()
    private let frontWave = SKShapeNode()
    private let deep = SKSpriteNode()
    private let boat = BoatNode()
    private let fishLayer = SKNode()
    private var fish: [Fish] = []
    private let line = SKShapeNode()
    private let hook = SKShapeNode(circleOfRadius: 2)
    private let rain = SKEmitterNode()
    private let flash = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))

    // The weather as currently shown. These ease toward the day's weather.
    private var cloudCover = 0.15
    private var rainAmount = 0.0
    private var storminess = 0.0
    private var waveScale = 1.0
    private var weatherReady = false
    private var flashCountdown = 2.0

    private var waterline: CGFloat { size.height * 0.62 }

    init(settings: SeaSettings) {
        self.settings = settings
        self.startHour = settings.hourOverride ?? SeaClock.hour(for: Date())
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("SeaScene is only created in code")
    }

    // MARK: - Setting up

    override func didMove(to view: SKView) {
        if !built {
            build()
            built = true
        }
        layout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if built {
            layout()
        }
    }

    private func build() {
        backgroundColor = .black

        sky.anchorPoint = .zero
        sky.zPosition = 0
        addChild(sky)

        starLayer.zPosition = 1
        addChild(starLayer)

        buildDisc(in: sun, radius: 22, glow: 190, glowAlpha: 0.55,
                  colour: UIColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 1))
        sun.zPosition = 2
        addChild(sun)

        buildDisc(in: moon, radius: 15, glow: 120, glowAlpha: 0.35,
                  colour: UIColor(red: 0.93, green: 0.94, blue: 0.98, alpha: 1))
        moon.zPosition = 2
        addChild(moon)

        cloudLayer.zPosition = 5
        addChild(cloudLayer)

        backWave.strokeColor = .clear
        backWave.lineWidth = 0
        backWave.zPosition = 20
        addChild(backWave)

        boat.zPosition = 30
        addChild(boat)

        rain.particleTexture = Paint.raindrop()
        rain.particleBirthRate = 0
        rain.particleSpeed = 900
        rain.particleSpeedRange = 120
        rain.emissionAngle = -.pi / 2 - 0.18
        rain.particleRotation = -0.18
        rain.particleAlpha = 0.5
        rain.particleAlphaRange = 0.25
        rain.particleBlendMode = .alpha
        rain.zPosition = 35
        addChild(rain)

        frontWave.strokeColor = .clear
        frontWave.lineWidth = 0
        frontWave.zPosition = 40
        addChild(frontWave)

        deep.anchorPoint = .zero
        deep.zPosition = 41
        addChild(deep)

        fishLayer.zPosition = 45
        addChild(fishLayer)

        line.strokeColor = UIColor(white: 1, alpha: 0.6)
        line.lineWidth = 1
        line.zPosition = 50
        addChild(line)

        hook.fillColor = UIColor(white: 1, alpha: 0.85)
        hook.strokeColor = .clear
        hook.zPosition = 50
        addChild(hook)

        flash.anchorPoint = .zero
        flash.alpha = 0
        flash.zPosition = 90
        addChild(flash)
    }

    private func buildDisc(in parent: SKNode, radius: CGFloat, glow: CGFloat, glowAlpha: CGFloat, colour: UIColor) {
        let halo = SKSpriteNode(texture: Paint.softGlow())
        halo.size = CGSize(width: glow, height: glow)
        halo.color = colour
        halo.colorBlendFactor = 1
        halo.alpha = glowAlpha
        halo.blendMode = .add
        parent.addChild(halo)

        let disc = SKShapeNode(circleOfRadius: radius)
        disc.fillColor = colour
        disc.strokeColor = .clear
        disc.zPosition = 1
        parent.addChild(disc)
    }

    /// Places everything for the current screen size.
    private func layout() {
        let width = size.width
        let height = size.height
        let water = waterline

        sky.position = CGPoint(x: 0, y: water - 60)
        sky.size = CGSize(width: width, height: height - water + 60)

        deep.position = .zero
        deep.size = CGSize(width: width, height: water - 40)

        flash.position = .zero
        flash.size = size

        rain.position = CGPoint(x: width / 2 + 80, y: height + 20)
        rain.particlePositionRange = CGVector(dx: width * 1.7, dy: 0)
        rain.particleLifetime = (height - water + 30) / 900

        boat.position = CGPoint(x: width * 0.40, y: water)

        layoutStars()
        layoutClouds()
        layoutFish()
        lastPaint = -100
    }

    private func layoutStars() {
        starLayer.removeAllChildren()
        let skyHeight = size.height - waterline
        for _ in 0 ..< 110 {
            let side = CGFloat.random(in: 2.5 ... 6.0)
            let star = SKSpriteNode(texture: starTexture)
            star.size = CGSize(width: side, height: side)
            star.position = CGPoint(
                x: CGFloat.random(in: 0 ... size.width),
                y: waterline + 24 + CGFloat.random(in: 0 ... 1) * (skyHeight - 24)
            )
            star.alpha = CGFloat.random(in: 0.45 ... 1)
            let duration = Double.random(in: 1.2 ... 3.5)
            star.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.25, duration: duration),
                .fadeAlpha(to: 1.0, duration: duration)
            ])))
            starLayer.addChild(star)
        }
    }

    private func layoutClouds() {
        cloudLayer.removeAllChildren()
        clouds = []
        let skyHeight = size.height - waterline
        let count = 8
        for index in 0 ..< count {
            let width = CGFloat.random(in: 150 ... 280)
            let node = SKShapeNode(path: cloudPath(width: width))
            node.strokeColor = .clear
            node.lineWidth = 0
            // Spread the clouds evenly up the sky, with a little randomness.
            let band = (CGFloat(index) + CGFloat.random(in: 0.2 ... 0.8)) / CGFloat(count)
            node.position = CGPoint(
                x: CGFloat.random(in: -40 ... size.width + 40),
                y: waterline + skyHeight * (0.22 + 0.72 * band)
            )
            cloudLayer.addChild(node)
            clouds.append(Cloud(node: node, speed: CGFloat.random(in: 3 ... 10), width: width))
        }
        clouds.shuffle()
    }

    private func cloudPath(width w: CGFloat) -> CGPath {
        let h = w * 0.30
        // The puffs are merged into one outline so that overlaps do not show as holes.
        let puffs = [
            CGRect(x: -w * 0.50, y: -h * 0.35, width: w, height: h * 0.70),
            CGRect(x: -w * 0.34, y: -h * 0.10, width: w * 0.38, height: h * 0.90),
            CGRect(x: -w * 0.08, y: 0, width: w * 0.42, height: h * 1.05),
            CGRect(x: w * 0.14, y: -h * 0.15, width: w * 0.30, height: h * 0.75)
        ]
        var path = CGPath(ellipseIn: puffs[0], transform: nil)
        for puff in puffs.dropFirst() {
            path = path.union(CGPath(ellipseIn: puff, transform: nil))
        }
        return path
    }

    private func layoutFish() {
        fishLayer.removeAllChildren()
        fish = []
        let top = waterline - 110
        guard top > 60 else { return }
        for _ in 0 ..< 5 {
            let tail = CGMutablePath()
            tail.move(to: CGPoint(x: -11, y: 0))
            tail.addLine(to: CGPoint(x: -22, y: 6))
            tail.addLine(to: CGPoint(x: -22, y: -6))
            tail.closeSubpath()
            let body = CGPath(ellipseIn: CGRect(x: -14, y: -5, width: 28, height: 10), transform: nil)
                .union(tail)

            let node = SKShapeNode(path: body)
            node.strokeColor = .clear
            node.lineWidth = 0
            node.fillColor = UIColor(red: 0.0, green: 0.03, blue: 0.07, alpha: 1)
            node.alpha = CGFloat.random(in: 0.16 ... 0.32)
            let scale = CGFloat.random(in: 0.7 ... 1.9)
            let goingRight = Bool.random()
            node.xScale = goingRight ? scale : -scale
            node.yScale = scale
            node.position = CGPoint(
                x: CGFloat.random(in: 0 ... size.width),
                y: CGFloat.random(in: 40 ... top)
            )
            fishLayer.addChild(node)
            let speed = CGFloat.random(in: 8 ... 22) * (goingRight ? 1 : -1)
            fish.append(Fish(node: node, speed: speed))
        }
    }

    // MARK: - Every frame

    override func update(_ currentTime: TimeInterval) {
        guard built else { return }
        if startTime == nil {
            startTime = currentTime
            lastTime = currentTime
        }
        let elapsed = currentTime - (startTime ?? currentTime)
        let step = min(max(currentTime - lastTime, 0), 0.1)
        lastTime = currentTime

        let hour = currentHour(elapsed: elapsed)
        let daylight = SeaClock.daylight(atHour: hour)
        easeWeather(step: step)

        let paintEvery = settings.timeScale > 60 ? 0.08 : 0.5
        if currentTime - lastPaint > paintEvery {
            repaint(hour: hour, daylight: daylight)
            lastPaint = currentTime
        }

        moveSunAndMoon(hour: hour)
        moveClouds(step: step)
        moveWaves(time: elapsed)
        moveBoat(time: elapsed)
        moveFish(step: step)
        lightning(step: step)
    }

    private func currentHour(elapsed: TimeInterval) -> Double {
        if settings.hourOverride == nil && settings.timeScale == 1 {
            return SeaClock.hour(for: Date())
        }
        return SeaClock.normalized(startHour + elapsed * settings.timeScale / 3600)
    }

    private func easeWeather(step: Double) {
        let target = settings.weatherOverride
            ?? WeatherForecast.weather(onDay: SeaClock.dayIndex(for: Date()))
        let amount = weatherReady ? min(step * 0.5, 1) : 1
        cloudCover += (target.cloudCover - cloudCover) * amount
        rainAmount += (target.rain - rainAmount) * amount
        storminess += (target.storminess - storminess) * amount
        waveScale += (target.waveScale - waveScale) * amount
        weatherReady = true
    }

    /// Recolours the scene for the hour and the weather.
    private func repaint(hour: Double, daylight: Double) {
        let palette = Sky.palette(atHour: hour, storminess: storminess)

        sky.texture = Paint.verticalGradient(top: palette.skyTop, bottom: palette.horizon)
        deep.texture = Paint.verticalGradient(top: palette.waterTop, bottom: palette.waterDeep)
        frontWave.fillColor = palette.waterTop.uiColor
        backWave.fillColor = palette.waterTop.mixed(with: palette.horizon, t: 0.35).uiColor

        starLayer.alpha = CGFloat(palette.stars * (1 - cloudCover * 0.85))
        sun.alpha = CGFloat(1 - cloudCover * 0.8)
        moon.alpha = CGFloat(1 - cloudCover * 0.8)

        let cloudBase = RGB(1, 1, 1).mixed(with: RGB(0.36, 0.38, 0.43), t: storminess)
        let cloudColour = cloudBase
            .scaled(0.22 + 0.78 * daylight)
            .mixed(with: palette.horizon, t: 0.22)
            .uiColor
        let shown = cloudCover * Double(clouds.count) * 1.15
        for (index, cloud) in clouds.enumerated() {
            cloud.node.fillColor = cloudColour
            let visible = min(max(shown - Double(index), 0), 1)
            cloud.node.alpha = CGFloat(visible * 0.9)
        }

        boat.setLight(daylight)
        rain.particleBirthRate = CGFloat(rainAmount * 420)
    }

    private func moveSunAndMoon(hour: Double) {
        let skyHeight = size.height - waterline
        func place(_ node: SKNode, along t: Double) {
            node.isHidden = t < -0.06 || t > 1.06
            node.position = CGPoint(
                x: size.width * CGFloat(0.08 + 0.84 * t),
                y: waterline - 30 + CGFloat(sin(Double.pi * t)) * skyHeight * 0.86
            )
        }
        // The sun crosses from six in the morning to six in the evening; the moon takes the night.
        place(sun, along: (hour - 6) / 12)
        place(moon, along: SeaClock.normalized(hour + 6) / 12)
    }

    private func moveClouds(step: Double) {
        let wind = CGFloat(1 + storminess * 2.5)
        for cloud in clouds {
            var x = cloud.node.position.x + cloud.speed * wind * CGFloat(step)
            if x - cloud.width / 2 > size.width {
                x = -cloud.width / 2
            }
            cloud.node.position.x = x
        }
    }

    /// The height of the sea surface above its resting level at a point across the screen.
    private func waveHeight(at x: CGFloat, time: Double, layer: Int) -> CGFloat {
        let amplitude = (layer == 0 ? 5.0 : 6.5) * waveScale
        let phase = layer == 0 ? 1.3 : 0.0
        let position = Double(x)
        let long = sin(position * 0.021 + time * 0.9 + phase)
        let short = sin(position * 0.043 - time * 1.4 + phase * 1.7)
        return CGFloat(amplitude * (long * 0.65 + short * 0.35))
    }

    private func wavePath(layer: Int, base: CGFloat, time: Double) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -20, y: -20))
        var x: CGFloat = -20
        while x <= size.width + 20 {
            path.addLine(to: CGPoint(x: x, y: base + waveHeight(at: x, time: time, layer: layer)))
            x += 10
        }
        path.addLine(to: CGPoint(x: size.width + 20, y: -20))
        path.closeSubpath()
        return path
    }

    private func moveWaves(time: Double) {
        backWave.path = wavePath(layer: 0, base: waterline + 5, time: time)
        frontWave.path = wavePath(layer: 1, base: waterline - 3, time: time)
    }

    private func moveBoat(time: Double) {
        let x = boat.position.x
        let lift = waveHeight(at: x, time: time, layer: 1)
        let ahead = waveHeight(at: x + 18, time: time, layer: 1)
        let behind = waveHeight(at: x - 18, time: time, layer: 1)
        boat.position.y = waterline - 1 + lift * 0.8
        boat.zRotation = atan((ahead - behind) / 36) * 0.7

        // The line runs from the rod's tip down into the deep.
        let tip = boat.convert(boat.rodTip, to: self)
        let depth = min(280, waterline * 0.5)
        let end = CGPoint(x: tip.x + CGFloat(sin(time * 0.6)) * 4, y: waterline - depth)
        let path = CGMutablePath()
        path.move(to: tip)
        path.addQuadCurve(to: end, control: CGPoint(x: tip.x + 3, y: (tip.y + end.y) / 2))
        line.path = path
        hook.position = end
    }

    private func moveFish(step: Double) {
        for swimmer in fish {
            var x = swimmer.node.position.x + swimmer.speed * CGFloat(step)
            if x > size.width + 60 {
                x = -60
            } else if x < -60 {
                x = size.width + 60
            }
            swimmer.node.position.x = x
        }
    }

    private func lightning(step: Double) {
        guard storminess > 0.7 else { return }
        flashCountdown -= step
        guard flashCountdown <= 0 else { return }
        flashCountdown = Double.random(in: 3 ... 9)
        flash.removeAllActions()
        flash.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.04),
            .fadeAlpha(to: 0.05, duration: 0.09),
            .fadeAlpha(to: 0.35, duration: 0.04),
            .fadeAlpha(to: 0.0, duration: 0.5)
        ]))
    }
}
