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
    var photosCount: Int?
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
        if let count = photosCount, count >= 20 {
            return 20
        } else if let count = photosCount, count < 20 {
            return count
        } else {
            return 0
        }
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
        fr.returnsObjectsAsFaults = false
        
        do {
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
            }
        
        photosCount = photoObjects.count
        collectionView.reloadData()
    }
    
    func downloadNewImages() {
    
        let flickrUrl = webClient.getFlickrUrl(latitude: pin?.latitude, longitude: pin?.longitude)
        print(flickrUrl)
        
        webClient.taskViaHttp(url: flickrUrl, httpMethod: "GET", httpHeaders: nil, httpBody: nil) { (jsonData, error) in
            
            if let error = error {
                print("Error getting flickr results: \(error)")
                return
            }
            
            guard let jsonData = jsonData else {
                print("No data returned when getting flickr results.")
                return
            }
            
            guard let parsedResult = self.webClient.parseJsonData(data: jsonData, isUdacityApi: false) else {
                print("Returned data could not be parsed: \(jsonData)")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                print("No Photos Found. Search Again.")
                return
            } else {
                
                DispatchQueue.main.async {
                    self.photosCount = photosArray.count
                    self.collectionView.reloadData()
                }
                
                let maxPhotos = min(20, photosArray.count)
                var photosUsed: [Int] = []
                
                for photo in 1...maxPhotos {
                    
                    var randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    while photosUsed.contains(randomPhotoIndex) {
                        randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    }
                    
                    photosUsed.append(randomPhotoIndex)
                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary["url_m"] as? String else {
                        print("Cannot find key 'url_m' in \(photoDictionary)")
                        return
                    }
                    
                    // if an image exists at the url, set the image and title
                    let imageURL = URL(string: imageUrlString)
                    if let imageData = try? Data(contentsOf: imageURL!) {
                        if let _ = (UIImage(data: imageData)) {
                            
                            DispatchQueue.main.async {
                                self.saveToCoreData(imageData as NSData)
                                print("photo = \(photo), photoObjects.count = \(self.photoObjects.count)")
                                self.collectionView.reloadItems(at: [IndexPath(item: photo-1, section: 0)])
                            }
                        }
                    } else {
                        print("Image does not exist at \(imageUrlString)")
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(photoObjects.count)
        if photoObjects.count > 0 {
            fetchedResultsController?.managedObjectContext.delete(photoObjects[indexPath.row])
            photoObjects.remove(at: indexPath.row)
            photosCount = photosCount! - 1
        }
        print(photoObjects.count)
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
        guard let photos = getPhotosFromCoreData(),
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
