//
//  Cesium.swift
//
//  Created by Maryana on 19.10.2021.
//

import Foundation

struct Cartesian {
    var x:             Double
    var y:             Double
    var z:             Double
}

struct Cartographic {
    var longitude:     Double
    var latitude:      Double
    var height:        Double
}


class Cesium: NSObject {
    
    let EPSILON12 = 0.000000000001
    let EPSILON1 = 0.1
    let DEGREES_PER_RADIAN = 180.0 / Double.pi
    let RADIANS_PER_DEGREE = Double.pi / 180.0
    let wgs84RadiiSquared = Cartesian(x:6378137.0 * 6378137.0, y:6378137.0 * 6378137.0, z:6356752.3142451793 * 6356752.3142451793)
    
    static let shared = Cesium()
    
    override init() {
        super.init()
    }
    
    public func cartographicFromCartesian(cartesian: Cartesian) -> Cartographic? {
        let wgs84OneOverRadii = Cartesian.init(
            x:1.0 / 6378137.0,
            y:1.0 / 6378137.0,
            z:1.0 / 6356752.3142451793
        )
        let wgs84OneOverRadiiSquared = Cartesian.init(
            x:1.0 / (6378137.0 * 6378137.0),
            y:1.0 / (6378137.0 * 6378137.0),
            z:1.0 / (6356752.3142451793 * 6356752.3142451793)
        )
        let wgs84CenterToleranceSquared = EPSILON1
        
        let oneOverRadii = wgs84OneOverRadii
        let oneOverRadiiSquared = wgs84OneOverRadiiSquared
        let centerToleranceSquared = wgs84CenterToleranceSquared;
        
        //`cartesian is required.` is thrown from scaleToGeodeticSurface
        let p = scaleToGeodeticSurface(cartesian: cartesian, oneOverRadii: oneOverRadii, oneOverRadiiSquared: oneOverRadiiSquared, centerToleranceSquared: centerToleranceSquared)
        
        if p == nil {
            return nil
        }
        
        var n = multiplyComponents(left:p!, right:oneOverRadiiSquared)
        n = normalize(n)
        
        let h = subtract(left:cartesian, right:p!)
        
        let longitude = atan2(n.y, n.x)
        let latitude = asin(n.z)
        let height = sign(value: dot(left:h, right:cartesian)) * magnitude(h)
        
        return Cartographic.init(longitude: longitude * DEGREES_PER_RADIAN, latitude: latitude * DEGREES_PER_RADIAN, height: height)
    }
    
    public func cartesianFromCartographic(carto: Cartographic, ellipsoid: Cartesian? = nil) -> Cartesian {

        let _longitude = toRadians(degrees: carto.longitude)
        let _latitude = toRadians(degrees: carto.latitude)
        return fromRadians(longitude: _longitude, latitude: _latitude, height: carto.height, ellipsoid: ellipsoid)
    }
    
    
    //MARK: Inner methods
    
    func toRadians(degrees: Double) -> Double{
      return degrees * RADIANS_PER_DEGREE
    }
    
    func fromRadians(longitude: Double, latitude: Double, height: Double = 0, ellipsoid: Cartesian? = nil) -> Cartesian {
        
        let radiiSquared = wgs84RadiiSquared
        
        var scratchN = Cartesian(x: 0, y: 0, z: 0)
        var scratchK = Cartesian(x: 0, y: 0, z: 0)
        
        let cosLatitude = cos(latitude)
        scratchN.x = cosLatitude * cos(longitude)
        scratchN.y = cosLatitude * sin(longitude)
        scratchN.z = sin(latitude)
        scratchN = normalize(scratchN)
        
        scratchK = multiplyComponents(left: radiiSquared, right: scratchN)
        let gamma = sqrt(dot(left: scratchN, right: scratchK))
        scratchK = divideByScalar(cartesian: scratchK, scalar: gamma)
        scratchN = multiplyByScalar(cartesian: scratchN, scalar: height)
        
        var result = Cartesian(x: 0, y: 0, z: 0)
        result = add(left: scratchK, right: scratchN)
        return result
    }
    
    func divideByScalar(cartesian: Cartesian, scalar: Double) -> Cartesian {
        var result = Cartesian(x: 0, y: 0, z: 0)
        result.x = cartesian.x / scalar
        result.y = cartesian.y / scalar
        result.z = cartesian.z / scalar
        return result
    }
    
    func add(left: Cartesian, right: Cartesian) -> Cartesian {
        var result = Cartesian(x: 0, y: 0, z: 0)
        result.x = left.x + right.x
        result.y = left.y + right.y
        result.z = left.z + right.z
        return result
      }

    private func magnitudeSquared(_ cartesian: Cartesian) -> Double {
        return (cartesian.x * cartesian.x + cartesian.y * cartesian.y + cartesian.z * cartesian.z)
    }

    private func magnitude(_ cartesian: Cartesian) -> Double  {
      return sqrt(magnitudeSquared(cartesian))
    }
    
    private func normalize(_ cartesian: Cartesian) -> Cartesian {
        
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        let _magnitude = magnitude(cartesian)
        
        result.x = cartesian.x / _magnitude
        result.y = cartesian.y / _magnitude
        result.z = cartesian.z / _magnitude
        
        return result
    }

    private func dot(left: Cartesian, right: Cartesian) -> Double {
      return left.x * right.x + left.y * right.y + left.z * right.z
    }
    
