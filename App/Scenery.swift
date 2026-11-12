import SpriteKit
import UIKit
import MarinCore

/// The light falling on the scenery at this hour.
struct Light {
    /// Multiplies every colour: white by day, blue at night, warm at dawn and dusk.
    var tint: RGB
    /// The colour distant things fade toward.
    var haze: RGB

    func colour(_ base: RGB, haze amount: Double) -> RGB {
        base.multiplied(by: tint).mixed(with: haze, t: amount)
    }
}

/// A group of drawn shapes that can be re-lit as the day changes.
///
/// Every piece of scenery is built from simple shapes here. This is placeholder artwork:
/// each builder is the place where a painted picture will later be put instead.
final class Scenery {
    let node = SKNode()
    private var shapes: [(node: SKShapeNode, colour: RGB, haze: Double)] = []

    @discardableResult
    func add(_ path: CGPath, _ colour: RGB, haze: Double = 0, z: CGFloat = 0,
             alpha: CGFloat = 1, to parent: SKNode? = nil) -> SKShapeNode {
        let shape = SKShapeNode(path: path)
        shape.strokeColor = .clear
        shape.lineWidth = 0
        shape.fillColor = colour.uiColor
        shape.zPosition = z
        shape.alpha = alpha
        (parent ?? node).addChild(shape)
        shapes.append((node: shape, colour: colour, haze: haze))
        return shape
    }

    func apply(_ light: Light) {
        for shape in shapes {
            shape.node.fillColor = light.colour(shape.colour, haze: shape.haze).uiColor
        }
    }
}

enum SceneryBuilder {
    private static let rock = RGB(0.52, 0.60, 0.86)
    private static let rockShade = RGB(0.43, 0.49, 0.79)
    private static let grass = RGB(0.56, 0.74, 0.58)
    private static let water = RGB(0.96, 0.98, 1.0)

    static func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    /// A fish facing right, about 36 points long.
    static func fishPath() -> CGPath {
        let tail = CGMutablePath()
        tail.move(to: CGPoint(x: -11, y: 0))
        tail.addLine(to: CGPoint(x: -22, y: 6))
        tail.addLine(to: CGPoint(x: -22, y: -6))
        tail.closeSubpath()
        return CGPath(ellipseIn: CGRect(x: -14, y: -5, width: 28, height: 10), transform: nil).union(tail)
    }

    // MARK: - The horizon

    /// The far mountains for one stretch. y = 0 is the horizon.
    static func mountains(_ features: [CoastFeature], scale k: CGFloat) -> Scenery {
        let scenery = Scenery()
        for feature in features {
            let x = CGFloat(feature.x) * k
            let w = CGFloat(feature.width) * k
            let h = CGFloat(feature.height) * k
            scenery.add(polygon([
                CGPoint(x: x - w / 2, y: -10),
                CGPoint(x: x - w * 0.20, y: h * 0.78),
                CGPoint(x: x, y: h),
                CGPoint(x: x + w * 0.22, y: h * 0.70),
                CGPoint(x: x + w / 2, y: -10)
            ]), RGB(0.68, 0.71, 0.93), haze: 0.5)
            scenery.add(polygon([
                CGPoint(x: x - w * 0.075, y: h * 0.92),
                CGPoint(x: x, y: h),
                CGPoint(x: x + w * 0.085, y: h * 0.885),
                CGPoint(x: x + w * 0.02, y: h * 0.90),
                CGPoint(x: x - w * 0.02, y: h * 0.875)
            ]), RGB(1, 1, 1), haze: 0.3, z: 1, alpha: 0.8)
        }
        return scenery
    }

    /// The coast for one stretch: cliffs, waterfalls, arches, sea stacks, a village. y = 0 is the horizon.
    static func coast(_ features: [CoastFeature], scale k: CGFloat) -> Scenery {
        let scenery = Scenery()
        for feature in features {
            switch feature.kind {
            case .cliff:
                cliff(feature, scenery, k)
            case .settlement:
                cliff(feature, scenery, k)
                village(feature, scenery, k)
            case .arch:
                arch(feature, scenery, k)
            case .stack:
                stack(feature, scenery, k)
            case .mountain:
                break
            }
        }
        return scenery
    }

