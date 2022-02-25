//
//  CardAnimator.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/1/20.
//

import Foundation
import UIKit

/// Controls various aspects of the CardAnimator but is not required
@objc public protocol CardDelegate {
    
    /// Asks the delegate whether the card animator should handle a particular scroll view
    /// - Parameters:
    ///   - cardAnimator: The card animator asking the delegate
    ///   - scrollView: The scroll view that should/shouldn't be handled
    @objc optional func cardAnimator(_ cardAnimator: CardAnimator, shouldHandleScrollView scrollView: UIScrollView) -> Bool
    
    /// Asks the delgate whether the card should be dismissed on drag down
    /// - Parameter cardAnimator: The card animator asking the delegate
    @objc optional func cardAnimatorShouldDismissOnDragDown(_ cardAnimator: CardAnimator) -> Bool
    
    /// Asks the delgate whether the card should be dismissed upon the background tap
    /// - Parameter cardAnimator: The card animator asking the delegate
    @objc optional func cardAnimatorShouldDismissOnBackgroundTap(_ cardAnimator: CardAnimator) -> Bool
}

/// Class used to handle interactions between the Card and CardParent
public class CardAnimator: NSObject {
    
    /// Describes the orientation of the phone and the various types of card layout types
    public enum CardOrientation {
        /// When the screen is wide and short
        case compactVertical
        
        /// The default card layout. When the screen is narrow and tall
        case compactHorizontal
        
        /// A big screen. Mostly used for iPads
        case regular
    }
    
    private static let MAX_BOUNDARY_OFFSET: CGFloat = 64
    private static let MIN_BOUNDARY_OFFSET: CGFloat = 128
    private static let ANIMATION_OPTIONS = UIView.AnimationOptions.init(arrayLiteral: .allowUserInteraction, .beginFromCurrentState)
    
    fileprivate lazy var _panGesture = CardPanGesture(target: self, action: #selector(didPan(_:)))
    private lazy var scrollHandler = ScrollHandler(cardAnimator: self)
    private weak var _parent: (UIViewController & CardParent)?
    private weak var _card: (UIViewController & Card)?
    private var _cornerRadius: CGFloat = 12
    private var _presented = false
    private var pulltabTopConstraint: NSLayoutConstraint!
    private var compactVerticalConstraints = [NSLayoutConstraint]()
    private var compactHorizontalConstraints = [NSLayoutConstraint]()
    private var regularConstraints = [NSLayoutConstraint]()
    private let listeners = WeakSet<CardListener>()
    private let boundaryCurve = AsymptotalCurve(degree: 1)
    private let bottomConstraint: NSLayoutConstraint
    private let cardHeightConstraint: NSLayoutConstraint
    
    fileprivate var scrollConstant: CGFloat {
        return card?.scrollOffset(forOrientation: orientation).distanceFromBottom(safeAreaHeight) ?? .zero
    }
    
    fileprivate var maxConstant: CGFloat {
        return maxOffset.distanceFromBottom(safeAreaHeight)
    }
    
    private var minConstant: CGFloat {
        return minOffset.distanceFromBottom(safeAreaHeight)
    }

    private var constant: CGFloat {
        set { bottomConstraint.constant = newValue }
        get { return bottomConstraint.constant }
    }
    
    private var _pullTabTopDistance: CGFloat = 6 {
        didSet { pulltabTopConstraint?.constant = _pullTabTopDistance }
    }
    
    private let _pullTab: PullTab = {
        let pullTab = PullTab(frame: CGRect(x: 0, y: 0, width: 35, height: 10))
        pullTab.translatesAutoresizingMaskIntoConstraints = false
        pullTab.lineWidth = 5
        if #available(iOS 13.0, *) { pullTab.lineColor = UIColor.systemFill }
        else { pullTab.lineColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3481913527) }
        pullTab.isHidden = true
        return pullTab
    }()
    
    /// The delegate for the the CardAnimator. This is not a weak variable so the delegate should only maintain weak references to the CardAnimator.
    public var delegate: CardDelegate?
    
    /// Whether the card should be dismissed upon drag down
    public var dismissesOnDragDown = false
    
    /// Whether the card should be dismissed upon the background tap
    public var dismissesOnBackgroundTap = true
    
    /// Whether the pull tab should be animated alongside the card
    public var shouldAnimatePullTab = true
    
    /// Whether drags in scrollviews should be handled. This works well 99% of the time
    public var shouldHandleScrollViews = true {
        didSet { scrollHandler.isEnabled = shouldHandleScrollViews }
    }
    
