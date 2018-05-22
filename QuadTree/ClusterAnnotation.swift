import MapKit

class ClusterAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String? = ""
    var subtitle: String? = ""
    let count: Int
    
    init(_ coordinate: CLLocationCoordinate2D, _ count: Int){
        self.coordinate = coordinate
        self.count = count
        self.title = "\(count) hotels in this area"
    }
    
    override var hashValue: Int {
        let toHash = String(format: "%.5F%.5F", coordinate.latitude, coordinate.longitude)
        return toHash.hashValue
    }
    
    override func isEqual(_ otherObject: Any?) -> Bool {
        if !(otherObject is ClusterAnnotation) {
            return false
        }
        
        guard let other = otherObject as! ClusterAnnotation? else {
            return false
        }
        
        return hashValue == other.hashValue
    }
}
