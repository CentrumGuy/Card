//
//  Card.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/1/20.
//

import Foundation
import UIKit

public protocol Card: CardListener {
    
    /// The furthest view in the back of the card's view stack
    var backgroundView: UIView { get }
    
    /// The view containing the contents of the card. In most scenarios this is the background view but in some scenarios it isn't like when the background view is a UIVisualEffectView, it's the effectView's contentView property.
    var containerView: UIView { get }
    
    /// The current card animator which is presenting the Card controller
    var cardAnimator: CardAnimator? { get set }
    
    /// Should return the array of sticky offsets given a particular orientation of the device. The first offset should be the closest to the bottom of the screen and the last offset should be the closest to the top of the screen. It's better to use a constant array and return this array rather than create new offsets each time this method is called
    /// - Parameter orientation: The orientation of the device
    func stickyOffsets(forOrientation orientation: CardAnimator.CardOrientation) -> [StickyOffset]
    
    /// The default offset which the card sticks to upon presentation
    /// - Parameter orientation: The orientation of the device
    func defaultOffset(forOrientation orientation: CardAnimator.CardOrientation) -> StickyOffset
    
    /// The offset which the card will stick to and transition the card drag gesture to a scroll drag gesture
    /// - Parameter orientation: The orientation of the device
    func scrollOffset(forOrientation orientation: CardAnimator.CardOrientation) -> StickyOffset
    
    /// If you want the card to be inset by a particular amount from the screen edges, you can return these insets here
    /// - Parameter orientation: The orientation of the device
    func edgeInsets(forOrientation orientation: CardAnimator.CardOrientation) -> UIEdgeInsets
    
}

public extension Card {
    
    var backgroundView: UIView {
        guard let controller = self as? UIViewController else { fatalError("Failed to implement background view") }
        return controller.view
    }
    
    var containerView: UIView {
        if let backgroundView = backgroundView as? UIVisualEffectView { return backgroundView.contentView }
        return backgroundView
    }
    
    func defaultOffset(forOrientation orientation: CardAnimator.CardOrientation) -> StickyOffset {
        return stickyOffsets(forOrientation: orientation).first!
    }
    
    func scrollOffset(forOrientation orientation: CardAnimator.CardOrientation) -> StickyOffset {
        return stickyOffsets(forOrientation: orientation).last!
    }
    
    func edgeInsets(forOrientation orientation: CardAnimator.CardOrientation) -> UIEdgeInsets {
        return .zero
    }
    
    /// Convenience method used to dismiss the currently presented card
    /// - Parameters:
    ///   - animated: Whether the dismissal should be animated
    ///   - completion: A completion handler which will run once the dismissal is complete
    func dismissCard(animated: Bool, completion: @escaping () -> () = {}) {
        cardAnimator?.dismiss(animated: animated, completion: completion)
    }
    
}