    private static func cliff(_ feature: CoastFeature, _ scenery: Scenery, _ k: CGFloat) {
        var random = SeededRandom(seed: feature.detail)
        let w = CGFloat(feature.width) * k
        let h = CGFloat(feature.height) * k
        let left = CGFloat(feature.x) * k - w / 2
        let right = left + w
        let haze = 0.16

        var top: [CGPoint] = []
        let steps = 7
        for index in 0 ... steps {
            let t = CGFloat(index) / CGFloat(steps)
            let inset = w * 0.07
            top.append(CGPoint(x: left + inset + (w - inset * 2) * t,
                               y: h * CGFloat(random.range(0.87, 1.0))))
        }

        scenery.add(polygon([CGPoint(x: left, y: -10)] + top + [CGPoint(x: right, y: -10)]), rock, haze: haze)

        let split = steps / 2 + 1
        let shaded = [CGPoint(x: top[split].x - w * 0.05, y: -10)] + Array(top[split...]) + [CGPoint(x: right, y: -10)]
        scenery.add(polygon(shaded), rockShade, haze: haze, z: 1)

        let under = top.reversed().map { CGPoint(x: $0.x, y: $0.y - h * 0.11) }
        scenery.add(polygon(top + under), grass, haze: haze, z: 2)

        for fall in feature.waterfalls {
            let x = left + w * (0.16 + 0.68 * CGFloat(fall))
            let width = CGFloat(random.range(5, 9)) * k
            scenery.add(CGPath(rect: CGRect(x: x - width / 2, y: -8, width: width, height: h * 0.84 + 8), transform: nil),
                        water, haze: 0.05, z: 3, alpha: 0.9)
            scenery.add(CGPath(ellipseIn: CGRect(x: x - width * 2.2, y: -8, width: width * 4.4, height: 14 * k), transform: nil),
                        water, haze: 0.05, z: 4, alpha: 0.55)
        }
    }

    private static func village(_ feature: CoastFeature, _ scenery: Scenery, _ k: CGFloat) {
        var random = SeededRandom(seed: feature.detail ^ 0x51A7)
        let w = CGFloat(feature.width) * k
        let h = CGFloat(feature.height) * k
        let cx = CGFloat(feature.x) * k
        let ground = h * 0.93
        let haze = 0.12

        // A grassy rise for the houses to stand on.
        scenery.add(CGPath(ellipseIn: CGRect(x: cx - w * 0.38, y: h * 0.82, width: w * 0.76, height: h * 0.22), transform: nil),
                    grass, haze: haze, z: 5)

        let houses = random.whole(4, 6)
        var x = cx - w * 0.30
        for _ in 0 ..< houses {
            let width = CGFloat(random.range(12, 17)) * k
            let height = CGFloat(random.range(9, 14)) * k
            scenery.add(CGPath(rect: CGRect(x: x, y: ground, width: width, height: height), transform: nil),
                        RGB(0.98, 0.95, 0.88), haze: haze, z: 6)
            scenery.add(polygon([
                CGPoint(x: x - 1.5 * k, y: ground + height),
                CGPoint(x: x + width / 2, y: ground + height + 6 * k),
                CGPoint(x: x + width + 1.5 * k, y: ground + height)
            ]), RGB(0.85, 0.37, 0.34), haze: haze, z: 7)
            x += width + CGFloat(random.range(1, 5)) * k
        }

        // The lighthouse.
        let lx = cx + w * 0.29
        let tower = 34 * k
        scenery.add(polygon([
            CGPoint(x: lx - 4.5 * k, y: ground), CGPoint(x: lx - 3 * k, y: ground + tower),
            CGPoint(x: lx + 3 * k, y: ground + tower), CGPoint(x: lx + 4.5 * k, y: ground)
        ]), RGB(0.98, 0.97, 0.94), haze: haze, z: 6)
        scenery.add(CGPath(rect: CGRect(x: lx - 3.9 * k, y: ground + tower * 0.52, width: 7.8 * k, height: 5 * k), transform: nil),
                    RGB(0.85, 0.30, 0.30), haze: haze, z: 7)
        scenery.add(CGPath(rect: CGRect(x: lx - 3 * k, y: ground + tower, width: 6 * k, height: 5 * k), transform: nil),
                    RGB(0.98, 0.90, 0.60), haze: 0, z: 7)
        scenery.add(polygon([
            CGPoint(x: lx - 4.5 * k, y: ground + tower + 5 * k),
            CGPoint(x: lx, y: ground + tower + 10 * k),
            CGPoint(x: lx + 4.5 * k, y: ground + tower + 5 * k)
        ]), RGB(0.85, 0.30, 0.30), haze: haze, z: 7)
    }

