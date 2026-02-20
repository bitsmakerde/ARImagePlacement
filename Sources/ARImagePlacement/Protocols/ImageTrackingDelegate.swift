//
//  ImageTrackingDelegate.swift
//  ARImagePlacement
//
//  Delegate protocol for image tracking events

import Foundation

/// Notified when image anchors are detected, updated, or removed
@MainActor
public protocol ImageTrackingDelegate: AnyObject {
    func imageTrackingManager(_ manager: ImageTrackingManager, didDetect image: DetectedImage)
    func imageTrackingManager(_ manager: ImageTrackingManager, didUpdate image: DetectedImage)
    func imageTrackingManager(_ manager: ImageTrackingManager, didRemove imageID: UUID)
}
