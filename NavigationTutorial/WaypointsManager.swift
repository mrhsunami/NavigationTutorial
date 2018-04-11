//
//  WaypointsManager.swift
//  NavigationTutorial
//
//  Created by Nathan Hsu on 2018-04-10.
//  Copyright © 2018 Nathan Hsu. All rights reserved.
//

import Foundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class WaypointsManager {
 
    var userLocation: Waypoint? = nil
    var waypoints: [Waypoint] = []
    var directionsRoute: Route?
    
    
    func createRoutingWaypoints() -> [Waypoint] {
        var waypoints: [Waypoint] = []
        if let userLocation = self.userLocation {
            waypoints.append(userLocation)
        }
        waypoints.append(contentsOf: self.waypoints)
        return waypoints
    }
}


