//
//  UIShapeView.swift
//  Sine Graph
//
//  Created by Shahar Ben-Dor on 6/11/20.
//  Copyright © 2020 Specter. All rights reserved.
//

import UIKit

public class UIShapeView: UIView {
    
    override public class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    override public var layer: CAShapeLayer {
        return super.layer as! CAShapeLayer
    }
    
    
    
    public var path: CGPath? {
        get {
            return layer.path
        }
        
        set {
            layer.path = newValue
        }
    }
    
    public var fillColor: CGColor? {
        get {
            return layer.fillColor
        }
        
        set {
            layer.fillColor = newValue
        }
    }
    
    public var strokeColor: CGColor? {
        get {
            return layer.strokeColor
        }
        
        set {
            layer.strokeColor = newValue
        }
    }
    
}
