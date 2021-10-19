# CartesianSwift

Class that allow you to convert Cartesian to cartographic coordinates in Swift. Based on Cesium library.

Code example:

<code>
  
    let cartesianPoint = Cartesian.init(x: 4397821.849148, y: 3089527.636507, z: 3423708.737369)
  
    if let cartography = Cesium.shared.fromCartesian(cartesian: cartesianPoint)

      {
     
          let coordinates = CLLocationCoordinate2D.init(latitude: cartography.latitude, longitude: cartography.longitude)

      }
  
</code>