    private static func arch(_ feature: CoastFeature, _ scenery: Scenery, _ k: CGFloat) {
        let w = CGFloat(feature.width) * k
        let h = CGFloat(feature.height) * k
        let left = CGFloat(feature.x) * k - w / 2
        let right = left + w
        let haze = 0.22

        let outer = polygon([
            CGPoint(x: left, y: -10),
            CGPoint(x: left + w * 0.08, y: h * 0.70),
            CGPoint(x: left + w * 0.25, y: h),
            CGPoint(x: right - w * 0.30, y: h * 0.95),
            CGPoint(x: right - w * 0.06, y: h * 0.60),
            CGPoint(x: right, y: -10)
        ])
        let hole = CGPath(ellipseIn: CGRect(x: left + w * 0.30, y: -h * 0.62, width: w * 0.44, height: h * 1.24), transform: nil)
        scenery.add(outer.subtracting(hole), rock, haze: haze)
        scenery.add(polygon([
            CGPoint(x: left + w * 0.19, y: h * 0.91),
            CGPoint(x: left + w * 0.25, y: h),
            CGPoint(x: right - w * 0.30, y: h * 0.95),
            CGPoint(x: right - w * 0.25, y: h * 0.86),
            CGPoint(x: left + w * 0.27, y: h * 0.90)
        ]), grass, haze: haze, z: 1)
    }

    private static func stack(_ feature: CoastFeature, _ scenery: Scenery, _ k: CGFloat) {
        let w = CGFloat(feature.width) * k
        let h = CGFloat(feature.height) * k
        let cx = CGFloat(feature.x) * k
        let haze = 0.20
        scenery.add(polygon([
            CGPoint(x: cx - w / 2, y: -10),
            CGPoint(x: cx - w * 0.32, y: h * 0.80),
            CGPoint(x: cx - w * 0.10, y: h),
            CGPoint(x: cx + w * 0.25, y: h * 0.90),
            CGPoint(x: cx + w / 2, y: -10)
        ]), rockShade, haze: haze)
        scenery.add(CGPath(ellipseIn: CGRect(x: cx - w * 0.30, y: h * 0.84, width: w * 0.55, height: h * 0.16), transform: nil),
                    grass, haze: haze, z: 1)
    }

    // MARK: - Under the water

