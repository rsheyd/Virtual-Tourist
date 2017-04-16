//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Roman Sheydvasser on 4/9/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    var selectedPinLatitude: CLLocationDegrees!
    var selectedPinLongitude: CLLocationDegrees!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "wasOpened", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        loadLastMapView()
        loadSavedPins(fr)
        longPressRecognizerSetup()
    }
    
    func loadLastMapView() {
        if let _ = UserDefaults.standard.value(forKey: "mapLatitude") {
            let span = MKCoordinateSpanMake(UserDefaults.standard.value(forKey: "mapLatitudeDelta") as! CLLocationDegrees, UserDefaults.standard.value(forKey: "mapLongitudeDelta") as! CLLocationDegrees)
            let centerCoord = CLLocationCoordinate2DMake(UserDefaults.standard.value(forKey: "mapLatitude") as! CLLocationDegrees, UserDefaults.standard.value(forKey: "mapLongitude") as! CLLocationDegrees)
            let region = MKCoordinateRegionMake(centerCoord, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func loadSavedPins(_ request: NSFetchRequest<NSFetchRequestResult>) {
        
        request.returnsObjectsAsFaults = false
        
        do {
            
            let results = try fetchedResultsController?.managedObjectContext.fetch(request)
            
            if results!.count > 0 {
                
                for result in results as! [NSManagedObject] {
                    
                    guard let pinLatitude = result.value(forKey: "latitude") as? Double, let pinLongitude = result.value(forKey: "longitude") as? Double else {
                        print("Invalid pin found. Skipping.")
                        continue
                    }
                    
                    let pin = MKPointAnnotation()
                    pin.coordinate = CLLocationCoordinate2DMake(pinLatitude, pinLongitude)
                    mapView.addAnnotation(pin)
                    
                }
            } else {
                print("No pins could be found in Core Data.")
            }
            
        } catch {
            print("Request for pin in Core Data could not be processed.")
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //save map view so same place will be loaded when app is reopened
        UserDefaults.standard.set(mapView.region.center.latitude as Double, forKey: "mapLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude as Double, forKey: "mapLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta as Double, forKey: "mapLatitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta as Double, forKey: "mapLongitudeDelta")
    }
    
    func longPressRecognizerSetup() {
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)
    }
    
    func handleLongPress(_ getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .began { return }
        
        let touchPoint = getstureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = touchMapCoordinate
        mapView.addAnnotation(pin)
        
        let newPin = Pin(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude, wasOpened: false, context: fetchedResultsController!.managedObjectContext)
        print("just created new pin in core data: \(newPin)")
        delegate.stack.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "toPhotoAlbum" {
            
            if let photoAlbumVC = segue.destination as? PhotoAlbumVC {
                
                //do fetch request to get specific pin based on lat and lon
                let frPins = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
                let predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", argumentArray: [selectedPinLatitude, selectedPinLongitude])
                frPins.predicate = predicate
                
                
                guard let fetchedResultsController = fetchedResultsController,
                    let pins = try? fetchedResultsController.managedObjectContext.fetch(frPins),
                    let pin = pins.first as? Pin else {
                    print("Pin not found at \(selectedPinLatitude) and \(selectedPinLongitude)")
                    return
                }
                
                //do another fetch request to get the photos, and use the pin from prevoius request to filter the photos
                
                let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: false)]
                //"pin" is the relationship name (check the relationship name under "relationships" in Photo entity)
                let photoPredicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
                fr.predicate = photoPredicate
                let photos = try? fetchedResultsController.managedObjectContext.fetch(fr)
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:fetchedResultsController.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                
                // Inject it into the photoAlbumVC
                photoAlbumVC.fetchedResultsController = fc
                
                // Inject the pin too!
                photoAlbumVC.pin = pin
                
                print("photos count = \(String(describing: photos?.count))")
                
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        selectedPinLatitude = view.annotation?.coordinate.latitude
        selectedPinLongitude = view.annotation?.coordinate.longitude
        performSegue(withIdentifier: "toPhotoAlbum", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

