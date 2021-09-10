//
//  PullTab.swift
//  Fluidity
//
//  Created by Shahar Ben-Dor on 3/21/20.
//  Copyright © 2020 Spectre Software. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class PullTab: UIShapeView {
    
    public enum State {
        /// The down arrow state of the pull tab
        case downArrow
        
        /// The straight line state of the pull tab
        case straightLine
    }
    
    private var _state: State = .downArrow
    
    /// Returns the current state of the pull tab
    public var state: State {
        return _state
    }
    
    /// The line (stroke) color of the pull tab
    @IBInspectable public var lineColor: UIColor? {
        set { strokeColor = newValue?.cgColor }
        get {
            if let strokeColor = strokeColor { return UIColor(cgColor: strokeColor) }
            return nil
        }
    }
    
    /// The line width of the pull tab
    @IBInspectable public var lineWidth: CGFloat {
        set { layer.lineWidth = newValue }
        get { return layer.lineWidth }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.lineCap = .round
        layer.lineJoin = .round
        fillColor = nil
        setState(.straightLine, animated: false)
    }
    
    
    private func getPath(state: State) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        
        switch state {
        case .straightLine:
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.midY))
        case .downArrow:
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
        }
        
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        return path
    }
    
    /// Sets the state of the pull tab
    /// - Parameters:
    ///   - state: The new state for the pull tab
    ///   - animated: Whether the transition should be animated
    public func setState(_ state: State, animated: Bool) {
        guard state != self.state else { return }
        self._state = state
        
        let path = getPath(state: state)
        let pathCG = path.cgPath
        
        if animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = self.path
            animation.toValue = pathCG
            animation.duration = 0.3
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(animation, forKey: "animation")
        }
        
        self.path = pathCG
    }
}
