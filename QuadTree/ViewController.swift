import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    let quadtree = QuadTree<Accommodation>(BoundingBox(19, -166, 72, -50))
    static let AnnotatioViewReuseID = "AnnotatioViewReuseIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadHotelData()
        
        // Centre the map to the middle of the USA because all the data comes
        // from there. In case you are (for instance) from Europe the map will
        // be centered by default to the position where you currently are. While
        // experimenting with the code this is annoying because you have to drag
        // the map all the time. Thus this code snippet makes our life more
        // relaxed.
        let coordinates = CLLocationCoordinate2DMake(41.225884, -97.942760)
        let region = MKCoordinateRegionMakeWithDistance(coordinates, 5000000, 5000000)
        self.mapView.setRegion(region, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func loadHotelData() {
        var totalAccommodations = 0
        var failedToImport      = 0
        let accommodationsUrl   = Bundle.main.url(forResource: "USA-HotelMotel", withExtension: "csv")
        let accommodations      = try! String(contentsOf: accommodationsUrl!, encoding: String.Encoding.utf8)
        var minLongitude        = 1000.0
        var maxLongitude        = -1000.0
        var minLatitude         = 1000.0
        var maxLatitude         = -1000.0
        
        for accommodation in accommodations.split(separator: "\n") {
            let data      = accommodation.split(separator: ",")
            let longitude = Double(String(data[0]).trimmingCharacters(in: [" "]))!
            let latitude  = Double(String(data[1]).trimmingCharacters(in: [" "]))!
            let name      = String(data[2]).trimmingCharacters(in: [" "])
            // let country   = String(data[3]).trimmingCharacters(in: [" "])
            let phone     = String(data[4]).trimmingCharacters(in: [" "])
            
            if longitude < minLongitude {
                minLongitude = longitude
            }
            
            if longitude > maxLongitude {
                maxLongitude = longitude
            }
            
            if latitude < minLatitude {
                minLatitude = latitude
            }
            
            if latitude > maxLatitude {
                maxLatitude = latitude
            }
            
            if !quadtree.insert(at: Point(latitude, longitude), data: Accommodation(name, phone)) {
                print("ERROR: can not insert: \(String(accommodation)))")
                failedToImport += 1
            }
            
            totalAccommodations += 1
        }
        
        print("Imported accommodations = \(totalAccommodations - failedToImport) of \(totalAccommodations)")
        print("Latitude range          = \(minLatitude) - \(maxLatitude)")
        print("Longitude range         = \(minLongitude) - \(maxLongitude)")
    }

    func zoomLevel(fromZoomScale scale: MKZoomScale) -> Int {
        let totalTilesAtMaxZoom = MKMapSizeWorld.width / 256.0
        let zoomLevelAtMaxZoom = Int(log2(totalTilesAtMaxZoom))
        let zoomLevel = max(0, zoomLevelAtMaxZoom + Int(floor(log2f(Float(scale)) + 0.5)))
        
        return zoomLevel
    }

    func cellSize(forZoomScale zoomScale: MKZoomScale) -> Double {
        let zoomLvl = zoomLevel(fromZoomScale: zoomScale)
        
        switch zoomLvl {
        case 13, 14, 15:
            return 64
        case 16, 17, 18:
            return 32
        case 19:
            return 16
        default:
            return 88
        }
    }
    
    func clusteredAnnotations(withinMapRect rect: MKMapRect, withZoomScale zoomScale: Double) -> [ClusterAnnotation] {
        let cellSize = self.cellSize(forZoomScale: CGFloat(zoomScale))
        let scaleFactor: Double = zoomScale / cellSize
        let minX = Int(floor(MKMapRectGetMinX(rect) * scaleFactor))
        let maxX = Int(floor(MKMapRectGetMaxX(rect) * scaleFactor))
        let minY = Int(floor(MKMapRectGetMinY(rect) * scaleFactor))
        let maxY = Int(floor(MKMapRectGetMaxY(rect) * scaleFactor))
    
        var clusteredAnnotations = [ClusterAnnotation]()
        for x in minX...maxX {
            for y in minY...maxY {
                let mapRect: MKMapRect = MKMapRectMake(Double(x) / scaleFactor, Double(y) / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor)
                var totalX = 0.0
                var totalY = 0.0
                var count  = 0
                var names: [String] = []
                var phoneNumbers: [String] = []
                
                quadtree.gatherData(in: mapRect) { hotel, coordinate in
                    totalX += coordinate.x
                    totalY += coordinate.y
                    count += 1
                    names.append(hotel.name)
                    phoneNumbers.append(hotel.phone)
                }
                
                if (count == 1) {
                    let coordinate = CLLocationCoordinate2DMake(totalX, totalY)
                    let annotation = ClusterAnnotation(coordinate, count)
                    annotation.title = names.last!
                    annotation.subtitle = phoneNumbers.last!
                    clusteredAnnotations.append(annotation)
                }
    
                if (count > 1) {
                    let coordinate = CLLocationCoordinate2DMake(totalX / Double(count), totalY / Double(count))
                    let annotation = ClusterAnnotation(coordinate, count)
                    clusteredAnnotations.append(annotation)
                }
            }
        }
    
        return clusteredAnnotations
    }
    
    func updateMapViewAnnotations(with annotations: [ClusterAnnotation]) {
        var before2 = Set<AnyHashable>(mapView.annotations as! [ClusterAnnotation])
        before2.remove(mapView.userLocation)
        let after2 = Set<AnyHashable>(annotations)
        
        var toKeep2 = Set<AnyHashable>(before2)
        toKeep2 = toKeep2.intersection(after2)
        
        var toAdd2 = Set<AnyHashable>(after2)
        toAdd2.subtract(toKeep2)
        
        var toRemove2 = Set<AnyHashable>(before2)
        toRemove2.subtract(after2)
        
        OperationQueue.main.addOperation({() -> Void in
            self.mapView.addAnnotations(Array(toAdd2) as! [MKAnnotation])
            self.mapView.removeAnnotations(Array(toRemove2) as! [MKAnnotation])
        })
    }
    
    func addBounceAnnimation(to view: UIView) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale");
        bounceAnimation.values = [0.05, 1.1, 0.9, 1]
        bounceAnimation.duration = 0.6
        
        var timingFunctions = [CAMediaTimingFunction]()
        bounceAnimation.values?.forEach { _ in
            timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        
        bounceAnimation.timingFunctions = timingFunctions
        bounceAnimation.isRemovedOnCompletion = false
        
        view.layer.add(bounceAnimation, forKey: "bounce")
    }
    
    // MARK: - MapView
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let boundsWidth = Double(self.mapView.bounds.size.width)
        let visibleMapRectWidth = self.mapView.visibleMapRect.size.width
        
        let oq = OperationQueue()
        oq.addOperation() {
            let scale: Double = boundsWidth / visibleMapRectWidth
            let annotations = self.clusteredAnnotations(withinMapRect: self.mapView.visibleMapRect, withZoomScale: scale)
            self.updateMapViewAnnotations(with: annotations)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: ViewController.AnnotatioViewReuseID) as? ClusterAnnotationView
        if annotationView == nil {
            annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: ViewController.AnnotatioViewReuseID)
        }
        annotationView?.canShowCallout = true
        annotationView?.count = (annotation as! ClusterAnnotation).count
        
        return annotationView
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            addBounceAnnimation(to: view)
        }
    }
}

