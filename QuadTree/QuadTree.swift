import MapKit

class Point {
    let x: Double
    let y: Double
    
    required init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
    
    convenience init(_ x: Int, _ y: Int) {
        self.init(Double(x), Double(y))
    }
}

class BoundingBox: CustomStringConvertible {
    let x0: Double
    let y0: Double
    let xf: Double
    let yf: Double
    
    init?() {
        return nil
    }
    
    init(_ x0: Double, _ y0: Double,_ xf: Double,_ yf: Double) {
        self.x0 = x0
        self.y0 = y0
        self.xf = xf
        self.yf = yf
    }
    
    var description: String {
        return "\(String(format: "%.5f", x0)),\(String(format: "%.5f", y0)) - \(String(format: "%.5f", xf)),\(String(format: "%.5f", yf))"
    }
    
    func contains(_ point: Point) -> Bool {
        let containsX: Bool = self.x0 <= point.x && point.x <= self.xf;
        let containsY: Bool = self.y0 <= point.y && point.y <= self.yf;
        return containsX && containsY;
    }
    
    func intersects(_ other: BoundingBox) -> Bool {
        return self.x0 <= other.xf && self.xf >= other.x0 && self.y0 <= other.yf && self.yf >= other.y0
    }
}

class Leaf<T> {
    let point: Point
    let data: T
    
    init?() {
        return nil
    }
    
    required init(_ point: Point, _ data: T) {
        self.point = point
        self.data = data
    }
    
    convenience init(_ x: Double, _ y: Double, _ data: T) {
        self.init(Point(x, y), data)
    }
}

class Node<T> {
    var northWest: Node<T>? = nil
    var northEast: Node<T>? = nil
    var southWest: Node<T>? = nil
    var southEast: Node<T>? = nil
    let box: BoundingBox
    let capacity: Int = 4
    var leafs: [Leaf<T>]
    
    init(_ boundingBox: BoundingBox) {
        self.box = boundingBox
        self.leafs = Array<Leaf<T>>()
    }
    
    private func subdivide()
    {
        let xMid: Double = (box.xf + box.x0) / 2.0
        let yMid: Double = (box.yf + box.y0) / 2.0
        
        northWest = Node<T>(BoundingBox(box.x0, yMid, xMid, box.yf))
        northEast = Node<T>(BoundingBox(xMid, yMid, box.xf, box.yf))
        southWest = Node<T>(BoundingBox(box.x0, box.y0, xMid, yMid))
        southEast = Node<T>(BoundingBox(xMid, box.y0, box.xf, yMid))
    }

    func insert(_ data: Leaf<T>) -> Bool {
        
        if !box.contains(data.point) {
            return false
        }
        
        if leafs.count < capacity {
            leafs.append(data)
            return true
        }
        
        if northWest == nil {
            subdivide()
        }
        
        if northWest?.insert(data) == true {
             return true
        }
        if northEast?.insert(data) == true {
             return true
        }
        if southWest?.insert(data) == true {
            return true
        }
        if southEast?.insert(data) == true {
            return true
        }
        
        return false
    }
    
    func gatherData(in searchBox: BoundingBox,_ results: (T, Point) -> Void) {
        
        if !self.box.intersects(searchBox) {
            return
        }
    
        for bucket in leafs {
            if searchBox.contains(bucket.point) {
                results(bucket.data, bucket.point)
            }
        }

        if northWest == nil {
            return
        }
    
        northWest?.gatherData(in: searchBox, results)
        northEast?.gatherData(in: searchBox, results)
        southWest?.gatherData(in: searchBox, results)
        southEast?.gatherData(in: searchBox, results)
    }
}

class QuadTree<T> {
    let rootNode: Node<T>
    
    init?() {
        return nil
    }
    
    init(_ boundingBox: BoundingBox) {
        rootNode = Node<T>(boundingBox)
    }
    
    func insert(x: Int, y: Int, data: T) -> Bool {
        return self.insert(at: Point(x, y), data: data)
    }
    
    func insert(at coordinate:Point, data:T) -> Bool {
        return rootNode.insert(Leaf<T>(coordinate, data))
    }
    
    func gatherData(in mapRect: MKMapRect,_ results: (T, Point) -> Void) {
        let topLeft: CLLocationCoordinate2D = MKCoordinateForMapPoint(mapRect.origin)
        let botRight: CLLocationCoordinate2D = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(mapRect), MKMapRectGetMaxY(mapRect)))
        let minLat: CLLocationDegrees = botRight.latitude
        let maxLat: CLLocationDegrees = topLeft.latitude
        let minLon: CLLocationDegrees = topLeft.longitude
        let maxLon: CLLocationDegrees = botRight.longitude
        
        self.gatherData(in: BoundingBox(minLat, minLon, maxLat, maxLon), results)
    }
    
    func gatherData(in boundingBox: BoundingBox,_ results: (T, Point) -> Void) {
        self.rootNode.gatherData(in: boundingBox, results)
    }
}
