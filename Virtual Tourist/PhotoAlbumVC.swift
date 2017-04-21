//
//  PhotoAlbumVC.swift
//  Virtual Tourist
//
//  Created by Roman Sheydvasser on 4/9/17.
//  Copyright © 2017 RLabs. All rights reserved.
//
// remove photosCount


import UIKit
import CoreData

class PhotoAlbumVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    let webClient = WebClient.sharedInstance()
    var photosCount = 0
    var photoObjects: [NSManagedObject] = []
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        self.photoObjects = []
        self.collectionView.reloadData()
        deleteSavedImages()
        downloadNewImages()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Get photos from Core Data
        getSavedImages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func enableUI(_ enabled: Bool) {
        navigationItem.hidesBackButton = !enabled
        newCollectionButton.isEnabled = enabled
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        cell.imageView.image = UIImage(named: "blankImage")
        
        if photoObjects.count > indexPath.row {
            
            if let imageData = photoObjects[indexPath.row].value(forKey: "imageData") as? Data {
                cell.imageView.image = UIImage(data: imageData)
            } else {
                cell.imageView.image = UIImage(named: "blankImage")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosCount
    }
    
    func getPhotosFromCoreData() -> [NSManagedObject]? {
        guard let pin = pin, let fetchedResultsController = fetchedResultsController else {
            print("Photo album segue performed without Pin or FetchedResultsController objects.")
            return nil
        }
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "imageData", ascending: true)]
        let photoPredicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fr.predicate = photoPredicate
        //fr.returnsObjectsAsFaults = false
        
        do {
            //crash occurs here if I try to get a new collection of images
            let results = try fetchedResultsController.managedObjectContext.fetch(fr) as? [NSManagedObject]
            return results
        } catch {
            print("Request for photos in Core Data could not be processed.")
        }
        
        return nil
    }
    
    func getSavedImages() {
        
        guard let photos = getPhotosFromCoreData() else {
            print("Could not retrieve photos from Core Data.")
            return
        }
        
        print("photoalbum photos count = \(String(describing: photos.count))")
        
        if photos.count > 0 {
            for photo in photos {
                photoObjects.append(photo)
            }
        } else {
            print("No photos could be found in Core Data.")
            downloadNewImages()
            return
        }
        
        photosCount = photoObjects.count
        collectionView.reloadData()
        enableUI(true)
    }
    
    func downloadNewImages() {
        
        enableUI(false)
    
        let flickrUrl = webClient.createFlickrUrl(latitude: pin?.latitude, longitude: pin?.longitude)
        print(flickrUrl)
        
        webClient.getFlickrPhotoUrls(flickrUrl: flickrUrl) { (photoUrls, error) in
            
            if let error = error {
                Helper.displayAlertOnMain(error)
                DispatchQueue.main.async {
                    self.enableUI(true)
                }
                return
            }
            
            guard let photoUrls = photoUrls else {
                Helper.displayAlertOnMain("Error getting flickr results.")
                DispatchQueue.main.async {
                    self.enableUI(true)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.photosCount = photoUrls.count
                self.collectionView.reloadData()
            }
            
            var urlIndex = 1
            
            for url in photoUrls {
                self.webClient.downloadImage(url) { (imageData) in
                    DispatchQueue.main.async {
                        self.saveToCoreData(imageData)
                        print("photo = \(urlIndex), photoObjects.count = \(self.photoObjects.count)")
                        self.collectionView.reloadItems(at: [IndexPath(item: urlIndex-1, section: 0)])
                        urlIndex = urlIndex + 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.enableUI(true)
            }
            
            self.delegate.stack.save()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(photoObjects.count)
        if photoObjects.count > 0 {
            fetchedResultsController?.managedObjectContext.delete(photoObjects[indexPath.row])
            photoObjects.remove(at: indexPath.row)
            photosCount = photosCount - 1
        }
        print(photoObjects.count)
        self.delegate.stack.save()
        self.collectionView.reloadData()
    }
    
    func saveToCoreData(_ imageData: NSData) {
        if let pin = pin, let fc = fetchedResultsController {
            print("Saving photo to Core Data")
            let photo = Photo(imageData: imageData, context: fc.managedObjectContext)
            photo.pin = pin
            photoObjects.append(photo)
        }
    }
    
    func deleteSavedImages() {
        guard let photos = getPhotosFromCoreData() as? [Photo],
            let context = fetchedResultsController?.managedObjectContext else {
            print("Could not retrieve photos from Core Data or core data context.")
            return
        }
        
        for photo in photos {
            context.delete(photo)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate.stack.save()
    }
}
