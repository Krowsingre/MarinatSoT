import SpriteKit
import UIKit

/// A bottle with a letter inside, drifting under the water. Placeholder artwork drawn in code.
final class BottleNode: SKNode {
    override init() {
        super.init()
        build()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BottleNode is only created in code")
    }

    private func build() {
        // A soft glint so the bottle can be seen in dark water.
        let glint = SKSpriteNode(texture: Paint.softGlow())
        glint.size = CGSize(width: 54, height: 54)
        glint.color = UIColor(red: 0.85, green: 1.0, blue: 0.92, alpha: 1)
        glint.colorBlendFactor = 1
        glint.blendMode = .add
        glint.alpha = 0.35
        glint.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.6, duration: 1.1),
            .fadeAlpha(to: 0.3, duration: 1.1)
        ])))
        addChild(glint)

        let glass = UIColor(red: 0.62, green: 0.86, blue: 0.76, alpha: 0.9)
        add(CGPath(roundedRect: CGRect(x: -6, y: -14, width: 12, height: 23),
                   cornerWidth: 4, cornerHeight: 4, transform: nil), glass, z: 1)
        add(CGPath(rect: CGRect(x: -2.5, y: 8, width: 5, height: 7), transform: nil), glass, z: 1)
        // The rolled letter inside.
        add(CGPath(roundedRect: CGRect(x: -3, y: -10, width: 6, height: 14),
                   cornerWidth: 1.5, cornerHeight: 1.5, transform: nil),
            UIColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1), z: 2)
        // The cork.
        add(CGPath(rect: CGRect(x: -3, y: 14, width: 6, height: 4.5), transform: nil),
            UIColor(red: 0.62, green: 0.44, blue: 0.28, alpha: 1), z: 2)

        zRotation = 0.5
    }

    private func add(_ path: CGPath, _ colour: UIColor, z: CGFloat) {
        let shape = SKShapeNode(path: path)
        shape.fillColor = colour
        shape.strokeColor = .clear
        shape.lineWidth = 0
        shape.zPosition = z
        addChild(shape)
    }
}
