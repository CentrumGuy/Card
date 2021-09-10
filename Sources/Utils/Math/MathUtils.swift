import Foundation
import UIKit

class MathUtils {
    static func bezierCubicFunction(p1: CGPoint, cp1: CGPoint, cp2: CGPoint, p2: CGPoint, t: CGFloat) -> CGPoint {
        let x = p1.x * (pow(1 - t, 3)) + cp1.x * (3 * t * pow(1 - t, 2)) + cp2.x * (3 * (1 - t) * pow(t, 2)) + p2.x * (pow(t, 3))
        let y = p1.y * (pow(1 - t, 3)) + cp1.y * (3 * t * pow(1 - t, 2)) + cp2.y * (3 * (1 - t) * pow(t, 2)) + p2.y * (pow(t, 3))
        return CGPoint(x: x, y: y)
    }
    
    static func getTForBezierX(p1: CGPoint, cp1: CGPoint, cp2: CGPoint, p2: CGPoint, x: CGFloat) -> CGFloat? {
        let roots = MathUtils.findRoots(x: Double(x), pa: Double(p1.x), pb: Double(cp1.x), pc: Double(cp2.x), pd: Double(p2.x))
        for root in roots {
            if root >= 0 && root <= 1 {
                return CGFloat(root)
            }
        }
        
        return nil
    }
    
    static func getPointForT(p0: CGPoint, slope: CGFloat, t: CGFloat) -> CGPoint {
        if slope == .infinity {
            return CGPoint(x: p0.x, y: p0.y + t)
        } else if slope == -.infinity {
            return CGPoint(x: p0.x, y: p0.y - t)
        }
        
        let x = p0.x + t
        let y = p0.y + t * slope
        return CGPoint(x: x, y: y)
    }
    
    static func findRoots(x: Double, pa: Double, pb: Double, pc: Double, pd: Double) -> [Double] {
        let pa3 = 3 * pa
        let pb3 = 3 * pb
        let pc3 = 3 * pc
        let a = -pa + pb3 - pc3 + pd
        var b = pa3 - 2 * pb3 + pc3
        var c = -pa3 + pb3
        var d = pa - x
        
        if a == 0 {
            if b == 0 {
                if c == 0 {
                    return []
                }
                
                return [-d / c]
            }
            
            let q = sqrt(c * c - 4 * b * d)
            let b2 = 2 * b
            
            return [
                (q - c) / b2,
                (-c - q) / b2
            ]
        }
        
        b /= a
        c /= a
        d /= a
        
        let b3 = b / 3
        let p = (3 * c - b * b) / 3
        let p3 = p / 3
        let q = (2 * b * b * b - 9 * b * c + 27 * d) / 27
        let q2 = q / 2
        let discriminant = q2 * q2 + p3 * p3 * p3
        let u1: Double
        let v1: Double
        
        if discriminant < 0 {
            let mp3 = -p / 3
            let r = sqrt(mp3 * mp3 * mp3)
            let t = -q / (2 * r)
            let cosphi = t < -1 ? -1 : t > 1 ? 1 : t
            let phi = acos(cosphi)
            let crtr = pow(r, 1 / 3)
            let t1 = 2 * crtr
            
            return [
                t1 * cos(phi / 3) - b3,
                t1 * cos((phi + 2 * .pi) / 3) - b3,
                t1 * cos((phi + 2 * 2 * .pi) / 3) - b3
            ]
        } else if discriminant == 0 {
            u1 = q2 < 0 ? pow(-q2, 1 / 3) : -pow(q2, 1 / 3)
            
            return [
                2 * u1 - b3,
                -u1 - b3
            ]
        } else {
            let sd = sqrt(discriminant)
            u1 = pow(-q2 + sd, 1 / 3)
            v1 = pow(q2 + sd, 1 / 3)
            
            return [
                u1 - v1 - b3
            ]
        }
    }
    
    static func newtonApproximation(x0: Double, percision: Double = 0.00000001, maxIterations: Int = -1, value: (Double) -> (Double), derivative: (Double) -> (Double)) -> Double {
        var iterationCount = 0
        var xN = x0
        
        while maxIterations < 0 || iterationCount < maxIterations {
            let _value = value(xN)
            let _derivative = derivative(xN)
            let xN1 = xN - (_value / _derivative)
            
            if abs(xN1 - xN) <= percision {
                xN = xN1
                break
            }
            
            xN = xN1
            iterationCount += 1
        }
        
        return xN
    }
}








internal extension CGFloat {
    var sign: CGFloat {
        return self == 0 ? 0 : self / abs(self)
    }
}
