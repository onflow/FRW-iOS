//
//  BlobLayer.swift
//  BlobLayer
//
//  Created by João Gabriel Pozzobon dos Santos on 04/10/22.
//

import SwiftUI

/// A CALayer that draws a single blob on the screen
public class BlobLayer: CAGradientLayer {
    // MARK: Lifecycle

    init(color: Color) {
        super.init()

        type = .radial
        #if os(OSX)
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif

        // Set color
        set(color: color)

        // Center point
        let position = newPosition()
        startPoint = position

        // Radius
        let radius = newRadius()
        endPoint = position.displace(by: radius)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Required by the framework
    override public init(layer: Any) {
        super.init(layer: layer)
    }

    // MARK: Internal

    /// Generate a random point on the canvas
    func newPosition() -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 0.0...1.0),
            y: CGFloat.random(in: 0.0...1.0)
        ).capped()
    }

    /// Generate a random radius for the blob
    func newRadius() -> CGPoint {
        let size = CGFloat.random(in: 0.15...0.75)
        let viewRatio = frame.width / frame.height
        let safeRatio = max(viewRatio.isNaN ? 1 : viewRatio, 1)
        let ratio = safeRatio * CGFloat.random(in: 0.25...1.75)
        return CGPoint(
            x: size,
            y: size * ratio
        )
    }

    /// Animate the blob to a random point and size on screen at set speed
    func animate(speed: CGFloat) {
        guard speed > 0 else { return }

        removeAllAnimations()
        let currentLayer = presentation() ?? self

        let animation = CASpringAnimation()
        animation.mass = 10 / speed
        animation.damping = 50
        animation.duration = 1 / speed

        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards

        let position = newPosition()
        let radius = newRadius()

        // Center point
        let start = animation.copy() as! CASpringAnimation
        start.keyPath = "startPoint"
        start.fromValue = currentLayer.startPoint
        start.toValue = position

        // Radius
        let end = animation.copy() as! CASpringAnimation
        end.keyPath = "endPoint"
        end.fromValue = currentLayer.endPoint
        end.toValue = position.displace(by: radius)

        startPoint = position
        endPoint = position.displace(by: radius)

        // Opacity
        let value = Float.random(in: 0.5...1)
        let opacity = animation.copy() as! CASpringAnimation
        opacity.fromValue = self.opacity
        opacity.toValue = value

        self.opacity = value

        add(opacity, forKey: "opacity")
        add(start, forKey: "startPoint")
        add(end, forKey: "endPoint")
    }

    /// Set the color of the blob
    func set(color: Color) {
        // Converted to the system color so that cgColor isn't nil
        colors = [
            SystemColor(color).cgColor,
            SystemColor(color).cgColor,
            SystemColor(color.opacity(0.0)).cgColor,
        ]
        locations = [0.0, 0.9, 1.0]
    }
}
