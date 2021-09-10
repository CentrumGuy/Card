//
//  CardParent.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/1/20.
//

import Foundation
import UIKit

/// The protocol that the view controller presenting the card must implement
public protocol CardParent: CardListener {
    
    /// The card animator property accessible when there is a card being presented
    var cardAnimator: CardAnimator? { get set }
}

public extension CardParent where Self: UIViewController {
    
    /// Convenience method used to present a card
    /// - Parameters:
    ///   - cardController: The card controller to present. Should implement Card
    ///   - animated: Whether it should be animated
    func presentCard(_ cardController: UIViewController & Card, animated: Bool) {
        cardAnimator?.dismiss(animated: animated)
        self.cardAnimator = CardAnimator(parent: self, card: cardController)
        cardAnimator?.present(animated: animated)
    }
    
    /// Convenience method used to dismiss the currently presented card
    /// - Parameters:
    ///   - animated: Whether the dismissal should be animated
    ///   - completion: A completion handler which will run once the dismissal is complete
    func dismissCard(animated: Bool, completion: @escaping () -> () = {}) {
        cardAnimator?.dismiss(animated: animated, completion: completion)
    }
    
}
