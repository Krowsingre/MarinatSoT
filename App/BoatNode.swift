import SpriteKit
import UIKit
import MarinCore

/// Marin's boat, seen from the side, with Marin aboard holding her rod.
///
/// The boat is drawn around its own waterline: y = 0 is where the hull meets the sea.
final class BoatNode: SKNode {
    /// The end of the fishing rod, in the boat's own coordinates.
    let rodTip = CGPoint(x: 50, y: 42)

    private var parts: [(node: SKShapeNode, colour: RGB)] = []
    private let lanternGlow = SKSpriteNode(texture: Paint.softGlow())
    private let lanternFlame = SKShapeNode(circleOfRadius: 2.5)

    override init() {
        super.init()
        build()
        setLight(1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BoatNode is only created in code")
    }

    /// Dims the boat as daylight fades and brightens its lantern. `daylight` is 0 ... 1.
    func setLight(_ daylight: Double) {
        let brightness = 0.32 + 0.68 * daylight
        for part in parts {
            part.node.fillColor = part.colour.scaled(brightness).uiColor
        }
        let dark = CGFloat(1 - daylight)
        lanternGlow.alpha = 0.08 + 0.72 * dark
        lanternFlame.alpha = 0.5 + 0.5 * dark
    }

    private func build() {
        // Jib, the small sail toward the stern side of the mast.
        addPart(polygon([CGPoint(x: -5, y: 18), CGPoint(x: -5, y: 60), CGPoint(x: -30, y: 18)]),
                RGB(0.90, 0.87, 0.79), z: 1)
        // Main sail.
        addPart(polygon([CGPoint(x: 2, y: 18), CGPoint(x: 2, y: 74), CGPoint(x: 34, y: 18)]),
                RGB(0.96, 0.93, 0.85), z: 1)
        // Mast.
        addPart(CGPath(rect: CGRect(x: -3, y: 10, width: 3, height: 68), transform: nil),
                RGB(0.30, 0.20, 0.14), z: 2)

        // Marin: hair, head, coat.
        addPart(CGPath(ellipseIn: CGRect(x: 14.5, y: 25, width: 11.5, height: 11.5), transform: nil),
                RGB(0.24, 0.15, 0.10), z: 3)
        addPart(CGPath(ellipseIn: CGRect(x: 17, y: 24.5, width: 9.5, height: 9.5), transform: nil),
                RGB(0.94, 0.79, 0.67), z: 4)
        addPart(CGPath(roundedRect: CGRect(x: 15, y: 11, width: 11, height: 14),
                       cornerWidth: 4, cornerHeight: 4, transform: nil),
                RGB(0.80, 0.30, 0.26), z: 4)

        // Fishing rod, from Marin's hands out over the bow.
        let rod = SKShapeNode()
        let rodPath = CGMutablePath()
        rodPath.move(to: CGPoint(x: 25, y: 19))
        rodPath.addLine(to: rodTip)
        rod.path = rodPath
        rod.strokeColor = UIColor(red: 0.36, green: 0.25, blue: 0.16, alpha: 1)
        rod.lineWidth = 1.6
        rod.lineCap = .round
        rod.zPosition = 5
        addChild(rod)

        // Hull.
        let hull = CGMutablePath()
        hull.move(to: CGPoint(x: -40, y: 12))
        hull.addLine(to: CGPoint(x: 44, y: 12))
        hull.addQuadCurve(to: CGPoint(x: 26, y: -9), control: CGPoint(x: 38, y: -5))
        hull.addLine(to: CGPoint(x: -28, y: -9))
        hull.addQuadCurve(to: CGPoint(x: -40, y: 12), control: CGPoint(x: -38, y: -5))
        hull.closeSubpath()
        addPart(hull, RGB(0.45, 0.28, 0.18), z: 6)

        // A lighter rail along the top of the hull.
        addPart(CGPath(roundedRect: CGRect(x: -41, y: 10, width: 86, height: 3.5),
                       cornerWidth: 1.5, cornerHeight: 1.5, transform: nil),
                RGB(0.66, 0.46, 0.30), z: 7)

        // Lantern at the stern.
        lanternGlow.size = CGSize(width: 70, height: 70)
        lanternGlow.position = CGPoint(x: -34, y: 21)
        lanternGlow.color = UIColor(red: 1.0, green: 0.78, blue: 0.42, alpha: 1)
        lanternGlow.colorBlendFactor = 1
        lanternGlow.blendMode = .add
        lanternGlow.zPosition = 8
        addChild(lanternGlow)

        lanternFlame.position = CGPoint(x: -34, y: 21)
        lanternFlame.fillColor = UIColor(red: 1.0, green: 0.86, blue: 0.55, alpha: 1)
        lanternFlame.strokeColor = .clear
        lanternFlame.zPosition = 9
        addChild(lanternFlame)
    }

    private func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    private func addPart(_ path: CGPath, _ colour: RGB, z: CGFloat) {
        let node = SKShapeNode(path: path)
        node.strokeColor = .clear
        node.lineWidth = 0
        node.fillColor = colour.uiColor
        node.zPosition = z
        addChild(node)
        parts.append((node: node, colour: colour))
    }
}
