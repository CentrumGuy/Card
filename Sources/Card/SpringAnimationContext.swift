//
//  SpringAnimationParameters.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/23/20.
//

import Foundation
import UIKit

/// A struct that holds information about the spring animation parameters. Allows animations and completions to be added to the spring animation
public struct SpringAnimationContext {
    
    /// The duration of the spring animation
    public let duration: TimeInterval
    
    /// The delay for the spring animation
    public let delay: TimeInterval
    
    /// The spring damping for the spring animation
    public let springDamping: CGFloat
    
    /// The initial spring velocity for the spring animation
    public let initialSpringVelocity: CGFloat
    
    /// Animation options for the spring animation
    public let options: UIView.AnimationOptions
    
    private var animations = [() -> Void]()
    private var completions = [(Bool) -> Void]()
    
    /// Creates a SpringAnimationContext given the parameters of a spring animation curve
    /// - Parameters:
    ///   - duration: The duration of the animation
    ///   - delay: The delay for the animation
    ///   - springDamping: The spring damping coefficient 1 is critically damped
    ///   - initialSpringVelocity: The initial spring velocity. For smooth start to the animation, match this value to the view’s velocity as it was prior to attachment. A value of 1 corresponds to the total animation distance traversed in one second. For example, if the total animation distance is 200 points and you want the start of the animation to match a view velocity of 100 pt/s, use a value of 0.5.
    ///   - options: A mask of options indicating how you want to perform the animations. For a list of valid constants, see UIView.AnimationOptions.
    ///   - animations: The animations to run
    ///   - completion: An optional completion block to run after the animations are over
    public init (duration: TimeInterval, delay: TimeInterval, springDamping: CGFloat, initialSpringVelocity: CGFloat, options: UIView.AnimationOptions, animations: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        self.duration = duration
        self.delay = delay
        self.springDamping = springDamping
        self.initialSpringVelocity = initialSpringVelocity
        self.options = options
        if let animations = animations { addAnimation(animation: animations) }
        if let completion = completion { addCompletion(completion: completion) }
    }
    
    /// Adds an animation to play along with the animation
    /// - Parameter animation: The animation to add
    public mutating func addAnimation(animation: @escaping () -> Void) {
        animations.append(animation)
    }
    
    /// Adds a completion handler to play after the animation is over
    /// - Parameter completion: The completion handler
    public mutating func addCompletion(completion: @escaping (Bool) -> Void) {
        completions.append(completion)
    }
    
    /// Runs the animation. For any SpringAnimationContexts that are instantiated by the CardAnimator, this will be called automatically
    public func animate() {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: springDamping, initialSpringVelocity: initialSpringVelocity, options: options) {
            animations.forEach { $0() }
        } completion: { (didFinish) in
            completions.forEach { $0(didFinish) }
        }
    }
}
