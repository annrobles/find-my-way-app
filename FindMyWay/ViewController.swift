//
//  ViewController.swift
//  FindMyWay
//
//  Created by Ann Robles on 1/15/23.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var showRouteButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var transportType: UISegmentedControl!
    
    var locationManager = CLLocationManager()
    var destination: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        mapView.isZoomEnabled = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        stackView.layer.cornerRadius = 5
        
        showRouteButton.isHidden = true
        addDoubleTap()
    }
    
    @IBAction func drawRoute(_ sender: UIButton) {
        if self.transportType.selectedSegmentIndex == 1 {
            drawRoute(transportType:  .walking)
        }
        else {
            drawRoute(transportType:  .automobile)
        }
    }
    
    @IBAction func zoomOutButtonClicked(sender: UIButton) {
        let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta*2, longitudeDelta: mapView.region.span.longitudeDelta*2)
        let region = MKCoordinateRegion(center: mapView.region.center, span: span)

        mapView.setRegion(region, animated: true)
    }

    @IBAction func zoomInButtonClicked(sender: UIButton) {
        let span = MKCoordinateSpan(latitudeDelta: mapView.region.span.latitudeDelta/2, longitudeDelta: mapView.region.span.longitudeDelta/2)
        let region = MKCoordinateRegion(center: mapView.region.center, span: span)

        mapView.setRegion(region, animated: true)
    }
    
    @IBAction func transportTypeSegmentClicked(_ sender: UISegmentedControl) {
        if destination != nil {
            if sender.selectedSegmentIndex == 1 {
                drawRoute(transportType:  .walking)
            }
            else {
                drawRoute(transportType:  .automobile)
            }
        }
    }
    
    func drawRoute(transportType: MKDirectionsTransportType?) {
        mapView.removeOverlays(mapView.overlays)
        
        let sourcePlaceMark = MKPlacemark(coordinate: locationManager.location!.coordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = transportType ?? .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            let route = directionResponse.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
        }
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        
        removePin()
        
        annotation.title = "My Destination"
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        destination = coordinate
        showRouteButton.isHidden = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        print(userLocation)
        displayLocation(latitude: latitude, longitude: longitude)
    }
    
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees) {
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees =  0.05
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        switch annotation.title {
        case "My Destination":
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            annotationView.pinTintColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
            return annotationView
        default:
            return nil
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if self.transportType.selectedSegmentIndex == 0 {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.systemRed
            renderer.lineWidth = 5
            return renderer
        }
        else {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
            renderer.lineWidth = 5
            renderer.lineDashPattern = [0, 10]
            return renderer
        }
        
        return MKOverlayRenderer()
    }
}
