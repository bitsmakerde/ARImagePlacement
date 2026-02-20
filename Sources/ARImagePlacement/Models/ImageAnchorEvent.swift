//
//  ImageAnchorEvent.swift
//  ARImagePlacement
//
//  Events for image anchor lifecycle

import Foundation

/// Represents an image anchor lifecycle event
public enum ImageAnchorEvent: Sendable {
    case added(DetectedImage)
    case updated(DetectedImage)
    case removed(UUID)
}
