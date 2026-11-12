import SpriteKit
import UIKit
import MarinCore

/// The sea, in landscape, built from five depth layers that slide past at different speeds:
///
/// 1. Far background: sky, sun, moon, stars, clouds.
/// 2. Distant landscape: mountains.
/// 3. Coastal landscape: cliffs, waterfalls, arches, sea stacks, a village and lighthouse.
/// 4. Gameplay layer: Marin's boat and the sea around it.
/// 5. Foreground: the nearest waves and spray.
///
/// Layers 2 and 3 are assembled from parts by seeded rules, so the coast goes on for as far
/// as the boat sails and the same stretch always looks the same.
///
/// While sailing, only the surface of the sea is seen. Casting the line raises the view and
/// reveals what is under the water.
final class SeaScene: SKScene {
    private struct Cloud {
        let node: SKShapeNode
        let speed: CGFloat
        let width: CGFloat
    }

    /// One band of waves. Far bands are small and slow; near bands are large and fast.
    private struct Band {
        let node: SKShapeNode
        /// Height of the band's top edge, as a fraction of the screen height.
        let level: CGFloat
        let amplitude: Double
        let frequency: Double
        let parallax: Double
        let pace: Double
        let phase: Double
    }

    // MARK: - Controls

    /// True while the player is holding Sail.
    var wantsSail = false
    /// True while the line is in the water.
    var fishing = false
    /// Told whenever the part of the day changes.
    var onPhaseChange: ((DayPhase) -> Void)?

    // MARK: - State

    private let settings: SeaSettings
    private var built = false
    private var startTime: TimeInterval?
    private var lastTime: TimeInterval = 0
    private var lastPaint: TimeInterval = -100
    private let startHour: Double
    private var lastPhase: DayPhase?

    /// How far the boat has sailed, in points.
    private var worldX: Double
    private var speed = 0.0
    /// 0 while sailing, 1 once the line is down; eases between the two.
    private var fishAmount: Double

    private var cloudCover = 0.15
    private var rainAmount = 0.0
    private var storminess = 0.0
    private var waveScale = 1.0
    private var weatherReady = false
    private var flashCountdown = 2.0
    private var light = Light(tint: RGB(1, 1, 1), haze: RGB(1, 1, 1))

    // MARK: - Nodes

    /// Everything that moves up when the line is cast.
    private let world = SKNode()
    private let sky = SKSpriteNode()
    private let starLayer = SKNode()
    private let starTexture = Paint.softGlow(diameter: 32)
    private let sun = SKNode()
    private let moon = SKNode()
    private let cloudLayer = SKNode()
    private var clouds: [Cloud] = []
    private let mountainLayer = SKNode()
    private var mountainStretches: [Int: Scenery] = [:]
    private let coastLayer = SKNode()
    private var coastStretches: [Int: Scenery] = [:]
    private var farBands: [Band] = []
    private let nearLayer = SKNode()
    private var nearBands: [Band] = []
    private let glitter = SKSpriteNode(texture: Paint.softGlow())
    private let boat = BoatNode()
    private let spray = SKEmitterNode()
    private let underwaterLayer = SKNode()
    private let deep = SKSpriteNode()
    private let surface = SKShapeNode()
    private var underwater: Scenery?
    private var underwaterSpot: Int?
    private let line = SKShapeNode()
    private let hook = SKShapeNode(circleOfRadius: 2)
    private let rain = SKEmitterNode()
    private let flash = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
    private let grain = SKSpriteNode(texture: Paint.paperGrain())

    // MARK: - Measurements

    /// Everything is sized against a 390-point-tall screen.
    private var k: CGFloat { size.height / 390 }
    private var horizonY: CGFloat { size.height * 0.50 }
    private var boatLineY: CGFloat { size.height * 0.435 }
    /// How far the view rises when the line is cast.
    private var fishShift: CGFloat { size.height * 0.24 }
    /// How far below the bottom of the screen the water is drawn, so nothing shows through.
    private var floorY: CGFloat { -size.height * 0.27 }