    /// Whether landscape and wide screens should be conformed to by using a slimmer side card
    public var conformsToWideScreen = true {
        didSet { configureToNewOrientation() }
    }
    
    /// Whether there should be a pull tab at the top of the card
    public var pullTabEnabled: Bool {
        set { pullTab.isHidden = !newValue }
        get { return !pullTab.isHidden }
    }
    
    /// The distance between the top of the card and the pull tab if a pull tab exists
    public var pullTabTopDistance: CGFloat {
        set { self._pullTabTopDistance = newValue }
        get { return _pullTabTopDistance }
    }
    
    /// The corner radius of the card
    public var cornerRadius: CGFloat {
        set {
            self._cornerRadius = newValue
            updateCornerRadius()
        }
        get { _cornerRadius }
    }
    
    /// The dark dismiss button in the background of the card
    public var dismissButton: UIButton? = {
        let button = UIButton()
        button.backgroundColor = .black
        button.alpha = 0
        return button
    }()
    
    /// The alpha curve responsible for handling changes to the dismiss button's alpha value as the card is being dragged
    public var alphaCurve: AlphaCurve
    
    /// The parent controller presenting the card
    public var parent: (UIViewController & CardParent)? { return _parent }
    
    /// The card controller being presented
    public var card: (UIViewController & Card)? { return _card }
    
    /// The view of the parent controller
    public var parentView: UIView? { return parent?.view }
    
    /// The view of the card controller
    public var cardView: UIView? { return card?.view }
    
    /// The card controller's background view. This should be the view that is the furthest back on the card controller's view heirarchy
    public var backgroundView: UIView? { return card?.backgroundView }
    
    /// The pull tab at the top of the card
    public var pullTab: PullTab { return _pullTab }
    
    /// The current set of sticky offsets that are being used to handle where the card "sticks" to
    public var stickyOffsets: [StickyOffset] { return card?.stickyOffsets(forOrientation: orientation) ?? [.zero] }
    
    /// The offset that is responsible for showing the most of the card
    public var maxOffset: StickyOffset { return stickyOffsets.last! }
    
    /// The offset that is responsible for showing the least of the card
    public var minOffset: StickyOffset { return stickyOffsets.first! }
    
    /// The offset that the card sticks to after it's being presented
    public var defaultOffset: StickyOffset { return card?.defaultOffset(forOrientation: orientation) ?? .zero }
    
    /// Whether the card has been presented
    public var presented: Bool { return _presented }
    
    /// The current height of the card
    public var height: CGFloat { return constant }
    
    /// The pan gesture associated with dragging the card
    public var panGesture: UIPanGestureRecognizer { return _panGesture }
    
    /// Returns the height of the entire safe area
    public var safeAreaHeight: CGFloat { return parentView?.safeAreaLayoutGuide.layoutFrame.height ?? 0 }
    
