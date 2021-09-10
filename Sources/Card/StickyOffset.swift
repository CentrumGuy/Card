//
//  StickyOffset.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/1/20.
//

import Foundation
import UIKit

/// An offset on the screen that the card "sticks" to
public struct StickyOffset: Equatable {
    
    public static let zero = StickyOffset(distanceFromBottom: 0)
    
    private let distanceFromTop: CGFloat?
    private let distanceFromBottom: CGFloat?
    private let percent: CGFloat?
    
    /// Used to instantiate a Sitcky Offset from the top of the safe area
    /// - Parameter distanceFromTop: Distance in points from the top of the safe area
    public init (distanceFromTop: CGFloat) {
        self.distanceFromTop = distanceFromTop
        self.distanceFromBottom = nil
        self.percent = nil
    }
    
    /// Used to instantiate a Sitcky Offset from the bottom of the screen
    /// - Parameter distanceFromBottom: Distance in points from the bottom of the screen
    public init (distanceFromBottom: CGFloat) {
        self.distanceFromBottom = distanceFromBottom
        self.distanceFromTop = nil
        self.percent = nil
    }
    
    /// Used to instantiate a Sitcky Offset as a percentage of the screen
    /// - Parameter percent: Percent from 0 ... 1 where 0 is the bottom of the screen and 1 is the top of the screen
    public init (percent: CGFloat) {
        self.percent = percent
        self.distanceFromTop = nil
        self.distanceFromBottom = nil
    }
    
    /// Calculates the distance of the offset from the bottom of the screen given the total usable height
    /// - Parameter totalHeight: The total usable height
    /// - Returns: The distance from the bottom of the screen
    public func distanceFromBottom(_ totalHeight: CGFloat) -> CGFloat {
        if let distanceFromTop = distanceFromTop {
            return totalHeight - distanceFromTop
        } else if let distanceFromBottom = distanceFromBottom {
            return distanceFromBottom
        } else {
            return percent! * totalHeight
        }
    }
    
}


public struct AlphaCurve {
    
    /// Constant alpha value for the background. Will override all other alpha parameters
    public var overrideAlpha: CGFloat? = nil
    
    /// The offset that has the minimum background brightness (darkest background)
    public var offsetForMinBrightness: StickyOffset
    
    /// The offset that has the maximum background brightness (lightest background)
    public var offsetForMaxBrightness: StickyOffset
    
    /// The minimum alpha value for the background
    public var minAlpha: CGFloat = 0
    
    /// The maximum alpha value for the backgorund
    public var maxAlpha: CGFloat = 0.4
    
    /// A hard cap for the maximum alpha. The background will not go past this alpha value even if the user drags the card further up on the screen
    public var maxAlphaTopBound: CGFloat = 1
}
