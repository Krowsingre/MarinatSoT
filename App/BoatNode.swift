import SpriteKit
import UIKit
import MarinCore

/// Marin's boat, seen from the side: a small wooden sailboat with a patched sail and a lantern.
///
/// The boat is drawn around its own waterline: y = 0 is where the hull meets the sea.
/// This is placeholder artwork drawn in code, to be replaced by painted art.
final class BoatNode: SKNode {
    /// The end of the fishing rod, in the boat's own coordinates.
    let rodTip = CGPoint(x: 60, y: 50)

    private var parts: [(node: SKShapeNode, colour: RGB)] = []
    private let rod = SKShapeNode()
    private let lanternGlow = SKSpriteNode(texture: Paint.softGlow())
    private let lanternFlame = SKShapeNode(circleOfRadius: 2.2)

    override init() {
        super.init()
        build()
        setLight(tint: RGB(1, 1, 1), darkness: 0)
        setRodVisible(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BoatNode is only created in code")
    }

    /// Tints the boat for the time of day and brightens its lantern as it gets dark.
    func setLight(tint: RGB, darkness: Double) {
        for part in parts {
            part.node.fillColor = part.colour.multiplied(by: tint).uiColor
        }
        let dark = CGFloat(min(max(darkness, 0), 1))
        lanternGlow.alpha = 0.10 + 0.75 * dark
        lanternFlame.alpha = 0.6 + 0.4 * dark
    }

    /// The rod is only out while Marin is fishing.
    func setRodVisible(_ visible: Bool) {
        rod.isHidden = !visible
    }

    private func build() {
        let cream = RGB(0.97, 0.93, 0.82)
        let blue = RGB(0.36, 0.56, 0.86)
        let wood = RGB(0.56, 0.34, 0.25)
        let darkWood = RGB(0.34, 0.22, 0.16)

        // The sail, hanging from a slanted yard behind Marin.
        addPart(polygon([CGPoint(x: -40, y: 20), CGPoint(x: -36, y: 62), CGPoint(x: -5, y: 80), CGPoint(x: -5, y: 22)]),
                cream, z: 1)
        // A patch on the sail.
        addPart(CGPath(rect: CGRect(x: -17, y: 30, width: 7, height: 7), transform: nil),
                RGB(0.90, 0.84, 0.70), z: 2)
        // The fish painted on the sail.
        let fish = CGMutablePath()
        fish.move(to: CGPoint(x: -29, y: 57))
        fish.addLine(to: CGPoint(x: -34, y: 61))
        fish.addLine(to: CGPoint(x: -34, y: 53))
        fish.closeSubpath()
        addPart(CGPath(ellipseIn: CGRect(x: -31, y: 53, width: 17, height: 8), transform: nil).union(fish),
                blue, z: 2)
        // Two painted waves beneath the fish.
        addPart(CGPath(roundedRect: CGRect(x: -34, y: 44, width: 24, height: 2.4),
                       cornerWidth: 1.2, cornerHeight: 1.2, transform: nil), blue, z: 2)
        addPart(CGPath(roundedRect: CGRect(x: -36, y: 38, width: 22, height: 2.4),
                       cornerWidth: 1.2, cornerHeight: 1.2, transform: nil), blue, z: 2)

        // Mast, yard and the arm the lantern hangs from.
        addPart(CGPath(rect: CGRect(x: -6, y: 10, width: 3, height: 76), transform: nil), darkWood, z: 3)
        addPart(polygon([CGPoint(x: -38, y: 61), CGPoint(x: -37, y: 64), CGPoint(x: -3, y: 83), CGPoint(x: -3, y: 80)]),
                darkWood, z: 3)
        addPart(CGPath(rect: CGRect(x: -4, y: 76, width: 16, height: 2.4), transform: nil), darkWood, z: 3)

        // Lantern.
        addPart(CGPath(rect: CGRect(x: 9.4, y: 70, width: 1.2, height: 6), transform: nil), darkWood, z: 3)
        addPart(CGPath(roundedRect: CGRect(x: 6.5, y: 61, width: 7, height: 9.5),
                       cornerWidth: 1.5, cornerHeight: 1.5, transform: nil), RGB(0.36, 0.27, 0.16), z: 4)
        lanternGlow.size = CGSize(width: 64, height: 64)
        lanternGlow.position = CGPoint(x: 10, y: 65.5)
        lanternGlow.color = UIColor(red: 1.0, green: 0.78, blue: 0.42, alpha: 1)
        lanternGlow.colorBlendFactor = 1
        lanternGlow.blendMode = .add
        lanternGlow.zPosition = 9
        addChild(lanternGlow)
        lanternFlame.position = CGPoint(x: 10, y: 65.5)
        lanternFlame.fillColor = UIColor(red: 1.0, green: 0.86, blue: 0.55, alpha: 1)
        lanternFlame.strokeColor = .clear
        lanternFlame.zPosition = 10
        addChild(lanternFlame)

        // Cargo in the stern: a crate and a bedroll.
        addPart(CGPath(rect: CGRect(x: -32, y: 11, width: 20, height: 11), transform: nil),
                RGB(0.68, 0.50, 0.34), z: 4)
        addPart(CGPath(ellipseIn: CGRect(x: -30, y: 21, width: 16, height: 7), transform: nil),
                RGB(0.80, 0.78, 0.72), z: 4)

        // Marin: long dark curly hair blowing back, brown skin, a cream shawl with a blue band.
        let hair = RGB(0.13, 0.10, 0.09)
        for curl in [CGRect(x: 10.5, y: 28.5, width: 13, height: 13),
                     CGRect(x: 6, y: 26, width: 11, height: 11),
                     CGRect(x: 2.5, y: 22.5, width: 10, height: 10),
                     CGRect(x: 8, y: 21, width: 9, height: 9),
                     CGRect(x: 15, y: 34, width: 9, height: 8)] {
            addPart(CGPath(ellipseIn: curl, transform: nil), hair, z: 5)
        }
        addPart(CGPath(ellipseIn: CGRect(x: 15.5, y: 27.5, width: 11, height: 11), transform: nil),
                RGB(0.55, 0.36, 0.26), z: 6)
        addPart(polygon([CGPoint(x: 8, y: 11), CGPoint(x: 31, y: 11), CGPoint(x: 27, y: 28), CGPoint(x: 13, y: 28)]),
                RGB(0.94, 0.89, 0.77), z: 6)
        addPart(CGPath(rect: CGRect(x: 9.5, y: 15.5, width: 20.5, height: 3), transform: nil), blue, z: 7)

        // Fishing rod, out over the bow.
        let rodPath = CGMutablePath()
        rodPath.move(to: CGPoint(x: 28, y: 21))
        rodPath.addLine(to: rodTip)
        rod.path = rodPath
        rod.strokeColor = UIColor(red: 0.36, green: 0.25, blue: 0.16, alpha: 1)
        rod.lineWidth = 1.4
        rod.lineCap = .round
        rod.zPosition = 8
        addChild(rod)

        // Hull.
        let hull = CGMutablePath()
        hull.move(to: CGPoint(x: -46, y: 12))
        hull.addLine(to: CGPoint(x: 48, y: 14))
        hull.addQuadCurve(to: CGPoint(x: 30, y: -9), control: CGPoint(x: 43, y: -5))
        hull.addLine(to: CGPoint(x: -32, y: -9))
        hull.addQuadCurve(to: CGPoint(x: -46, y: 12), control: CGPoint(x: -43, y: -5))
        hull.closeSubpath()
        addPart(hull, wood, z: 11)
        addPart(polygon([CGPoint(x: -47, y: 10.5), CGPoint(x: -47, y: 13.5), CGPoint(x: 49, y: 15.5), CGPoint(x: 49, y: 12.5)]),
                RGB(0.74, 0.52, 0.36), z: 12)
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