    /// Gets the current orientation of the card animator
    public var orientation: CardOrientation {
        guard let parent = parent else { return .compactVertical }
        let horizontalSizeClass = parent.traitCollection.horizontalSizeClass
        let verticalSizeClass = parent.traitCollection.verticalSizeClass
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return .regular
        } else if verticalSizeClass == .regular {
            return .compactHorizontal
        } else {
            return .compactVertical
        }
    }
    
    /// Instantiate a new CardAnimator
    /// - Parameters:
    ///   - parent: The parent (presenting) controller. Must implement CardParent
    ///   - card: The card (presented) controller. Musit implement Card
    public init (parent: UIViewController & CardParent, card: UIViewController & Card) {
        self._parent = parent
        self._card = card
        self.bottomConstraint = parent.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: card.backgroundView.topAnchor, constant: 0)
        self.cardHeightConstraint = NSLayoutConstraint(item: card.view!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        self.alphaCurve = AlphaCurve(offsetForMinBrightness: card.stickyOffsets(forOrientation: .compactHorizontal).last!, offsetForMaxBrightness: card.stickyOffsets(forOrientation: .compactHorizontal).first!)
        super.init()
        
        parentView?.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        card.cardAnimator = self
        
        card.backgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.view.clipsToBounds = true
        
        addListener(parent)
        addListener(card)
        
        scrollHandler.setup()
    }
    
    private func addChild() {
        guard !presented, let parent = parent, let parentView = parentView, let card = card, let cardView = cardView, let backgroundView = backgroundView else { return }
        if !card.containerView.isDescendant(of: backgroundView) { fatalError("The container view of a card controller must be a descendant of backgroundView") }
        
        // 1: Add Child
        var traits = [UITraitCollection(horizontalSizeClass: .compact)]
        if #available(iOS 13.0, *) { traits.append(UITraitCollection(userInterfaceLevel: .elevated)) }
        let newTraitCollection = UITraitCollection(traitsFrom: traits)
        parent.addChild(card)
        parent.setOverrideTraitCollection(newTraitCollection, forChild: card)
        
        // 2: Add Subview And Set Constraints
        cardView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        if let dismissButton = dismissButton {
            dismissButton.translatesAutoresizingMaskIntoConstraints = false
            parentView.addSubview(dismissButton)
            var dismissButtonConstraints = [NSLayoutConstraint]()
            dismissButtonConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[dismissButton]|", options: [], metrics: nil, views: ["dismissButton": dismissButton])
            dismissButtonConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[dismissButton]|", options: [], metrics: nil, views: ["dismissButton": dismissButton])
            parentView.addConstraints(dismissButtonConstraints)
            dismissButton.addTarget(self, action: #selector(dismissButtonClicked), for: .touchUpInside)
        }
        
        if !cardView.isDescendant(of: card.containerView) { card.containerView.addSubview(cardView) }
        parentView.addSubview(backgroundView)
        
        var backgroundViewConstraints = [NSLayoutConstraint]()
        backgroundViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[cardView]|", options: [], metrics: nil, views: ["cardView": cardView])
        backgroundViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[cardView]|", options: [], metrics: nil, views: ["cardView": cardView])
        if backgroundView != cardView { backgroundView.addConstraints(backgroundViewConstraints) }
        
        cardView.addSubview(pullTab)
        pulltabTopConstraint = pullTab.topAnchor.constraint(equalTo: cardView.safeAreaLayoutGuide.topAnchor, constant: pullTabTopDistance)
        let pulltabConstraints = [
            pullTab.centerXAnchor.constraint(equalTo: cardView.safeAreaLayoutGuide.centerXAnchor),
            pullTab.widthAnchor.constraint(equalToConstant: pullTab.frame.width),
            pullTab.heightAnchor.constraint(equalToConstant: pullTab.frame.height),
            pulltabTopConstraint!
        ]
        
        cardView.addConstraints(pulltabConstraints)
        
        let bottomAnchorConstraint = parentView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        let initialBottomConstraint = NSLayoutConstraint(item: backgroundView, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .bottom, multiplier: 1, constant: 0)
        
        initialBottomConstraint.priority = .defaultLow
        
        let screenBounds = UIScreen.main.bounds
        let minWidth = min(screenBounds.width, screenBounds.height)
        compactVerticalConstraints = [
            parentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: -card.edgeInsets(forOrientation: .compactVertical).left),
            parentView.layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: backgroundView.trailingAnchor, constant: card.edgeInsets(forOrientation: .compactVertical).right),
            NSLayoutConstraint(item: backgroundView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: min(minWidth * 0.9, 340) - card.edgeInsets(forOrientation: .compactVertical).right)
        ]
        
        compactHorizontalConstraints = [
            parentView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: -card.edgeInsets(forOrientation: .compactHorizontal).left),
            parentView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: card.edgeInsets(forOrientation: .compactHorizontal).right)
        ]
        
        regularConstraints = [
            parentView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: -12 - card.edgeInsets(forOrientation: .regular).left),
            parentView.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualTo: backgroundView.trailingAnchor, constant: 12 + card.edgeInsets(forOrientation: .regular).right),
            NSLayoutConstraint(item: backgroundView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: min(minWidth * 0.9, 450) - card.edgeInsets(forOrientation: .regular).right)
        ]

        // Add cardHeightConstraint to the list and remove the constraint from the bottom of backgroundViewConstraints to make the height of the card constant
        let constraints: [NSLayoutConstraint] = [
            bottomAnchorConstraint,
            initialBottomConstraint,
        ]
        
        parentView.addConstraints(constraints)
        
        // 3: Call didMove()
        card.didMove(toParent: parent)
        
        // 4: Additional Setup
        setOffset(maxOffset, animated: false)
        bottomConstraint.isActive = true
        parentView.layoutIfNeeded()
        listeners.forEach{ $0.cardAnimatorWillTransitionToNewOrientation(self, newOrientation: orientation) }
        configureToNewOrientation()
        bottomConstraint.isActive = false
        updateCornerRadius()
        parentView.layoutIfNeeded()
        cardView.addGestureRecognizer(panGesture)
        dismissButton?.alpha = 0
        _presented = true
    }
    
    private func removeChild() {
        card?.willMove(toParent: nil)
        dismissButton?.removeFromSuperview()
        backgroundView?.removeFromSuperview()
        card?.removeFromParent()
        if parent?.cardAnimator == self { parent?.cardAnimator = nil }
        _presented = false
    }
    
    private func updateCornerRadius() {
        var currentView = cardView
        currentView?.layer.cornerRadius = _cornerRadius
        while let superView = currentView?.superview, superView != parentView {
            superView.layer.cornerRadius = _cornerRadius
            currentView = superView
        }
    }
    
    private var startConstant: CGFloat = 0
    @objc private func didPan(_ panGesture: UIPanGestureRecognizer) {
        if let cardGesture = panGesture as? CardPanGesture, cardGesture.isCancelled { return }
        switch panGesture.state {
        case .began:
            self._panGesture.resetOrigin()
            startPanRecognition()
            fallthrough
        case .changed:
            continuePanRecognition()
        case .cancelled, .ended:
            endPanRecognition()
        default:
            break
        }
    }
    
    fileprivate func startPanRecognition() {
        startConstant = constant
    }
    
    private func continuePanRecognition() {
        guard !scrollHandler.cardShouldIgnorePan || !scrollHandler.isScrolling else { return }
        let translation = panGesture.translation(in: parentView).y
        var newConstant = startConstant - translation
        let distanceFromMax = newConstant - maxConstant
        let distanceFromMin = newConstant - minConstant
        if distanceFromMax > 0 {
            let t = Double(distanceFromMax) / Double(CardAnimator.MAX_BOUNDARY_OFFSET)
            newConstant = maxConstant + CardAnimator.MAX_BOUNDARY_OFFSET * CGFloat(boundaryCurve.combinedTransform(x: t, slope: 1, asymptote: 1))
        } else if distanceFromMin < 0 && !dismissesOnDragDown {
            let t = Double(-distanceFromMin) / Double(CardAnimator.MIN_BOUNDARY_OFFSET)
            newConstant = minConstant - CardAnimator.MIN_BOUNDARY_OFFSET * CGFloat(boundaryCurve.combinedTransform(x: t, slope: 1, asymptote: 1))
        }
        
        setConstant(newConstant, animationParameters: nil)
        if shouldAnimatePullTab { pullTab.setState(newConstant >= maxConstant ? .downArrow : .straightLine, animated: true) }
    }
    
    private func endPanRecognition() {
        var velocity = panGesture.velocity(in: parentView).y
        var dismissIfAvailable = true
        if scrollHandler.state == .scrolling {
            velocity = 0
            dismissIfAvailable = false
        }
        stickToClosestOffset(velocity: velocity, dismissIfAvailable: dismissIfAvailable, animated: true)
    }
    
    private func findClosestStickyOffset(forBottomConstraintHeight bottomConstraintHeight: CGFloat, velocity: CGFloat? = nil) -> StickyOffset {
        if let velocity = velocity, abs(velocity) > 50 {
            if velocity <= -6000 { return maxOffset }
            else if velocity >= 6000 { return minOffset }
            
            var bestOffset = minOffset
            for i in 1 ..< stickyOffsets.count {
                let offset = stickyOffsets[i]
                if velocity > 0 { // Velocity is down
                    let distance = bottomConstraintHeight - offset.distanceFromBottom(safeAreaHeight)
                    if distance < 0 { break } // Distance is negative when the offset is above the card
                    else { bestOffset = offset } // Sets the best offset the offsets below the card
                } else if velocity < 0 { // Velocity is up
                    let distance = bottomConstraintHeight - offset.distanceFromBottom(safeAreaHeight)
                    bestOffset = offset
                    if distance <= 0 { break } // Stops when distance is distance <= 0 » stops when offset is above card
                }
            }
            
            return bestOffset
        }
        
        return stickyOffsets.min { (lhs, rhs) -> Bool in
            return abs(lhs.distanceFromBottom(safeAreaHeight) - bottomConstraintHeight) < abs(rhs.distanceFromBottom(safeAreaHeight) - bottomConstraintHeight)
        }!
    }
    
    private func setConstant(_ constant: CGFloat, animationParameters: SpringAnimationContext?) {
        scrollHandler.previousConstant = self.constant
        listeners.forEach{ $0.cardAnimator(self, heightWillChange: constant, leftoverHeight: safeAreaHeight - constant, animationParameters: animationParameters) }
        self.constant = constant
        updateBackgroundButtonAlpha()
    }
    
    private func configureToNewOrientation() {
        guard let parentView = parentView, let backgroundView = backgroundView, backgroundView.isDescendant(of: parentView) else { return }
        let maxHeight = maxOffset.distanceFromBottom(safeAreaHeight) + parentView.safeAreaInsets.bottom
        cardHeightConstraint.constant = maxHeight
        
        switch orientation {
        case .regular:
            if (!conformsToWideScreen) { fallthrough }
            compactHorizontalConstraints.forEach{ $0.isActive = false }
            compactVerticalConstraints.forEach{ $0.isActive = false }
            regularConstraints.forEach{ $0.isActive = true }
        case .compactVertical:
            if (!conformsToWideScreen) { fallthrough }
            regularConstraints.forEach{ $0.isActive = false }
            compactHorizontalConstraints.forEach{ $0.isActive = false }
            compactVerticalConstraints.forEach{ $0.isActive = true }
        case .compactHorizontal:
            regularConstraints.forEach{ $0.isActive = false }
            compactVerticalConstraints.forEach{ $0.isActive = false }
            compactHorizontalConstraints.forEach{ $0.isActive = true }
        }
        
        let closestOffset = findClosestStickyOffset(forBottomConstraintHeight: constant)
        setOffset(closestOffset, animated: false)
        backgroundView.layoutIfNeeded()
        listeners.forEach{ $0.cardAnimatorDidTransitionToNewOrientation(self, newOrientation: orientation, newOffset: closestOffset) }
    }
    
    private func setOffset(_ stickyOffset: StickyOffset, springAnimation: inout SpringAnimationContext) {
        if shouldAnimatePullTab { pullTab.setState(stickyOffset == maxOffset ? .downArrow : .straightLine, animated: true) }
        let springAnimationCopy = springAnimation
        springAnimation.addAnimation { [weak this = self] in
            this?.setConstant(stickyOffset.distanceFromBottom(this!.safeAreaHeight), animationParameters: springAnimationCopy)
            this?.parentView?.layoutIfNeeded()
        }
        
        listeners.forEach{ $0.cardAnimator(self, willApplyNewOffset: stickyOffset, withAnimationParameters: &springAnimation) }
        springAnimation.animate()
    }
    
    @objc private func dismissButtonClicked() {
        if delegate?.cardAnimatorShouldDismissOnBackgroundTap?(self) ?? dismissesOnBackgroundTap {
            dismiss(animated: true)
        }
    }
    
    private func stickToClosestOffset(velocity: CGFloat, dismissIfAvailable: Bool, animated: Bool) {
        guard let cardView = cardView else { return }
        var velocity = velocity
        let closestStickyOffset = findClosestStickyOffset(forBottomConstraintHeight: constant, velocity: velocity)
        let idealNewConstraint = startConstant - panGesture.translation(in: parentView).y
        let distanceFromMax = idealNewConstraint - maxConstant
        let distanceFromMin = idealNewConstraint - minConstant
        if distanceFromMax > 0 {
            let t = Double(distanceFromMax) / Double(CardAnimator.MAX_BOUNDARY_OFFSET)
            let scalar = CGFloat(boundaryCurve.combinedTransformD(x: t, slope: 1, asymptote: 1))
            velocity *= scalar
        } else if distanceFromMin < 0 && !dismissesOnDragDown {
            let t = Double(-distanceFromMin) / Double(CardAnimator.MIN_BOUNDARY_OFFSET)
            let scalar = CGFloat(boundaryCurve.combinedTransformD(x: t, slope: 1, asymptote: 1))
            velocity *= scalar
        } else if dismissIfAvailable && (delegate?.cardAnimatorShouldDismissOnDragDown?(self) ?? dismissesOnDragDown) && ((distanceFromMin - cardView.safeAreaInsets.bottom) / (minConstant + cardView.safeAreaInsets.bottom) < -0.5 || (constant < minConstant && velocity > 700)) {
            dismiss(animated: true)
            return
        }
        
        setOffset(closestStickyOffset, velocity: velocity, animated: animated)
    }
    
    
    
    
    
    /// Force the card to stick to the closest available offset
    /// - Parameter animated: Whether the transition should be animated
    public func stickToClosestOffset(animated: Bool) {
        stickToClosestOffset(velocity: 0, dismissIfAvailable: false, animated: animated)
    }
    
    /// Force the card to stick to a particular offset
    /// - Parameters:
    ///   - stickyOffset: The offset to stick to
    ///   - velocity: The current vertical velocity to start the animation at. If the card is not moving, use 0. 0 by default
    ///   - animated: Whether the transition should be animated
    public func setOffset(_ stickyOffset: StickyOffset, velocity: CGFloat = 0, animated: Bool) {
        let distance = constant - stickyOffset.distanceFromBottom(safeAreaHeight)
        if distance == 0 { return }
        var springVelocity = distance == 0 ? 0 : velocity / distance
        springVelocity = springVelocity.sign * min(abs(springVelocity), 300)
        var springAnimation = SpringAnimationContext(duration: animated ? 0.6 : 0, delay: 0, springDamping: 0.8, initialSpringVelocity: springVelocity, options: CardAnimator.ANIMATION_OPTIONS, animations: nil)
        setOffset(stickyOffset, springAnimation: &springAnimation)
    }
    
    /// Present the card
    /// - Parameter animated: Whether the presentation should be animated
    public func present(animated: Bool) {
        listeners.forEach { $0.cardAnimatorWillBeginSetup(self) }
        addChild()
        var springAnimation = SpringAnimationContext(duration: animated ? 0.7 : 0, delay: 0, springDamping: 0.7, initialSpringVelocity: 0, options: CardAnimator.ANIMATION_OPTIONS) { [weak this = self] in
            this?.bottomConstraint.isActive = true
            this?.parentView?.layoutIfNeeded()
        }
        
        listeners.forEach { $0.cardAnimatorWillPresentCard(self, withAnimationParameters: &springAnimation) }
        setOffset(defaultOffset, springAnimation: &springAnimation)
        springAnimation.animate()
    }
    
    /// Dismiss the card
    /// - Parameters:
    ///   - animated: Whether the dismissal should be animated
    ///   - completion: A completion handler which will run after the dismissal
    public func dismiss(animated: Bool, completion: @escaping () -> () = {}) {
        guard presented else {
            completion()
            return
        }
        
        var springAnimation = SpringAnimationContext(duration: animated ? 0.3 : 0, delay: 0, springDamping: 1, initialSpringVelocity: 0, options: CardAnimator.ANIMATION_OPTIONS) { [weak this = self] in
            this?.dismissButton?.backgroundColor = nil
            this?.bottomConstraint.isActive = false
            this?.parentView?.layoutIfNeeded()
        } completion: { [weak this = self] (_) in
            this?.removeChild()
            completion()
        }
        
        listeners.forEach { $0.cardAnimatorWillDismissCard(self, withAnimationParameters: &springAnimation) }
        springAnimation.animate()
    }
    
    /// Add a listener to the card animator
    /// - Parameter listener: The listener to add
    public func addListener(_ listener: CardListener) {
        listeners.insert(listener)
    }
    
    /// Remove a listener from the card animator
    /// - Parameter listener: The listener to remove
    public func removeListener(_ listener: CardListener) {
        listeners.remove(listener)
    }
    
    /// Called every time the background button alpha should be updated. Should be called after any updates to the alpha curve
    public func updateBackgroundButtonAlpha() {
        if conformsToWideScreen && orientation != .compactHorizontal {
            dismissButton?.alpha = 0
        } else if let alpha = alphaCurve.overrideAlpha {
            if let dismissButton = dismissButton, dismissButton.alpha != alpha { dismissButton.alpha = alpha }
        } else if alphaCurve.offsetForMinBrightness == alphaCurve.offsetForMaxBrightness {
            let tween = constant/alphaCurve.offsetForMaxBrightness.distanceFromBottom(safeAreaHeight)
            let alpha = max(0, min(tween * (alphaCurve.maxAlpha - alphaCurve.minAlpha) + alphaCurve.minAlpha, alphaCurve.maxAlphaTopBound))
            if let dismissButton = dismissButton, dismissButton.alpha != alpha { dismissButton.alpha = alpha }
        } else {
            var offsetBoundary = alphaCurve.offsetForMinBrightness.distanceFromBottom(safeAreaHeight) - alphaCurve.offsetForMaxBrightness.distanceFromBottom(safeAreaHeight)
            if offsetBoundary == 0 { offsetBoundary = 1 }
            let tween = (constant - alphaCurve.offsetForMaxBrightness.distanceFromBottom(safeAreaHeight)) / offsetBoundary
            let alpha = max(0, min(tween * (alphaCurve.maxAlpha - alphaCurve.minAlpha) + alphaCurve.minAlpha, alphaCurve.maxAlphaTopBound))
            if let dismissButton = dismissButton, dismissButton.alpha != alpha { dismissButton.alpha = alpha }
        }
    }
    
    
    
    
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async { [weak this = self] in
            this?.listeners.forEach{ $0.cardAnimatorWillTransitionToNewOrientation(self, newOrientation: this!.orientation) }
            this?.configureToNewOrientation()
        }
    }
    
    deinit {
        parentView?.removeObserver(self, forKeyPath: "frame")
    }
}









