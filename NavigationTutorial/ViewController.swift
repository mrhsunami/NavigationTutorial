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

class ViewController: UIViewController, MGLMapViewDelegate {

    var mapView = NavigationMapView()
    var directionsRoute: Route?
    
//    var annotations: [MGLPointAnnotation] = []
    var userLocation: [Waypoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a MapView and configure options
        mapView = NavigationMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        
        view.addSubview(mapView)
        
        // Add a gesture recognizer
        let setDestination = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(setDestination)
        
        // Style the buttons
        calculateRouteButton.layer.cornerRadius = 5
        startNavigationButton.layer.cornerRadius = 5
        clearWaypointsButton.layer.cornerRadius = 5
        
        view.bringSubview(toFront: calculateRouteButton)
        view.bringSubview(toFront: startNavigationButton)
        view.bringSubview(toFront: clearWaypointsButton)
        
    }
    
    //MARK: Buttons
    @IBOutlet weak var calculateRouteButton: UIButton!
    @IBOutlet weak var startNavigationButton: UIButton!
    @IBOutlet weak var clearWaypointsButton: UIButton!
    
    @IBAction func calculateRouteButtonPressed(_ sender: UIButton) {
        
        // insert current user location as start point if available
        if let userLocation = mapView.userLocation?.coordinate {
            let firstWaypoint = Waypoint(coordinate: userLocation, coordinateAccuracy: -1, name: nil)
            self.userLocation = [firstWaypoint]
        }
        
        var waypoints: [Waypoint] = []
        
        if let annotations = mapView.annotations {
            guard annotations.count > 0 else {
                print("No destination found")
                return
            }
            for annotation in annotations {
                let waypoint = Waypoint(coordinate: annotation.coordinate, coordinateAccuracy: -1, name: nil)
                waypoints.append(waypoint)
            }
        }
        
        
        let finalWaypoints = userLocation + waypoints.reversed()
        
        calculateRoute(with: finalWaypoints) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
    }

    @IBAction func startNavigationButtonPressed(_ sender: UIButton) {
        if let calculatedRoute = directionsRoute {
            let navigationViewController = NavigationViewController(for: calculatedRoute)
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }

    @IBAction func clearWaypointsButtonPressed(_ sender: UIButton) {
        
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        
        directionsRoute = nil
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = nil
        }
    }
    
    //MARK: functions
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation and add it to map
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Delete"
//        annotations.append(annotation)
        mapView.addAnnotation(annotation)
        
    }
    
    func calculateRoute(with waypoints: [Waypoint],
                            completion: @escaping (Route?, Error?) -> ()) {

            // Specify that the route is intended for bikes
            let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .cycling)
    
            // Generate the route object and draw it on the map
            _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
                self.directionsRoute = routes?.first
                // Draw the route on the map after creating it
                self.drawRoute(route: self.directionsRoute!)
            }
        }

    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        // Convert the route's coordinates into a polyline
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // If there's already a route line on the map, reset its shape to the new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
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
    
    // Implement the delegate method that allows annotations to show callouts when tapped
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        
        mapView.removeAnnotation(annotation)

        
    }




}





























