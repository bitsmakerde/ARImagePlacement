//
//  DetectedImage.swift
//  ARImagePlacement
//
//  Platform-agnostic representation of a detected AR image anchor

import Foundation
import simd

/// A detected image anchor with its physical properties and transform
public struct DetectedImage: Identifiable, Sendable {
    public let id: UUID
    public let name: String?
    public let physicalWidth: Float
    public let physicalHeight: Float
    public let scaleFactor: Float
    public let transform: simd_float4x4

    /// Physical width adjusted by estimated scale factor
    public var effectiveWidth: Float { physicalWidth * scaleFactor }

    /// Physical height adjusted by estimated scale factor
    public var effectiveHeight: Float { physicalHeight * scaleFactor }

    public init(
        id: UUID,
        name: String?,
        physicalWidth: Float,
        physicalHeight: Float,
        scaleFactor: Float,
        transform: simd_float4x4
    ) {
        self.id = id
        self.name = name
        self.physicalWidth = physicalWidth
        self.physicalHeight = physicalHeight
        self.scaleFactor = scaleFactor
        self.transform = transform
    }
}
