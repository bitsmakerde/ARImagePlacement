//
//  ImageTrackingManagerTests.swift
//  ARImagePlacementTests
//
//  Tests for image tracking manager

import XCTest
import RealityKit
import simd
@testable import ARImagePlacement

final class ImageTrackingManagerTests: XCTestCase {

    // MARK: - Mock Delegate

    final class MockDelegate: ImageTrackingDelegate {
        var detectedImages: [DetectedImage] = []
        var updatedImages: [DetectedImage] = []
        var removedIDs: [UUID] = []

        func imageTrackingManager(_ manager: ImageTrackingManager, didDetect image: DetectedImage) {
            detectedImages.append(image)
        }

        func imageTrackingManager(_ manager: ImageTrackingManager, didUpdate image: DetectedImage) {
            updatedImages.append(image)
        }

        func imageTrackingManager(_ manager: ImageTrackingManager, didRemove imageID: UUID) {
            removedIDs.append(imageID)
        }
    }

    // MARK: - Helper

    private func makeImage(
        id: UUID = UUID(),
        name: String? = "test",
        physicalWidth: Float = 0.1,
        physicalHeight: Float = 0.05,
        scaleFactor: Float = 1.0,
        transform: simd_float4x4 = simd_float4x4(1)
    ) -> DetectedImage {
        DetectedImage(
            id: id,
            name: name,
            physicalWidth: physicalWidth,
            physicalHeight: physicalHeight,
            scaleFactor: scaleFactor,
            transform: transform
        )
    }

    // MARK: - DetectedImage Model Tests

    func test_detectedImage_effectiveWidth() {
        let image = makeImage(physicalWidth: 0.1, scaleFactor: 2.0)
        XCTAssertEqual(image.effectiveWidth, 0.2, accuracy: 0.001)
    }

    func test_detectedImage_effectiveHeight() {
        let image = makeImage(physicalHeight: 0.05, scaleFactor: 3.0)
        XCTAssertEqual(image.effectiveHeight, 0.15, accuracy: 0.001)
    }

    func test_detectedImage_identifiable() {
        let id = UUID()
        let image = makeImage(id: id)
        XCTAssertEqual(image.id, id)
    }

    func test_detectedImage_name() {
        let image = makeImage(name: "QRCode")
        XCTAssertEqual(image.name, "QRCode")
    }

    func test_detectedImage_nilName() {
        let image = makeImage(name: nil)
        XCTAssertNil(image.name)
    }

    // MARK: - PlacementOffset Tests

    func test_placementOffset_zero() {
        let offset = PlacementOffset.zero
        XCTAssertEqual(offset.x, 0)
        XCTAssertEqual(offset.y, 0)
        XCTAssertEqual(offset.z, 0)
    }

    func test_placementOffset_equality() {
        let a = PlacementOffset(x: 1.2, y: 0, z: 0.4)
        let b = PlacementOffset(x: 1.2, y: 0, z: 0.4)
        XCTAssertEqual(a, b)
    }

    // MARK: - Target Transform Tests

    @MainActor
    func test_targetTransform_appliesOffset() {
        let config = ImageTrackingManager.Configuration(
            placementOffset: PlacementOffset(x: 1.2, y: 0, z: 0.4)
        )
        let sut = ImageTrackingManager(configuration: config)

        var baseTransform = simd_float4x4(1)
        baseTransform.columns.3 = SIMD4<Float>(5, 0, 3, 1)

        let image = makeImage(transform: baseTransform)
        let result = sut.targetTransform(for: image)

        XCTAssertEqual(result.columns.3.x, 6.2, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.y, 0.0, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.z, 3.4, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.w, 1.0, accuracy: 0.001)
    }

    @MainActor
    func test_targetTransform_zeroOffset_preservesTransform() {
        let config = ImageTrackingManager.Configuration(
            placementOffset: .zero
        )
        let sut = ImageTrackingManager(configuration: config)

        var baseTransform = simd_float4x4(1)
        baseTransform.columns.3 = SIMD4<Float>(2, 3, 4, 1)

        let image = makeImage(transform: baseTransform)
        let result = sut.targetTransform(for: image)

        XCTAssertEqual(result.columns.3.x, 2.0, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.y, 3.0, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.z, 4.0, accuracy: 0.001)
    }

    @MainActor
    func test_targetTransform_negativeOffset() {
        let config = ImageTrackingManager.Configuration(
            placementOffset: PlacementOffset(x: -1.0, y: -0.5, z: -2.0)
        )
        let sut = ImageTrackingManager(configuration: config)

        var baseTransform = simd_float4x4(1)
        baseTransform.columns.3 = SIMD4<Float>(5, 3, 4, 1)

        let image = makeImage(transform: baseTransform)
        let result = sut.targetTransform(for: image)

        XCTAssertEqual(result.columns.3.x, 4.0, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.y, 2.5, accuracy: 0.001)
        XCTAssertEqual(result.columns.3.z, 2.0, accuracy: 0.001)
    }

    // MARK: - HandleEvent Tests