    /// What is seen below the surface once the line is cast. The origin is the bottom-left corner.
    static func underwater(seed: UInt64, width: CGFloat, height: CGFloat, scale k: CGFloat) -> Scenery {
        var random = SeededRandom(seed: seed)
        let scenery = Scenery()

        // Shafts of light from the surface.
        for index in 0 ..< 5 {
            let x = width * (0.12 + 0.2 * CGFloat(index)) + CGFloat(random.range(-30, 30)) * k
            let top = CGFloat(random.range(26, 60)) * k
            scenery.add(polygon([
                CGPoint(x: x, y: height), CGPoint(x: x + top, y: height),
                CGPoint(x: x + top * 0.4 - 70 * k, y: height * 0.15), CGPoint(x: x - 90 * k, y: height * 0.15)
            ]), RGB(1, 1, 1), z: 1, alpha: 0.055)
        }

        // Large shadowy fish, far off.
        for _ in 0 ..< random.whole(1, 2) {
            let big = scenery.add(fishPath(), RGB(0.10, 0.14, 0.32), z: 2, alpha: 0.28)
            let size = CGFloat(random.range(3.2, 5.5)) * k
            let goingRight = random.unit() < 0.5
            big.xScale = goingRight ? size : -size
            big.yScale = size
            big.position = CGPoint(x: width * CGFloat(random.range(0.15, 0.85)),
                                   y: height * CGFloat(random.range(0.18, 0.45)))
            let drift = CGFloat(goingRight ? 60 : -60) * k
            big.run(.repeatForever(.sequence([
                .moveBy(x: drift, y: 0, duration: 16),
                .moveBy(x: -drift, y: 0, duration: 16)
            ])))
        }

        // Rocks on the sea floor.
        for side in [CGFloat(0.0), CGFloat(1.0)] {
            let base = width * side
            var rocks = CGPath(ellipseIn: CGRect(x: base - 150 * k, y: -50 * k, width: 300 * k,
                                                 height: CGFloat(random.range(110, 160)) * k), transform: nil)
            rocks = rocks.union(CGPath(ellipseIn: CGRect(
                x: base + (side == 0 ? 60 : -230) * k, y: -40 * k,
                width: 170 * k, height: CGFloat(random.range(70, 110)) * k), transform: nil))
            scenery.add(rocks, RGB(0.30, 0.27, 0.50), z: 4)
        }

        // Kelp, swaying.
        for _ in 0 ..< random.whole(4, 6) {
            let tall = height * CGFloat(random.range(0.40, 0.85))
            let amplitude = CGFloat(random.range(5, 11)) * k
            let phase = CGFloat(random.range(0, 6))
            var leftEdge: [CGPoint] = []
            var rightEdge: [CGPoint] = []
            let steps = 14
            for index in 0 ... steps {
                let t = CGFloat(index) / CGFloat(steps)
                let centre = sin(t * 7 + phase) * amplitude * t
                let half = (4.5 * (1 - t) + 1) * k
                leftEdge.append(CGPoint(x: centre - half, y: tall * t))
                rightEdge.append(CGPoint(x: centre + half, y: tall * t))
            }
            let kelp = scenery.add(polygon(leftEdge + rightEdge.reversed()), RGB(0.62, 0.68, 0.36), z: 5, alpha: 0.8)
            kelp.position = CGPoint(x: width * CGFloat(random.range(0.03, 0.97)), y: -4 * k)
            let sway = CGFloat(random.range(0.03, 0.06))
            let time = random.range(2.6, 4.4)
            kelp.zRotation = -sway
            let leanOver = SKAction.rotate(toAngle: sway, duration: time)
            leanOver.timingMode = .easeInEaseOut
            let leanBack = SKAction.rotate(toAngle: -sway, duration: time)
            leanBack.timingMode = .easeInEaseOut
            kelp.run(.repeatForever(.sequence([leanOver, leanBack])))
        }

        // Coral on the rocks.
        for side in [CGFloat(0.07), CGFloat(0.16), CGFloat(0.88), CGFloat(0.95)] {
            let root = CGPoint(x: width * side + CGFloat(random.range(-14, 14)) * k,
                               y: CGFloat(random.range(30, 62)) * k)
            let pink = RGB(0.96, 0.56, 0.72)
            for branch in 0 ..< 5 {
                let frond = scenery.add(CGPath(roundedRect: CGRect(x: -2.5 * k, y: 0, width: 5 * k,
                                                                    height: CGFloat(random.range(20, 40)) * k),
                                               cornerWidth: 2.4 * k, cornerHeight: 2.4 * k, transform: nil),
                                        pink, z: 6)
                frond.position = root
                frond.zRotation = (CGFloat(branch) - 2) * 0.32 + CGFloat(random.range(-0.08, 0.08))
            }
        }

        // A school of small fish.
        let school = SKNode()
        school.zPosition = 7
        school.position = CGPoint(x: width * CGFloat(random.range(0.55, 0.8)),
                                  y: height * CGFloat(random.range(0.5, 0.72)))
        scenery.node.addChild(school)
        for _ in 0 ..< random.whole(6, 9) {
            let small = scenery.add(fishPath(), RGB(0.78, 0.87, 0.96), z: 0, alpha: 0.85, to: school)
            small.setScale(CGFloat(random.range(0.55, 0.85)) * k)
            small.position = CGPoint(x: CGFloat(random.range(-70, 70)) * k, y: CGFloat(random.range(-26, 26)) * k)
        }
        school.run(.repeatForever(.sequence([
            .moveBy(x: 90 * k, y: 6 * k, duration: 11),
            .scaleX(to: -1, duration: 0.5),
            .moveBy(x: -90 * k, y: -6 * k, duration: 11),
            .scaleX(to: 1, duration: 0.5)
        ])))

        // Jellyfish, bobbing.
        for _ in 0 ..< random.whole(1, 3) {
            let jelly = SKNode()
            jelly.zPosition = 8
            jelly.position = CGPoint(x: width * CGFloat(random.range(0.08, 0.45)),
                                     y: height * CGFloat(random.range(0.35, 0.75)))
            scenery.node.addChild(jelly)
            let r = CGFloat(random.range(11, 18)) * k
            let colour = RGB(0.99, 0.74, 0.88)
            let dome = CGPath(ellipseIn: CGRect(x: -r, y: -r * 0.8, width: r * 2, height: r * 1.6), transform: nil)
                .intersection(CGPath(rect: CGRect(x: -r, y: 0, width: r * 2, height: r), transform: nil))
            scenery.add(dome, colour, z: 1, alpha: 0.8, to: jelly)
            for strand in 0 ..< 4 {
                let x = -r * 0.6 + r * 0.4 * CGFloat(strand)
                scenery.add(CGPath(rect: CGRect(x: x - 0.8 * k, y: -r * CGFloat(random.range(1.3, 2.1)),
                                                width: 1.6 * k, height: r * 2.1), transform: nil)
                                .intersection(CGPath(rect: CGRect(x: -r, y: -r * 3, width: r * 2, height: r * 3), transform: nil)),
                            colour, z: 0, alpha: 0.5, to: jelly)
            }
            let rise = SKAction.moveBy(x: 0, y: 9 * k, duration: random.range(2.2, 3.2))
            rise.timingMode = .easeInEaseOut
            jelly.run(.repeatForever(.sequence([rise, rise.reversed()])))
        }

        return scenery
    }
}
