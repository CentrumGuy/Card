import Foundation

internal struct AsymptotalCurve {
    private let degree: Double
    private let derivativeCoefficient: Double
    private let derivativeDegree: Double
    
    public init (degree: Double) {
        self.degree = -degree
        
        self.derivativeCoefficient = -1 * self.degree
        self.derivativeDegree = self.degree - 1
    }
    
    public init (slope: Double, asymptote: Double, x0: Double = 0.1, percision: Double = 0.00000001) {
        let degree = AsymptotalCurve.degree(forSlope: slope, asymptote: asymptote, x0: x0, percision: percision)
        self.init(degree: degree)
    }
    
    public func y(forX x: Double) -> Double {
        return -pow(x, degree)
    }
    
    public func xForSlope(_ slope: Double) -> Double {
        return pow(slope / derivativeCoefficient, 1 / derivativeDegree)
    }
    
    public func transform(x: Double, slope: Double, asymptote: Double) -> Double {
        let absX = abs(x)
        let xForDerivative = xForSlope(slope)
        let yAtTangent = y(forX: xForDerivative) + asymptote
        let dY = xForDerivative - (yAtTangent / slope)
        let y = -pow(absX + dY, degree) + asymptote
        return x >= 0 ? y : -y
    }
    
    public func transformD(x: Double, slope: Double, asymptote: Double) -> Double {
        let absX = abs(x)
        let xForDerivative = xForSlope(slope)
        let yAtTangent = y(forX: xForDerivative) + asymptote
        let dY = xForDerivative - (yAtTangent / slope)
        let y = -degree * pow(absX + dY, degree - 1)
        return y
    }
    
    public func combinedTransform(x: Double, slope: Double, asymptote: Double) -> Double {
        let absX = abs(x)
        let xForDerivative = xForSlope(slope)
        let yAtTangent = y(forX: xForDerivative) + asymptote
        let dY = xForDerivative - (yAtTangent / slope)
        
        let y: Double
        if absX < (yAtTangent / slope) {
            y = slope * absX
        } else {
            y = -pow(absX + dY, degree) + asymptote
        }
        
        return x >= 0 ? y : -y
    }
    
    public func combinedTransformD(x: Double, slope: Double, asymptote: Double) -> Double {
        let absX = abs(x)
        let xForDerivative = xForSlope(slope)
        let yAtTangent = y(forX: xForDerivative) + asymptote
        let dY = xForDerivative - (yAtTangent / slope)
        
        let y: Double
        if absX < (yAtTangent / slope) {
            y = slope
        } else {
            y = -degree * pow(absX + dY, degree - 1)
        }
        
        return x >= 0 ? y : -y
    }
    
    public static func degree(forSlope slope: Double, asymptote: Double, x0: Double = 0.1, percision: Double = 0.00000001) -> Double {
        return MathUtils.newtonApproximation(x0: x0, percision: percision, maxIterations: 20, value: { (xN) -> (Double) in
            let a = pow(asymptote, (xN + 1) / xN)
            return xN * a - slope
        }) { (xN) -> (Double) in
            let a = pow(asymptote, ((xN + 1) / (xN)))
            let b = exp((log(asymptote) * (xN + 1)) / (xN)) * log(asymptote)
            return a - (b / xN)
        }
    }
}