    @MainActor
    func test_handleEvent_added_storesImage() {
        let sut = ImageTrackingManager()
        let image = makeImage()

        sut.handleEvent(.added(image))

        XCTAssertEqual(sut.detectedImages.count, 1)
        XCTAssertEqual(sut.detectedImages[image.id]?.name, "test")
    }

    @MainActor
    func test_handleEvent_added_notifiesDelegate() {
        let sut = ImageTrackingManager()
        let delegate = MockDelegate()
        sut.delegate = delegate

        let image = makeImage()
        sut.handleEvent(.added(image))

        XCTAssertEqual(delegate.detectedImages.count, 1)
        XCTAssertEqual(delegate.detectedImages.first?.id, image.id)
    }

    @MainActor
    func test_handleEvent_updated_updatesStoredImage() {
        let sut = ImageTrackingManager()
        let id = UUID()

        let image1 = makeImage(id: id, name: "first")
        sut.handleEvent(.added(image1))

        let image2 = makeImage(id: id, name: "second")
        sut.handleEvent(.updated(image2))

        XCTAssertEqual(sut.detectedImages[id]?.name, "second")
    }

    @MainActor
    func test_handleEvent_updated_notifiesDelegate() {
        let sut = ImageTrackingManager()
        let delegate = MockDelegate()
        sut.delegate = delegate

        let image = makeImage()
        sut.handleEvent(.added(image))
        sut.handleEvent(.updated(image))

        XCTAssertEqual(delegate.updatedImages.count, 1)
    }

    @MainActor
    func test_handleEvent_removed_removesImage() {
        let sut = ImageTrackingManager()
        let id = UUID()

        let image = makeImage(id: id)
        sut.handleEvent(.added(image))
        sut.handleEvent(.removed(id))

        XCTAssertTrue(sut.detectedImages.isEmpty)
    }

    @MainActor
    func test_handleEvent_removed_notifiesDelegate() {
        let sut = ImageTrackingManager()
        let delegate = MockDelegate()
        sut.delegate = delegate
        let id = UUID()

        let image = makeImage(id: id)
        sut.handleEvent(.added(image))
        sut.handleEvent(.removed(id))

        XCTAssertEqual(delegate.removedIDs, [id])
    }

    @MainActor
    func test_handleEvent_removed_unknownID_doesNotCrash() {
        let sut = ImageTrackingManager()
        sut.handleEvent(.removed(UUID()))
        XCTAssertTrue(sut.detectedImages.isEmpty)
    }

    // MARK: - Multiple Images

    @MainActor
    func test_multipleAdds_storesAll() {
        let sut = ImageTrackingManager()

        sut.handleEvent(.added(makeImage(name: "imageA")))
        sut.handleEvent(.added(makeImage(name: "imageB")))

        XCTAssertEqual(sut.detectedImages.count, 2)
    }

    // MARK: - Indicator Entity Tests

    @MainActor
    func test_createIndicatorEntity_hasModelComponent() {
        let sut = ImageTrackingManager()
        let image = makeImage(physicalWidth: 0.2, physicalHeight: 0.1, scaleFactor: 1.5)

        let entity = sut.createIndicatorEntity(for: image)

        XCTAssertNotNil(entity.components[ModelComponent.self])
    }

    @MainActor
    func test_createIndicatorEntity_hasTransform() {
        var transform = simd_float4x4(1)
        transform.columns.3 = SIMD4<Float>(1, 2, 3, 1)

        let sut = ImageTrackingManager()
        let image = makeImage(transform: transform)

        let entity = sut.createIndicatorEntity(for: image)

        // The entity should have a non-identity transform (rotated + positioned)
        XCTAssertNotEqual(entity.transform.matrix, simd_float4x4(1))
    }

    // MARK: - Configuration Tests

    @MainActor
    func test_defaultConfiguration() {
        let config = ImageTrackingManager.Configuration()
        XCTAssertEqual(config.placementOffset, .zero)
        XCTAssertTrue(config.createIndicatorEntity)
        XCTAssertNil(config.entityToPlaceName)
    }

    @MainActor
    func test_customConfiguration() {
        let config = ImageTrackingManager.Configuration(
            placementOffset: PlacementOffset(x: 1.2, y: 0, z: 0.4),
            createIndicatorEntity: false,
            entityToPlaceName: "car"
        )
        XCTAssertEqual(config.placementOffset.x, 1.2)
        XCTAssertEqual(config.placementOffset.z, 0.4)
        XCTAssertFalse(config.createIndicatorEntity)
        XCTAssertEqual(config.entityToPlaceName, "car")
    }

    // MARK: - ImageAnchorEvent Tests

    func test_imageAnchorEvent_added() {
        let image = makeImage()
        let event = ImageAnchorEvent.added(image)

        if case .added(let detectedImage) = event {
            XCTAssertEqual(detectedImage.id, image.id)
        } else {
            XCTFail("Expected .added event")
        }
    }

    func test_imageAnchorEvent_removed() {
        let id = UUID()
        let event = ImageAnchorEvent.removed(id)

        if case .removed(let removedID) = event {
            XCTAssertEqual(removedID, id)
        } else {
            XCTFail("Expected .removed event")
        }
    }
}
