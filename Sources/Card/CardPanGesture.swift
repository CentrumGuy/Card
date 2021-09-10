//
//  CardPanGesture.swift
//  Card Controller
//
//  Created by Shahar Ben-Dor on 11/1/20.
//

import Foundation
import UIKit

internal class CardPanGesture: UIPanGestureRecognizer {
    
    private var offset: CGPoint = .zero
    private var _isCancelled = false
    var isCancelled: Bool {
        return _isCancelled
    }
    
    func resetOrigin() {
        offset = super.translation(in: nil)
    }
    
    override func translation(in view: UIView?) -> CGPoint {
        return super.translation(in: view).applying(CGAffineTransform(translationX: -offset.x, y: -offset.y))
    }
    
    func cancelFurtherRecognition() {
        _isCancelled = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        _isCancelled = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        _isCancelled = false
    }
}
