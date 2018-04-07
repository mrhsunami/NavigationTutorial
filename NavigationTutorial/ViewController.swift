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

    //MARK: Buttons
    @IBOutlet weak var calculateRouteButton: UIButton!
    @IBAction func calculateRouteButtonPressed(_ sender: UIButton) {
        calculateRoute(with: waypoints) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
    }
    
    //        calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
    //            if error != nil {
    //                print("Error calculating route")
    //            }
    //        }
    var mapView = NavigationMapView()
    var directionsRoute: Route?
    var waypoints: [Waypoint] = []
    
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
        
        calculateRouteButton.layer.cornerRadius = 5

        view.bringSubview(toFront: calculateRouteButton)
        
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
        annotation.title = "Start navigation"
        mapView.addAnnotation(annotation)
        
        // Create a waypoint and add it to waypoint array
        let newWaypoint = Waypoint(coordinate: coordinate, coordinateAccuracy: -1, name: nil)
        waypoints.append(newWaypoint)
        
//        // Calculate the route from the user's location to the set destination
//        calculateRoute(from: (mapView.userLocation!.coordinate), to: annotation.coordinate) { (route, error) in
//            if error != nil {
//                print("Error calculating route")
//            }
//        }
    }
    
//    func calculateRoute(from origin: CLLocationCoordinate2D,
//                        to destination: CLLocationCoordinate2D,
//                        completion: @escaping (Route?, Error?) -> ()) {
//        // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
//        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
//        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
//
//        // Specify that the route is intended for bikes
//        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .cycling)
//
//        // Generate the route object and draw it on the map
//        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
//            self.directionsRoute = routes?.first
//            // Draw the route on the map after creating it
//            self.drawRoute(route: self.directionsRoute!)
//        }
//    }
    
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




}





























