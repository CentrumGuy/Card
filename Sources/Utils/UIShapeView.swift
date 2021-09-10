//
//  UIShapeView.swift
//  Sine Graph
//
//  Created by Shahar Ben-Dor on 6/11/20.
//  Copyright © 2020 Specter. All rights reserved.
//

import UIKit

/// A view which can draw shapes. Backed by a CAShapeLayer
public class UIShapeView: UIView {
    
    override public class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    /// Gives access to the backing CAShapeLayer
    override public var layer: CAShapeLayer {
        return super.layer as! CAShapeLayer
    }
    
    /// The path of the shape
    public var path: CGPath? {
        get {
            return layer.path
        }
        
        set {
            layer.path = newValue
        }
    }
    
    /// The fill color of the shape
    public var fillColor: CGColor? {
        get {
            return layer.fillColor
        }
        
        set {
            layer.fillColor = newValue
        }
    }
    
    /// The stroke color of the shape
    public var strokeColor: CGColor? {
        get {
            return layer.strokeColor
        }
        
        set {
            layer.strokeColor = newValue
        }
    }
    
}
