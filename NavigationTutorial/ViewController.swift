 //
//  ViewController.swift
//  NavigationTutorial
//
//  Created by Nathan Hsu on 2018-04-05.
//  Copyright © 2018 Nathan Hsu. All rights reserved.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import QuartzCore

class ViewController: UIViewController  {

    var mapView = NavigationMapView()
    var waypointsManager = WaypointsManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a MapView and configure options
        mapView = NavigationMapView(frame: view.bounds)
        // Delegate methods in extension below
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        // Makes map auto resize after rotating device
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(mapView)
        
        // Create gesture recognizer to drop waypoint pin
        let setWaypoint = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(setWaypoint)
        
        // Style the buttons
        calculateRouteButton.layer.cornerRadius = 5
        startNavigationButton.layer.cornerRadius = 5
        clearWaypointsButton.layer.cornerRadius = 5
        
        view.bringSubview(toFront: calculateRouteButton)
        view.bringSubview(toFront: startNavigationButton)
        view.bringSubview(toFront: clearWaypointsButton)
        
    }
    
    // Called by gesture recognizer 'setWayPoint' created above
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        dropWaypointPin(sender: sender)
        calculateRoute()
    }

    //MARK: Buttons Outlets
    
    @IBOutlet weak var calculateRouteButton: UIButton!
    @IBOutlet weak var startNavigationButton: UIButton!
    @IBOutlet weak var clearWaypointsButton: UIButton!
    
    //MARK: Button Actions
    
    @IBAction func calculateRouteButtonPressed(_ sender: UIButton) {
        calculateRoute()
    }

    @IBAction func startNavigationButtonPressed(_ sender: UIButton) {
        if let calculatedRoute = waypointsManager.directionsRoute {
            let navigationViewController = NavigationViewController(for: calculatedRoute)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }

    @IBAction func clearWaypointsButtonPressed(_ sender: UIButton) {
        clearRoute()
    }

}

 // After annotation drag ends, re-calculate route. Adopting our custom protocol.
 extension ViewController: AnnotationViewDelegate {
    
    func didEndDragging() {
        calculateRoute()
    }
    
 }
 
 // MARK: Routing methods
 extension ViewController {
    
    func dropWaypointPin(sender: UIGestureRecognizer ) {
        
        guard sender.state == .began else { return }
        
        // Converts point where user did long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation using coordinates and add it to map
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Delete"
        mapView.addAnnotation(annotation)
        
        // Give the user more haptic feedback when they drop the annotation.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
            hapticFeedback.impactOccurred()
        }
    }
    
    func clearRoute() {
        
        // Clear annotations from array maintained by mapView
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        // Delete generated route from waypointsManager
        waypointsManager.directionsRoute = nil
        
        // Delete the drawn line on the mapView
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = nil
        }
        
    }
    
    func calculateRoute() {
        
        // Capture the user's current location
        if let userLocation = mapView.userLocation?.coordinate {
            let waypoint = Waypoint(coordinate: userLocation, coordinateAccuracy: -1, name: nil)
            waypointsManager.userLocation = waypoint
        }
        
        // Capture the annotations on the map
        if let annotations = mapView.annotations {
            
            guard annotations.count > 0 else {
                print("No destination found")
                return
            }
            
            print("There are \(annotations.count) annotations, lets go ahead.")
            
            // Convert annotations to waypoints
            var waypoints: [Waypoint] = []
            
            for annotation in annotations {
                let waypoint = Waypoint(coordinate: annotation.coordinate, coordinateAccuracy: -1, name: nil)
                waypoints.append(waypoint)
            }
            
            let waypointsInCorrectOrder = waypoints.reversed() as Array
            
            // Give the waypoints to waypoints manager
            waypointsManager.waypoints = waypointsInCorrectOrder
            
        } else {
            
            // this will execude if annotations.count is 0
            clearRoute()
            return
            
        }
        
        // Try to calculate route. If success, draw it.
        print("About to call second part of calculateRoute")
        
        calculateRoute { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
        
    }
    
    func calculateRoute(completion: @escaping (Route?, Error?) -> ()) {
        
        // Get all waypoints including start, middle, and end from waypointsManager
        let allWaypoints = waypointsManager.createRoutingWaypoints()
        
        guard allWaypoints.count > 1 else {
            clearRoute()
            return
        }
        
        // Specify waypoints and that the mode is cycling. This is an API signature from Mapbox.
        let options = NavigationRouteOptions(waypoints: allWaypoints, profileIdentifier: .cycling)
        
        // Generate the route object using the options
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.waypointsManager.directionsRoute = routes?.first
            
            // Draw the route
            if let route = self.waypointsManager.directionsRoute {
                self.drawRoute(route: route)
            }
        }
    }
    
    func drawRoute(route: Route) {
        
        guard route.coordinateCount > 0 else {
            return
        }
        
        print("Distance: \(route.distance)")
        print("Estimated Travel Time: \(route.expectedTravelTime)")
        
        // Convert the route's coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        }
        else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and width
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = MGLStyleValue(rawValue: 3)
            
            // Add the source and style layer of the route line to the map
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    
 }

 // MARK: MGLMapViewDelegate methods
 extension ViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        mapView.removeAnnotation(annotation)
        calculateRoute()
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard annotation is MGLPointAnnotation else {
            return nil
        }
        
        // For better performance, always try to reuse existing annotations. To use multiple different annotation views, change the reuse identifier for each.
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") as? DraggableAnnotationView {
            //TODO: assign delegrate for annotationView
            annotationView.delegate = self
            return annotationView
        } else {
            let annotationView = DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 20)
            annotationView.delegate = self
            return annotationView
        }
    }

 }

