fileprivate extension UIView {
    func searchForScrollView() -> UIScrollView? {
        for subview in subviews {
            if let subview = subview as? UIScrollView { return subview }
            else if let subScrollView = subview.searchForScrollView() { return subScrollView }
        }
        
        return nil
    }
}

fileprivate extension UIScrollView {
    var adjustedContentOffset: CGPoint {
        get {
            var contentOffset = self.contentOffset
            contentOffset.x += adjustedContentInset.left
            contentOffset.y += adjustedContentInset.top
            return contentOffset
        }
        
        set {
            var contentOffset = newValue
            contentOffset.x -= adjustedContentInset.left
            contentOffset.y -= adjustedContentInset.top
            self.contentOffset = contentOffset
        }
        
    }
}
















fileprivate class ScrollHandler: NSObject, UIGestureRecognizerDelegate {
    
    private static let debugMode = false
    
    enum ScrollState {
        case scrolling, panningCard
    }
    
    weak var cardAnimator: CardAnimator?
    var cardShouldIgnorePan = false
    var isScrolling = false
    var isEnabled = true
    var wasBouncing = true
    private var _state: ScrollState = .panningCard
    var state: ScrollState {
        set {
            if let scrollView = scrollView, scrollView.adjustedContentOffset.y < 0 {
                scrollView.adjustedContentOffset.y = 0
            }
            
            if newValue == .panningCard {
                scrollView?.bounces = false
                scrollView?.showsVerticalScrollIndicator = false
                cardShouldIgnorePan = false
                
                if newValue != state {
                    lockedContentOffset = scrollView?.contentOffset ?? .zero
                    cardPan?.resetOrigin()
                    cardAnimator?.startPanRecognition()
                }
            } else if newValue == .scrolling {
                scrollView?.bounces = wasBouncing
                scrollView?.showsVerticalScrollIndicator = showsScrollIndicators
                cardShouldIgnorePan = true
            }
            
            _state = newValue
        }
        
        get {
            return _state
        }
    }
    
    var cardPan: CardPanGesture? {
        return cardAnimator?._panGesture
    }
    
    private var isLongPressOnScrollIndicators = false
    private var lockedContentOffset: CGPoint = .zero
    private var showsScrollIndicators = true
    private var previousOffset: CGPoint = .zero
    fileprivate var ignoreFurtherGestureEvents = false
    fileprivate var previousConstant: CGFloat = 0
    private weak var scrollView: UIScrollView?
    
    init (cardAnimator: CardAnimator) {
        self.cardAnimator = cardAnimator
        super.init()
    }
    
    func setup() {
        cardAnimator?.panGesture.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled else { return false }
        let gestureType = type(of: otherGestureRecognizer)
        let gestureClassName = String(describing: gestureType)
        if let panGesture = otherGestureRecognizer as? UIPanGestureRecognizer, panGesture.view is UIScrollView {
            if gestureClassName.starts(with: "UIScrollView") {
                isScrolling = panGesture.state == .began || panGesture.state == .changed
                panGesture.removeTarget(self, action: nil)
                panGesture.addTarget(self, action: #selector(scrollViewDidPan(_:)))
                if let tableView = panGesture.view as? UITableView, tableView.isEditing {
                    let wasEnabled = cardPan?.isEnabled ?? true
                    cardPan?.isEnabled = false
                    cardPan?.isEnabled = wasEnabled
                    return false
                }
            } else if gestureClassName.starts(with: "_UISwipeAction") {
                panGesture.removeTarget(self, action: nil)
                panGesture.addTarget(self, action: #selector(tableViewCellSwipeGesture(_:)))
            }
            
            return true
        }
        
        if gestureClassName.starts(with: "UIScrollView") {
            if gestureClassName == "UIScrollViewKnobLongPressGestureRecognizer" {
                otherGestureRecognizer.removeTarget(self, action: nil)
                otherGestureRecognizer.addTarget(self, action: #selector(longPressOnScrollIndicators(_:)))
            }
            return true
        }
        
        return false
    }
    
    @objc private func tableViewCellSwipeGesture(_ gesture: UIPanGestureRecognizer) {
        guard let tableView = gesture.view as? UITableView else { return }
        if tableView.isEditing {
            cardPan?.cancelFurtherRecognition()
            cardAnimator?.stickToClosestOffset(animated: false)
        }
    }
    
    @objc private func longPressOnScrollIndicators(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            isLongPressOnScrollIndicators = true
        case .cancelled, .ended:
            isLongPressOnScrollIndicators = false
        default:
            return
        }
    }
    
    @objc private func scrollViewDidPan(_ panGesture: UIPanGestureRecognizer) {
        guard let scrollView = panGesture.view as? UIScrollView, let cardAnimator = cardAnimator else { return }
        if ignoreFurtherGestureEvents && panGesture.state == .changed { return }
        lockedContentOffset.x = scrollView.contentOffset.x
        
        switch panGesture.state {
        case .began:
            debug("Began")
            ignoreFurtherGestureEvents = false
            self.scrollView = scrollView
            wasBouncing = scrollView.bounces
            isScrolling = true
            previousOffset = scrollView.contentOffset
            showsScrollIndicators = scrollView.showsVerticalScrollIndicator
            lockedContentOffset.y = max(-scrollView.adjustedContentInset.top, scrollView.contentOffset.y)
            fallthrough
        case .changed:
            debug("Changed")
            let isScrollingHorizontally = scrollView.contentOffset.x != previousOffset.x
            let panDirection = panGesture.velocity(in: scrollView).y
            let isPanningDown = panDirection > 0
            let isPanningUp = panDirection < 0
            if isScrollingHorizontally || !(cardAnimator.delegate?.cardAnimator?(cardAnimator, shouldHandleScrollView: scrollView) ?? true) {
                debug("Changed 1")
                state = .scrolling
                ignoreFurtherGestureEvents = true
                let isEnabled = cardPan?.isEnabled ?? false
                cardPan?.isEnabled = false
                cardPan?.isEnabled = isEnabled
            } else if isLongPressOnScrollIndicators && scrollView.adjustedContentOffset.y < 0 {
                debug("Changed 2")
                lockedContentOffset.y = -scrollView.adjustedContentInset.top
                state = .panningCard
                scrollView.isScrollEnabled = false
                scrollView.isScrollEnabled = true
            } else if isPanningDown && !scrollView.alwaysBounceHorizontal && scrollView.adjustedContentOffset.y < 0 {
                debug("Changed 3")
                // User is scrolling down and the scrollview is at the top
                lockedContentOffset.y = -scrollView.adjustedContentInset.top
                state = .panningCard
            } else if isPanningDown && scrollView.adjustedContentOffset.y > 0 {
                debug("Changed 4")
                // User is scrolling down and the scrollview is not at the top
                state = .scrolling
                scrollView.showsVerticalScrollIndicator = cardAnimator.height >= cardAnimator.scrollConstant ? showsScrollIndicators : false
            } else if isPanningUp && cardAnimator.height >= cardAnimator.scrollConstant {
                debug("Changed 5")
                // User is scrolling up and the card is at the top
                let isScrollable = scrollView.contentSize.height + scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom > scrollView.bounds.height ||
                                    scrollView.contentSize.width + scrollView.adjustedContentInset.left + scrollView.adjustedContentInset.right > scrollView.bounds.width ||
                                    scrollView.alwaysBounceHorizontal
                if isScrollable {
                    if previousConstant > cardAnimator.scrollConstant && cardAnimator.height > cardAnimator.scrollConstant && cardAnimator.height < cardAnimator.maxConstant {
                        debug("Changed 6")
                        lockedContentOffset.y = -scrollView.adjustedContentInset.top
                        state = .panningCard
                    } else {
                        debug("Changed 7")
                        cardAnimator.stickToClosestOffset(animated: false)
                        state = .scrolling
                    }
                } else {
                    debug("Changed 8")
                    lockedContentOffset.y = -scrollView.adjustedContentInset.top
                    state = .panningCard
                }
            } else if isPanningUp && cardAnimator.height < cardAnimator.scrollConstant {
                debug("Changed 9")
                // User is scrolling up and the card is not at the top
                state = .panningCard
            }
            
            previousOffset = scrollView.contentOffset
            if state == .panningCard { scrollView.contentOffset = lockedContentOffset }
        case .ended, .cancelled:
            debug("Ended")
            if state == .panningCard {
                if scrollView.contentSize.height > scrollView.bounds.height {
                    debug("Ended 1")
                    scrollView.setContentOffset(lockedContentOffset, animated: false)
                } else {
                    debug("Ended 2")
                    lockedContentOffset.y = -scrollView.adjustedContentInset.top
                    scrollView.setContentOffset(lockedContentOffset, animated: false)
                }
            }
            scrollView.showsVerticalScrollIndicator = showsScrollIndicators
            isScrolling = false
            scrollView.bounces = wasBouncing
            self.scrollView = nil
            panGesture.removeTarget(self, action: nil)
        default:
            break
        }
    }
    
    private func debug(_ str: @autoclosure () -> (String)) {
        if ScrollHandler.debugMode { print(str()) }
    }
}
