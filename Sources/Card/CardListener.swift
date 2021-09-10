//
//  CardDelegate.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/5/20.
//

import Foundation
import UIKit

public protocol CardListener: AnyObject {

    
    /// Called before the card changes orientation (compact vertical, compact horizontal, or regular)
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - newOrientation: The new orientation
    func cardAnimatorWillTransitionToNewOrientation(_ cardAnimator: CardAnimator, newOrientation: CardAnimator.CardOrientation)
    
    /// Called after the card changes orientation (compact vertical, compact horizontal, or regular)
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - newOrientation: The new orientation
    ///   - newOffset: The offset that the card will stick to
    func cardAnimatorDidTransitionToNewOrientation(_ cardAnimator: CardAnimator, newOrientation: CardAnimator.CardOrientation, newOffset: StickyOffset)
    
    /// Called before the card animator applies a new sticky offset
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - newOffset: The new offset that the card will stick to
    ///   - animationParameters: The spring animation parameters that the card will follow
    func cardAnimator(_ cardAnimator: CardAnimator, willApplyNewOffset newOffset: StickyOffset, withAnimationParameters animationParameters: inout SpringAnimationContext)
    
    /// Called every time the height of the card changes. This method should not take long to process since it is called very often (think of a pan gesture uptate)
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - newHeight: The new height that the card will have
    ///   - leftoverHeight: The leftover height from the top of the screen
    ///   - animationParameters: The spring animation parameters that the card will follow (if any exist)
    func cardAnimator(_ cardAnimator: CardAnimator, heightWillChange newHeight: CGFloat, leftoverHeight: CGFloat, animationParameters: SpringAnimationContext?)
    
    /// Called prior to the card setup. This should be the method used to set up the
    /// - Parameter cardAnimator: The card animator calling this method
    func cardAnimatorWillBeginSetup(_ cardAnimator: CardAnimator)
    
    /// Called prior to the card presentation on the screen
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - animationParameters: The spring animation parameters that the card will follow
    func cardAnimatorWillPresentCard(_ cardAnimator: CardAnimator, withAnimationParameters animationParameters: inout SpringAnimationContext)
    
    /// Called prior to the dismissal of a card. This is called before the animation begins
    /// - Parameters:
    ///   - cardAnimator: The card animator calling this method
    ///   - animationParameters: The spring animation parameters that the card will follow
    func cardAnimatorWillDismissCard(_ cardAnimator: CardAnimator, withAnimationParameters animationParameters: inout SpringAnimationContext)
    
}

public extension CardListener {
    
    func cardAnimatorWillTransitionToNewOrientation(_ cardAnimator: CardAnimator, newOrientation: CardAnimator.CardOrientation) {}
    func cardAnimatorDidTransitionToNewOrientation(_ cardAnimator: CardAnimator, newOrientation: CardAnimator.CardOrientation, newOffset: StickyOffset) {}
    func cardAnimator(_ cardAnimator: CardAnimator, willApplyNewOffset newOffset: StickyOffset, withAnimationParameters animationParameters: inout SpringAnimationContext) {}
    func cardAnimator(_ cardAnimator: CardAnimator, heightWillChange newHeight: CGFloat, leftoverHeight: CGFloat, animationParameters: SpringAnimationContext?) {}
    func cardAnimatorWillBeginSetup(_ cardAnimator: CardAnimator) {}
    func cardAnimatorWillPresentCard(_ cardAnimator: CardAnimator, withAnimationParameters animationParameters: inout SpringAnimationContext) {}
    func cardAnimatorWillDismissCard(_ cardAnimator: CardAnimator, withAnimationParameters animationParameters: inout SpringAnimationContext) {}
    
}
