//
//  PlacementOffset.swift
//  ARImagePlacement
//
//  Configurable offset for placing entities relative to a detected image

import Foundation

/// Offset applied when positioning an entity relative to a detected image
public struct PlacementOffset: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float

    public static let zero = PlacementOffset(x: 0, y: 0, z: 0)

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}
