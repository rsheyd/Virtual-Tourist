//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Roman Sheydvasser on 4/9/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadLastMapView()
    }
    
    func loadLastMapView() {
        if let _ = UserDefaults.standard.value(forKey: "mapLatitude") {
            let span = MKCoordinateSpanMake(UserDefaults.standard.value(forKey: "mapLatitudeDelta") as! CLLocationDegrees, UserDefaults.standard.value(forKey: "mapLongitudeDelta") as! CLLocationDegrees)
            let centerCoord = CLLocationCoordinate2DMake(UserDefaults.standard.value(forKey: "mapLatitude") as! CLLocationDegrees, UserDefaults.standard.value(forKey: "mapLongitude") as! CLLocationDegrees)
            let region = MKCoordinateRegionMake(centerCoord, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //save map view so same place will be loaded when app is reopened
        UserDefaults.standard.set(mapView.region.center.latitude as Double, forKey: "mapLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude as Double, forKey: "mapLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta as Double, forKey: "mapLatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta as Double, forKey: "mapLongitudeDelta")
    }
}