    init(settings: SeaSettings) {
        self.settings = settings
        self.startHour = settings.hourOverride ?? SeaClock.hour(for: Date())
        self.worldX = settings.worldX
        self.fishAmount = settings.startFishing ? 1 : 0
        self.fishing = settings.startFishing
        super.init(size: CGSize(width: 844, height: 390))
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
        addChild(world)

        // Layer 1: far background.
        sky.anchorPoint = .zero
        sky.zPosition = 0
        world.addChild(sky)

        starLayer.zPosition = 1
        world.addChild(starLayer)

        buildDisc(in: sun, radius: 26, glow: 230, glowAlpha: 0.55,
                  colour: UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1))
        sun.zPosition = 2
        world.addChild(sun)

        buildDisc(in: moon, radius: 17, glow: 140, glowAlpha: 0.35,
                  colour: UIColor(red: 0.93, green: 0.94, blue: 0.98, alpha: 1))
        moon.zPosition = 2
        world.addChild(moon)

        cloudLayer.zPosition = 5
        world.addChild(cloudLayer)

        // Layer 2: distant landscape.
        mountainLayer.zPosition = 10
        world.addChild(mountainLayer)

        // Layer 3: coastal landscape.
        coastLayer.zPosition = 14
        world.addChild(coastLayer)

        // Layer 4: the sea out to the horizon, and the boat.
        farBands = [
            makeBand(level: 0.500, amplitude: 0.8, frequency: 0.060, parallax: 0.35, pace: 0.5, phase: 0.0, z: 20, in: world),
            makeBand(level: 0.480, amplitude: 1.4, frequency: 0.045, parallax: 0.50, pace: 0.6, phase: 1.1, z: 21, in: world),
            makeBand(level: 0.458, amplitude: 2.2, frequency: 0.034, parallax: 0.70, pace: 0.7, phase: 2.3, z: 22, in: world)
        ]

        boat.zPosition = 30
        world.addChild(boat)

        spray.particleTexture = Paint.softGlow(diameter: 16)
        spray.particleBirthRate = 0
        spray.particleLifetime = 0.7
        spray.particleLifetimeRange = 0.3
        spray.emissionAngle = .pi * 0.72
        spray.emissionAngleRange = 0.7
        spray.particleAlpha = 0.75
        spray.particleAlphaSpeed = -1.1
        spray.particleBlendMode = .alpha
        spray.zPosition = 32
        world.addChild(spray)

        // What lies under the water, hidden until the line is cast.
        underwaterLayer.zPosition = 36
        underwaterLayer.alpha = 0
        world.addChild(underwaterLayer)

        surface.strokeColor = UIColor(white: 1, alpha: 0.5)
        surface.lineWidth = 1.5
        surface.zPosition = 0
        underwaterLayer.addChild(surface)

        deep.anchorPoint = .zero
        deep.zPosition = 1
        underwaterLayer.addChild(deep)

        // Layer 5: foreground waves.
        nearLayer.zPosition = 40
        world.addChild(nearLayer)
        nearBands = [
            makeBand(level: 0.418, amplitude: 3.5, frequency: 0.024, parallax: 1.00, pace: 0.9, phase: 0.0, z: 0, in: nearLayer),
            makeBand(level: 0.350, amplitude: 5.0, frequency: 0.018, parallax: 1.25, pace: 1.0, phase: 1.7, z: 1, in: nearLayer),
            makeBand(level: 0.265, amplitude: 6.5, frequency: 0.013, parallax: 1.55, pace: 1.1, phase: 3.1, z: 2, in: nearLayer),
            makeBand(level: 0.160, amplitude: 8.0, frequency: 0.010, parallax: 1.90, pace: 1.2, phase: 4.4, z: 3, in: nearLayer)
        ]

        glitter.color = UIColor(red: 1.0, green: 0.90, blue: 0.70, alpha: 1)
        glitter.colorBlendFactor = 1
        glitter.blendMode = .add
        glitter.zPosition = 10
        nearLayer.addChild(glitter)

