# CartesianSwift

Class that allow you to convert Cartesian to cartographic coordinates and back in Swift. Based on Cesium library.
 
 
 
Code example:

From Cartesian to Cartographic coordinates:
<code>
  
    let cartesianPoint = Cartesian.init(x: 4397821.849148, y: 3089527.636507, z: 3423708.737369)
  
    if let cartography = Cesium.shared.fromCartesian(cartesian: cartesianPoint)

    {
        let coordinates = CLLocationCoordinate2D.init(latitude: cartography.latitude, longitude: cartography.longitude)
    }
  
</code>


From Cartographic coordinates to Cartesian:
<code>
  
    let cartographic = Cartographic(longitude: 29.954285, latitude: 31.183833, height: 0)
    
    // if you set ellipsoid to 'nil' -> it will be used Earth-sized ellipsoid by WGS84 standard
  
    let cartesianPoint = Cesium.shared.cartesianFromCartographic(carto: carto, ellipsoid: nil)

</code>