    private func sign(value: Double) -> Double {
        let _value = +value
        if (_value == 0) {
            return _value
        }
        return _value > 0 ? 1 : -1
    }
    
    private func subtract(left: Cartesian, right: Cartesian) -> Cartesian  {
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        
        result.x = left.x - right.x
        result.y = left.y - right.y
        result.z = left.z - right.z
        return result
    }
    
    private func multiplyComponents (left: Cartesian, right: Cartesian) -> Cartesian {
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        result.x = left.x * right.x
        result.y = left.y * right.y
        result.z = left.z * right.z
        return result
    }
    
    private func multiplyByScalar(cartesian: Cartesian, scalar: Double) -> Cartesian {
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        result.x = cartesian.x * scalar
        result.y = cartesian.y * scalar
        result.z = cartesian.z * scalar
        return result
    }
    
    private func clone(cartesian: Cartesian) -> Cartesian {
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        result.x = cartesian.x
        result.y = cartesian.y
        result.z = cartesian.z
        return result
    }

    
    private func scaleToGeodeticSurface (cartesian: Cartesian, oneOverRadii: Cartesian, oneOverRadiiSquared: Cartesian, centerToleranceSquared: Double) -> Cartesian? {
        
        var scaleToGeodeticSurfaceIntersection = Cartesian.init(x: 0, y: 0, z: 0)
        var scaleToGeodeticSurfaceGradient = Cartesian.init(x: 0, y: 0, z: 0)
        
        let positionX = cartesian.x
        let positionY = cartesian.y
        let positionZ = cartesian.z
        
        let oneOverRadiiX = oneOverRadii.x
        let oneOverRadiiY = oneOverRadii.y
        let oneOverRadiiZ = oneOverRadii.z
        
        let x2 = positionX * positionX * oneOverRadiiX * oneOverRadiiX
        let y2 = positionY * positionY * oneOverRadiiY * oneOverRadiiY
        let z2 = positionZ * positionZ * oneOverRadiiZ * oneOverRadiiZ
        
        // Compute the squared ellipsoid norm.
        let squaredNorm = x2 + y2 + z2
        let ratio = sqrt(1.0 / squaredNorm)
        
        // As an initial approximation, assume that the radial intersection is the projection point.
        let intersection = multiplyByScalar(cartesian: cartesian, scalar: ratio)
        
        scaleToGeodeticSurfaceIntersection = intersection
        
        // If the position is near the center, the iteration will not converge.
        if (squaredNorm < centerToleranceSquared) {
            
            return !ratio.isFinite ? nil : clone(cartesian: intersection)
        }
        
        let oneOverRadiiSquaredX = oneOverRadiiSquared.x
        let oneOverRadiiSquaredY = oneOverRadiiSquared.y
        let oneOverRadiiSquaredZ = oneOverRadiiSquared.z
        
        // Use the gradient at the intersection point in place of the true unit normal.
        // The difference in magnitude will be absorbed in the multiplier.
        var gradient = scaleToGeodeticSurfaceGradient
        gradient.x = intersection.x * oneOverRadiiSquaredX * 2.0
        gradient.y = intersection.y * oneOverRadiiSquaredY * 2.0
        gradient.z = intersection.z * oneOverRadiiSquaredZ * 2.0
        
        // Compute the initial guess at the normal vector multiplier, lambda.
        var lambda = ((1.0 - ratio) * magnitude(cartesian)) / (0.5 * magnitude(gradient))
        var correction = 0.0
        
        var func_res: Double = 0
        var denominator: Double = 0
        var xMultiplier: Double = 0
        var yMultiplier: Double = 0
        var zMultiplier: Double = 0
        var xMultiplier2: Double = 0
        var yMultiplier2: Double = 0
        var zMultiplier2: Double = 0
        var xMultiplier3: Double = 0
        var yMultiplier3: Double = 0
        var zMultiplier3: Double = 0
        
        repeat {
            lambda -= correction;
            
            xMultiplier = 1.0 / (1.0 + lambda * oneOverRadiiSquaredX)
            yMultiplier = 1.0 / (1.0 + lambda * oneOverRadiiSquaredY)
            zMultiplier = 1.0 / (1.0 + lambda * oneOverRadiiSquaredZ)
            
            xMultiplier2 = xMultiplier * xMultiplier
            yMultiplier2 = yMultiplier * yMultiplier
            zMultiplier2 = zMultiplier * zMultiplier
            
            xMultiplier3 = xMultiplier2 * xMultiplier
            yMultiplier3 = yMultiplier2 * yMultiplier
            zMultiplier3 = zMultiplier2 * zMultiplier
            
            func_res = x2 * xMultiplier2 + y2 * yMultiplier2 + z2 * zMultiplier2 - 1.0

            denominator = x2 * xMultiplier3 * oneOverRadiiSquaredX + y2 * yMultiplier3 * oneOverRadiiSquaredY + z2 * zMultiplier3 * oneOverRadiiSquaredZ
            
            let derivative = -2.0 * denominator
            
            correction = func_res / derivative
        } while (abs(func_res) > EPSILON12)
        
        
        
        var result = Cartesian.init(x: 0, y: 0, z: 0)
        result.x = positionX * xMultiplier
        result.y = positionY * yMultiplier
        result.z = positionZ * zMultiplier
        return result
    }

}

