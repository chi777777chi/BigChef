import Foundation
import RealityKit
import UIKit

enum ARText {
    @discardableResult
    static func addLabel(
        text: String,
        to model: Entity,
        padding: Float = 0.02,
        color: UIColor = .white,
        maxWidthRatio: Float = 0.9,
        fontSize: CGFloat = 0.24,
        weight: UIFont.Weight = .semibold,
        boundingOverride: BoundingBox? = nil
    ) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.005,
            font: .systemFont(ofSize: fontSize, weight: weight),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let material = SimpleMaterial(color: color, isMetallic: false)
        let label = ModelEntity(mesh: mesh, materials: [material])

        let baseBounds = boundingOverride ?? model.visualBounds(relativeTo: model)
        let availableWidth = max(baseBounds.extents.x * maxWidthRatio, 0.05)

        let originalBounds = label.visualBounds(relativeTo: label)
        let width = max(originalBounds.extents.x, 0.001)
        let scaleFactor = Float(min(availableWidth / width, 1.0))
        label.scale = SIMD3<Float>(repeating: scaleFactor)

        let scaledBounds = label.visualBounds(relativeTo: label)
        let yPos = baseBounds.max.y + padding + scaledBounds.extents.y * 0.5
        let offsetX = -scaledBounds.center.x
        let offsetZ = -scaledBounds.center.z
        label.position = SIMD3<Float>(offsetX, yPos, offsetZ)
        label.components.set(BillboardComponent())

        model.addChild(label)
        return label
    }
}