        line.strokeColor = UIColor(white: 1, alpha: 0.7)
        line.lineWidth = 1
        line.zPosition = 50
        world.addChild(line)

        hook.fillColor = UIColor(white: 1, alpha: 0.9)
        hook.strokeColor = .clear
        hook.zPosition = 50
        world.addChild(hook)

        // Fixed to the screen: rain, lightning, and the paper wash over everything.
        rain.particleTexture = Paint.raindrop()
        rain.particleBirthRate = 0
        rain.particleSpeed = 900
        rain.particleSpeedRange = 120
        rain.emissionAngle = -.pi / 2 - 0.18
        rain.particleRotation = -0.18
        rain.particleAlpha = 0.5
        rain.particleAlphaRange = 0.25
        rain.particleBlendMode = .alpha
        rain.zPosition = 80
        addChild(rain)

        flash.anchorPoint = .zero
        flash.alpha = 0
        flash.zPosition = 90
        addChild(flash)

        grain.anchorPoint = .zero
        grain.blendMode = .multiply
        grain.zPosition = 95
        addChild(grain)
    }

    private func makeBand(level: CGFloat, amplitude: Double, frequency: Double, parallax: Double,
                          pace: Double, phase: Double, z: CGFloat, in parent: SKNode) -> Band {
        let node = SKShapeNode()
        node.lineWidth = 1.2
        node.zPosition = z
        parent.addChild(node)
        return Band(node: node, level: level, amplitude: amplitude, frequency: frequency,
                    parallax: parallax, pace: pace, phase: phase)
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

        sky.position = CGPoint(x: 0, y: horizonY - 60 * k)
        sky.size = CGSize(width: width, height: height + 20 - (horizonY - 60 * k))

        mountainLayer.position.y = horizonY
        coastLayer.position.y = horizonY
        for scenery in mountainStretches.values { scenery.node.removeFromParent() }
        for scenery in coastStretches.values { scenery.node.removeFromParent() }
        mountainStretches = [:]
        coastStretches = [:]

        boat.setScale(1.9 * k)
        boat.position = CGPoint(x: width * 0.36, y: boatLineY)

        spray.particleSpeed = 70 * k
        spray.particleSpeedRange = 40 * k
        spray.yAcceleration = -220 * k
        spray.particleScale = 0.5 * k
        spray.particleScaleRange = 0.3 * k

        deep.position = CGPoint(x: 0, y: floorY)
        deep.size = CGSize(width: width, height: boatLineY - 14 * k - floorY)
        underwater?.node.removeFromParent()
        underwater = nil
        underwaterSpot = nil

        glitter.size = CGSize(width: 230 * k, height: boatLineY * 1.5)

        rain.position = CGPoint(x: width / 2 + 80, y: height + 20)
        rain.particlePositionRange = CGVector(dx: width * 1.5, dy: 0)
        rain.particleLifetime = (height - boatLineY + 30) / 900

        flash.position = .zero
        flash.size = size
        grain.position = .zero
        grain.size = size

        layoutStars()
        layoutClouds()
        lastPaint = -100
    }

    private func layoutStars() {
        starLayer.removeAllChildren()
        for _ in 0 ..< 120 {
            let side = CGFloat.random(in: 2.5 ... 6.0)
            let star = SKSpriteNode(texture: starTexture)
            star.size = CGSize(width: side, height: side)
            star.position = CGPoint(
                x: CGFloat.random(in: 0 ... size.width),
                y: horizonY + 16 + CGFloat.random(in: 0 ... 1) * (size.height - horizonY)
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
        let skyHeight = size.height - horizonY
        let count = 8
        for index in 0 ..< count {
            let width = CGFloat.random(in: 150 ... 300) * k
            let node = SKShapeNode(path: cloudPath(width: width))
            node.strokeColor = .clear
            node.lineWidth = 0
            let band = (CGFloat(index) + CGFloat.random(in: 0.2 ... 0.8)) / CGFloat(count)
            node.position = CGPoint(
                x: CGFloat.random(in: -40 ... size.width + 40),
                y: horizonY + skyHeight * (0.42 + 0.56 * band)
            )
            cloudLayer.addChild(node)
            clouds.append(Cloud(node: node, speed: CGFloat.random(in: 3 ... 9), width: width))
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
        sail(step: step)
        easeFishing(step: step)

        let paintEvery = settings.timeScale > 60 ? 0.08 : 0.5
        if currentTime - lastPaint > paintEvery {
            repaint(hour: hour, daylight: daylight)
            lastPaint = currentTime
        }

        moveSunAndMoon(hour: hour)
        moveClouds(step: step)
        refreshStretches()
        moveWaves(time: elapsed)
        moveBoat(time: elapsed)
        lightning(step: step)

        let phase = SeaClock.phase(atHour: hour)
        if phase != lastPhase {
            lastPhase = phase
            onPhaseChange?(phase)
        }
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

    /// Holding Sail builds up speed; letting go lets the boat glide to a stop.
    /// There is no limit on how far the boat may go.
    private func sail(step: Double) {
        let scale = Double(k)
        let top = (wantsSail && !fishing) ? 150 * scale : 0
        if speed < top {
            speed = min(top, speed + 130 * scale * step)
        } else {
            speed = max(top, speed - 170 * scale * step)
        }
        worldX += speed * step
        spray.particleBirthRate = CGFloat(speed / (150 * scale)) * 70
    }

    private func easeFishing(step: Double) {
        let goal = fishing ? 1.0 : 0.0
        fishAmount += (goal - fishAmount) * min(step * 3, 1)
        if abs(goal - fishAmount) < 0.002 {
            fishAmount = goal
        }

        if fishing {
            // Each spot along the sea has its own arrangement under the water.
            let spot = Int((worldX / (400 * Double(k))).rounded(.down))
            if underwaterSpot != spot {
                buildUnderwater(spot: spot)
            }
        }

        let amount = CGFloat(fishAmount)
        world.position.y = fishShift * amount
        nearLayer.alpha = 1 - amount
        nearLayer.isHidden = amount > 0.995
        underwaterLayer.alpha = amount
        underwaterLayer.isHidden = amount < 0.005
        let lineOut = amount > 0.04
        boat.setRodVisible(lineOut)
        line.isHidden = !lineOut
        hook.isHidden = !lineOut
    }

    private func buildUnderwater(spot: Int) {
        underwater?.node.removeFromParent()
        let seed = SeededRandom.mix(Coast.defaultSeed, 0xDEE9, UInt64(bitPattern: Int64(spot)))
        let scenery = SceneryBuilder.underwater(seed: seed, width: size.width,
                                                height: boatLineY - floorY, scale: k)
        scenery.node.position = CGPoint(x: 0, y: floorY)
        scenery.node.zPosition = 2
        scenery.apply(underwaterLight())
        underwaterLayer.addChild(scenery.node)
        underwater = scenery
        underwaterSpot = spot
    }

    private func underwaterLight() -> Light {
        Light(tint: light.tint, haze: light.haze)
    }

    /// Recolours the scene for the hour and the weather.
    private func repaint(hour: Double, daylight: Double) {
        let palette = Sky.palette(atHour: hour, storminess: storminess)

        sky.texture = Paint.verticalGradient(top: palette.skyTop, bottom: palette.horizon)
        deep.texture = Paint.verticalGradient(top: palette.waterTop, bottom: palette.waterDeep)
        surface.fillColor = palette.waterTop.uiColor

        // The sea is palest at the horizon and deepest in the foreground.
        let far = palette.waterTop.mixed(with: palette.horizon, t: 0.55)
        let near = palette.waterTop.mixed(with: palette.waterDeep, t: 0.45)
        let bands = farBands + nearBands
        let foam = UIColor(white: 1, alpha: CGFloat(0.10 + 0.28 * daylight))
        for (index, band) in bands.enumerated() {
            let t = Double(index) / Double(bands.count - 1)
            band.node.fillColor = far.mixed(with: near, t: t).uiColor
            band.node.strokeColor = foam
        }

        starLayer.alpha = CGFloat(palette.stars * (1 - cloudCover * 0.85))
        sun.alpha = CGFloat(1 - cloudCover * 0.8)
        moon.alpha = CGFloat(1 - cloudCover * 0.8)
        glitter.alpha = CGFloat(0.30 * daylight * (1 - cloudCover * 0.9))

        // The light on the land: white by day, blue by night, warm at dawn and dusk, grey in a storm.
        let warmth = 4 * daylight * (1 - daylight)
        var tint = RGB(0.30, 0.36, 0.62)
            .mixed(with: RGB(1, 1, 1), t: daylight)
            .mixed(with: palette.horizon, t: 0.30 * warmth)
        tint = tint.mixed(with: tint.grey, t: storminess * 0.6).scaled(1 - 0.25 * storminess)
        light = Light(tint: tint, haze: palette.horizon)

        for scenery in mountainStretches.values { scenery.apply(light) }
        for scenery in coastStretches.values { scenery.apply(light) }
        underwater?.apply(underwaterLight())

        let cloudBase = RGB(1.0, 0.93, 0.95).mixed(with: RGB(0.40, 0.42, 0.48), t: storminess)
        let cloudColour = cloudBase.multiplied(by: tint).mixed(with: palette.horizon, t: 0.22).uiColor
        let shown = cloudCover * Double(clouds.count) * 1.15
        for (index, cloud) in clouds.enumerated() {
            cloud.node.fillColor = cloudColour
            let visible = min(max(shown - Double(index), 0), 1)
            cloud.node.alpha = CGFloat(visible * 0.9)
        }

        boat.setLight(tint: tint, darkness: 1 - daylight)
        rain.particleBirthRate = CGFloat(rainAmount * 420)
    }

    private func moveSunAndMoon(hour: Double) {
        let skyHeight = size.height - horizonY
        func place(_ node: SKNode, along t: Double) {
            node.isHidden = t < -0.06 || t > 1.06
            node.position = CGPoint(
                x: size.width * CGFloat(0.10 + 0.80 * t),
                y: horizonY - 24 * k + CGFloat(sin(Double.pi * t)) * skyHeight * 0.80
            )
        }
        // The sun crosses from six in the morning to six in the evening; the moon takes the night.
        place(sun, along: (hour - 6) / 12)
        place(moon, along: SeaClock.normalized(hour + 6) / 12)
        glitter.position = CGPoint(x: sun.position.x, y: boatLineY * 0.55)
    }

    private func moveClouds(step: Double) {
        let wind = CGFloat(1 + storminess * 2.5)
        // Clouds drift on the wind and slide back a little as the boat sails on.
        let drift = CGFloat(step) - CGFloat(speed * step) * 0.04 / 6
        for cloud in clouds {
            var x = cloud.node.position.x + cloud.speed * wind * drift
            if x - cloud.width / 2 > size.width {
                x = -cloud.width / 2
            } else if x + cloud.width / 2 < 0 {
                x = size.width + cloud.width / 2
            }
            cloud.node.position.x = x
        }
    }

    // MARK: - The procedural coast

    /// Builds the stretches of mountains and coast that are in view and removes those left behind.
    private func refreshStretches() {
        let scale = Double(k)

        let mountainOffset = worldX * 0.08
        mountainLayer.position.x = CGFloat(-mountainOffset)
        mountainStretches = refreshed(mountainStretches, in: mountainLayer, offset: mountainOffset,
                                      stretchWidth: Coast.mountainStretchWidth * scale) { index in
            SceneryBuilder.mountains(Coast.mountains(stretch: index), scale: self.k)
        }

        let coastOffset = worldX * 0.25
        coastLayer.position.x = CGFloat(-coastOffset)
        coastStretches = refreshed(coastStretches, in: coastLayer, offset: coastOffset,
                                   stretchWidth: Coast.stretchWidth * scale) { index in
            SceneryBuilder.coast(Coast.features(stretch: index), scale: self.k)
        }
    }

    private func refreshed(_ current: [Int: Scenery], in layer: SKNode, offset: Double,
                           stretchWidth: Double, build: (Int) -> Scenery) -> [Int: Scenery] {
        let first = Int((offset / stretchWidth).rounded(.down)) - 1
        let last = Int(((offset + Double(size.width)) / stretchWidth).rounded(.down)) + 1
        var result: [Int: Scenery] = [:]
        for index in first ... last {
            if let existing = current[index] {
                result[index] = existing
            } else {
                let scenery = build(index)
                scenery.node.position.x = CGFloat(Double(index) * stretchWidth)
                scenery.apply(light)
                layer.addChild(scenery.node)
                result[index] = scenery
            }
        }
        for (index, scenery) in current where result[index] == nil {
            scenery.node.removeFromParent()
        }
        return result
    }

    // MARK: - Waves and the boat

    /// The height of a band's surface above its resting level at a point across the screen.
    private func waveHeight(_ band: Band, at x: CGFloat, time: Double) -> CGFloat {
        let scale = Double(k)
        let position = (Double(x) + worldX * band.parallax) / scale
        let long = sin(position * band.frequency + time * band.pace + band.phase)
        let short = sin(position * band.frequency * 2.1 - time * band.pace * 1.5 + band.phase * 1.7)
        return CGFloat(band.amplitude * scale * waveScale * (long * 0.65 + short * 0.35))
    }

    private func wavePath(_ band: Band, base: CGFloat, time: Double) -> CGPath {
        let path = CGMutablePath()
        let bottom = floorY - 20
        path.move(to: CGPoint(x: -20, y: bottom))
        var x: CGFloat = -20
        while x <= size.width + 20 {
            path.addLine(to: CGPoint(x: x, y: base + waveHeight(band, at: x, time: time)))
            x += 12
        }
        path.addLine(to: CGPoint(x: size.width + 20, y: bottom))
        path.closeSubpath()
        return path
    }

    private func moveWaves(time: Double) {
        for band in farBands {
            band.node.path = wavePath(band, base: size.height * band.level, time: time)
        }
        if !nearLayer.isHidden {
            for band in nearBands {
                band.node.path = wavePath(band, base: size.height * band.level, time: time)
            }
        }
        if !underwaterLayer.isHidden, let front = nearBands.first {
            surface.path = wavePath(front, base: boatLineY - 4 * k, time: time)
        }
    }

    private func moveBoat(time: Double) {
        guard let front = nearBands.first else { return }
        let x = boat.position.x
        let reach = 18 * k
        let lift = waveHeight(front, at: x, time: time)
        let ahead = waveHeight(front, at: x + reach, time: time)
        let behind = waveHeight(front, at: x - reach, time: time)
        boat.position.y = boatLineY + lift * 0.8
        // The boat rides the swell, and leans back a little when under way.
        let lean = CGFloat(speed / (150 * Double(k))) * 0.035
        boat.zRotation = atan((ahead - behind) / (reach * 2)) * 0.7 + lean

        spray.position = CGPoint(x: x + 44 * 1.9 * k, y: boat.position.y - 2 * k)

        // The line runs from the rod's tip down into the deep.
        let tip = boat.convert(boat.rodTip, to: world)
        let depth = size.height * 0.46 * CGFloat(fishAmount)
        let end = CGPoint(x: tip.x + CGFloat(sin(time * 0.6)) * 4, y: boatLineY - depth)
        let path = CGMutablePath()
        path.move(to: tip)
        path.addQuadCurve(to: end, control: CGPoint(x: tip.x + 3, y: (tip.y + end.y) / 2))
        line.path = path
        hook.position = end
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
