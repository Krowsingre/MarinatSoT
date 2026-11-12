import SpriteKit
import UIKit
import MarinCore

extension RGB {
    var uiColor: UIColor {
        UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
    }
}

/// Small pictures drawn in code, so the game needs no artwork files yet.
enum Paint {
    /// A top-to-bottom blend between two colours.
    static func verticalGradient(top: RGB, bottom: RGB) -> SKTexture {
        let size = CGSize(width: 4, height: 256)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let colours = [top.uiColor.cgColor, bottom.uiColor.cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: colours, locations: [0, 1]) else { return }
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    /// A soft round glow, white in the middle and fading to nothing.
    static func softGlow(diameter: CGFloat = 128) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let colours = [
                UIColor(white: 1, alpha: 1).cgColor,
                UIColor(white: 1, alpha: 0.35).cgColor,
                UIColor(white: 1, alpha: 0).cgColor
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: colours, locations: [0, 0.35, 1]) else { return }
            let centre = CGPoint(x: diameter / 2, y: diameter / 2)
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: centre,
                startRadius: 0,
                endCenter: centre,
                endRadius: diameter / 2,
                options: []
            )
        }
        return SKTexture(image: image)
    }

    /// A soft mottled wash, laid over the whole picture to give it the unevenness of paint on paper.
    static func paperGrain() -> SKTexture {
        let columns = 96
        let rows = 54
        let size = CGSize(width: columns, height: rows)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        var random = SeededRandom(seed: 0x9A9E_4)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            for row in 0 ..< rows {
                for column in 0 ..< columns {
                    let shade = CGFloat(random.range(0.95, 1.0))
                    UIColor(white: shade, alpha: 1).setFill()
                    context.fill(CGRect(x: column, y: row, width: 1, height: 1))
                }
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    /// One streak of rain.
    static func raindrop() -> SKTexture {
        let size = CGSize(width: 2, height: 16)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(white: 1, alpha: 0.75).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
}
