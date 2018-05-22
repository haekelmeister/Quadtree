import MapKit

class ClusterAnnotationView: MKAnnotationView {
    private var countValue              = Int(0)
    private var countLabel              = UILabel()
    private static let scaleFactorAlpha = Float(0.3)
    private static let scaleFactorBeta  = Float(0.4)
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.clear
        self.setupLabel()
        self.count = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel() {
        self.countLabel                           = UILabel(frame: self.frame)
        self.countLabel.backgroundColor           = UIColor.clear
        self.countLabel.textColor                 = UIColor.white
        self.countLabel.textAlignment             = .center
        self.countLabel.shadowColor               = UIColor(white: 0.0, alpha: 0.75)
        self.countLabel.shadowOffset              = CGSize(width: 0, height: -1)
        self.countLabel.adjustsFontSizeToFitWidth = true
        self.countLabel.numberOfLines             = 1
        self.countLabel.font                      = UIFont.boldSystemFont(ofSize: 12)
        self.countLabel.baselineAdjustment        = .alignCenters
        self.addSubview(self.countLabel)
    }
    
    private func scaledValue(for count: Int) -> Float {
        let value = Float(count)
        return Float(1.0 / (1.0 + expf(-1 * ClusterAnnotationView.scaleFactorAlpha * powf(value, ClusterAnnotationView.scaleFactorBeta))))
    }
    
    private func center(of rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    
    private func centerRect(rect: CGRect, center: CGPoint) -> CGRect {
        let r = CGRect(x: center.x - rect.size.width / 2.0, y: center.y - rect.size.height / 2.0, width: rect.size.width, height: rect.size.height)
        return r
    }
    
    var count : Int {
        get {
            return countValue
        }
        
        set {
            self.countValue = newValue
            let dimension = CGFloat(roundf(44 * scaledValue(for: count)))
            let newBounds = CGRect(x: 0, y: 0, width: dimension, height: dimension)
            frame = centerRect(rect: newBounds, center: center)
            let newLabelBounds = CGRect(x: 0, y: 0, width: newBounds.size.width / 1.3, height: newBounds.size.height / 1.3)
            countLabel.frame = centerRect(rect: newLabelBounds, center: center(of: newBounds))
            countLabel.text = "\(self.count)"
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Graphic context not found")
        }
        
        context.setAllowsAntialiasing(true)
        let outerCircleStrokeColor = UIColor(white: 0, alpha: 0.25)
        let innerCircleStrokeColor = UIColor.white
        let innerCircleFillColor   = UIColor(red: 1.0, green: 0.3725, blue: 0.1467, alpha: 1.0)
        let circleFrame            = rect.insetBy(dx: 4, dy: 4)
        outerCircleStrokeColor.setStroke()
        context.setLineWidth(5.0)
        context.strokeEllipse(in: circleFrame)
        innerCircleStrokeColor.setStroke()
        context.setLineWidth(4)
        context.strokeEllipse(in: circleFrame)
        innerCircleFillColor.setFill()
        context.fillEllipse(in: circleFrame)
    }
}
