//
//  ImageTrackingManager.swift
//  ARImagePlacement
//
//  Manages image tracking, indicator creation, and entity placement

import Foundation
import RealityKit
import simd

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if os(visionOS)
import ARKit
#endif

/// Manages AR image tracking and positions entities relative to detected images.
@Observable
@MainActor
public final class ImageTrackingManager {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public var placementOffset: PlacementOffset
        public var createIndicatorEntity: Bool
        public var referenceImageGroupName: String?

        #if canImport(UIKit)
        public var indicatorColor: UIColor
        #elseif canImport(AppKit)
        public var indicatorColor: NSColor
        #endif

        public var entityToPlaceName: String?

        #if canImport(UIKit)
        public init(
            placementOffset: PlacementOffset = .zero,
            createIndicatorEntity: Bool = true,
            indicatorColor: UIColor = .red,
            entityToPlaceName: String? = nil,
            referenceImageGroupName: String? = nil
        ) {
            self.placementOffset = placementOffset
            self.createIndicatorEntity = createIndicatorEntity
            self.indicatorColor = indicatorColor
            self.entityToPlaceName = entityToPlaceName
            self.referenceImageGroupName = referenceImageGroupName
        }
        #elseif canImport(AppKit)
        public init(
            placementOffset: PlacementOffset = .zero,
            createIndicatorEntity: Bool = true,
            indicatorColor: NSColor = .red,
            entityToPlaceName: String? = nil,
            referenceImageGroupName: String? = nil
        ) {
            self.placementOffset = placementOffset
            self.createIndicatorEntity = createIndicatorEntity
            self.indicatorColor = indicatorColor
            self.entityToPlaceName = entityToPlaceName
            self.referenceImageGroupName = referenceImageGroupName
        }
        #endif
    }

    // MARK: - State

    public private(set) var detectedImages: [UUID: DetectedImage] = [:]
    public weak var delegate: (any ImageTrackingDelegate)?
    public var rootEntity: Entity?

    public let configuration: Configuration

    #if os(visionOS)
    /// The ARKit provider instance (managed internally)
    public private(set) var provider: ImageTrackingProvider?
    #endif

    // MARK: - Init

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: - Session Management

    #if os(visionOS)
    /// Start image tracking (creates and returns the provider for ARKitSession.run)
    public func startSession() -> ImageTrackingProvider {
        let referenceImages: [ReferenceImage]
        if let groupName = configuration.referenceImageGroupName {
            referenceImages = Array(ReferenceImage.loadReferenceImages(inGroupNamed: groupName))
        } else {
            referenceImages = []
        }

        let provider = ImageTrackingProvider(referenceImages: referenceImages)
        self.provider = provider
        return provider
    }

    /// Stop image tracking and cleanup
    public func stopSession() {
        provider = nil
        detectedImages.removeAll()
    }
    #endif

    // MARK: - visionOS: Process ARKit ImageTrackingProvider updates

    #if os(visionOS)
    public func processUpdates(from provider: ImageTrackingProvider?) async {
        guard let provider else { return }
        for await update in provider.anchorUpdates {
            let anchor = update.anchor
            let image = DetectedImage(from: anchor)

            switch update.event {
            case .added:
                handleEvent(.added(image))
            case .updated:
                handleEvent(.updated(image))
            case .removed:
                handleEvent(.removed(anchor.id))
            }
        }
    }

    /// Convenience method to process updates from the internally managed provider
    public func processUpdates() async {
        guard let provider else {
            print("Warning: ImageTrackingManager provider not started. Call startSession() first.")
            return
        }
        await processUpdates(from: provider)
    }
    #endif

    // MARK: - Testable API

    /// Process an image anchor event
    public func handleEvent(_ event: ImageAnchorEvent) {
        switch event {
        case .added(let image):
            detectedImages[image.id] = image

            // Create indicator entity if configured
            if configuration.createIndicatorEntity, let root = rootEntity {
                let indicator = createIndicatorEntity(for: image)
                root.addChild(indicator)
            }

            // Move named entity to target position if configured
            if let entityName = configuration.entityToPlaceName,
               let root = rootEntity,
               let entity = root.findEntity(named: entityName) {
                let target = targetTransform(for: image)
                entity.move(to: target, relativeTo: nil)
            }

            delegate?.imageTrackingManager(self, didDetect: image)

        case .updated(let image):
            detectedImages[image.id] = image
            delegate?.imageTrackingManager(self, didUpdate: image)

        case .removed(let id):
            detectedImages.removeValue(forKey: id)
            delegate?.imageTrackingManager(self, didRemove: id)
        }
    }

    // MARK: - Transform Calculation

    /// Calculate the target transform by applying the placement offset to the image transform
    public func targetTransform(for image: DetectedImage) -> simd_float4x4 {
        var result = image.transform
        result.columns.3.x += configuration.placementOffset.x
        result.columns.3.y += configuration.placementOffset.y
        result.columns.3.z += configuration.placementOffset.z
        return result
    }

    // MARK: - Indicator Entity

    /// Create a plane mesh entity representing the detected image
    public func createIndicatorEntity(for image: DetectedImage) -> Entity {
        let mesh = MeshResource.generatePlane(
            width: image.effectiveWidth,
            height: image.effectiveHeight
        )

        #if canImport(UIKit)
        let material = UnlitMaterial(color: configuration.indicatorColor)
        #elseif canImport(AppKit)
        let material = UnlitMaterial(color: configuration.indicatorColor)
        #endif

        let entity = ModelEntity(mesh: mesh, materials: [material])

        // Apply the image anchor transform with rotation to face upward
        var indicatorTransform = Transform(matrix: image.transform)
        let rotation = simd_quatf(angle: -1 * .pi / 2, axis: [1, 0, 0])
        indicatorTransform.rotation = rotation * indicatorTransform.rotation
        entity.transform = indicatorTransform

        return entity
    }
}

// MARK: - visionOS ARKit Conversion

#if os(visionOS)
extension DetectedImage {
    /// Create a DetectedImage from an ARKit ImageAnchor
    init(from anchor: ImageAnchor) {
        self.id = anchor.id
        self.name = anchor.referenceImage.name
        self.physicalWidth = Float(anchor.referenceImage.physicalSize.width)
        self.physicalHeight = Float(anchor.referenceImage.physicalSize.height)
        self.scaleFactor = anchor.estimatedScaleFactor
        self.transform = anchor.originFromAnchorTransform
    }
}
#endif
