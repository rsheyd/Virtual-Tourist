//
//  WebConvenience.swift
//  On The Map
//
//  Created by Roman Sheydvasser on 4/5/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation

extension WebClient {
    
    func createFlickrUrl(latitude: Double?, longitude: Double?) -> String {
        let flickrBbox = bboxString(latitude: latitude, longitude: longitude)
        let flickrUrl = "https://api.flickr.com/services/rest?method=flickr.photos.search&format=json&api_key=\(Constants.flickrAPIKey)&bbox=\(flickrBbox)&safe_search=1&extras=url_m&nojsoncallback=1"
        return flickrUrl
    }
    
    func bboxString(latitude: Double?, longitude: Double?) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = latitude, let longitude = longitude {
            let minimumLon = max(longitude - 1, -180)
            let minimumLat = max(latitude - 1, -90)
            let maximumLon = min(longitude + 1, 180)
            let maximumLat = min(latitude + 1, 90)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    func downloadImage(_ url: URL, completionHandler: @escaping (_ imageData: NSData) -> Void) {
        do {
            let imageData = try Data(contentsOf: url) as NSData
            completionHandler(imageData)
        } catch {
            print("Download operation failed.")
        }
    }
    
    func getFlickrPhotoUrls(flickrUrl: String, completionHandler: @escaping (_ photoUrls: [URL]?, _ error: String?) -> Void) {
        
        var photoUrls: [URL] = []
        
        taskViaHttp(url: flickrUrl, httpMethod: "GET", httpHeaders: nil, httpBody: nil) { (jsonData, error) in
            
            if let error = error {
                completionHandler(nil,"Error getting flickr results: \(error)")
                return
            }
            
            guard let jsonData = jsonData else {
                completionHandler(nil,"No data returned when getting flickr results.")
                return
            }
            
            guard let parsedResult = self.parseJsonData(data: jsonData, isUdacityApi: false) else {
                completionHandler(nil,"Returned data could not be parsed: \(jsonData)")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String, stat == "ok" else {
                completionHandler(nil,"Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? [String:AnyObject] else {
                completionHandler(nil,"Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                completionHandler(nil,"Cannot find key 'photo' in \(photosDictionary)")
                return
            }
            
            if photosArray.count == 0 {
                completionHandler(nil,"No Photos Found. Search Again.")
                return
            } else {
                
                let maxPhotos = min(20, photosArray.count)
                var photosUsed: [Int] = []
                
                for _ in 1...maxPhotos {
                    
                    var randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    while photosUsed.contains(randomPhotoIndex) {
                        randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                    }
                    
                    photosUsed.append(randomPhotoIndex)
                    let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photoDictionary["url_m"] as? String, let imageURL = URL(string: imageUrlString) else {
                        print("Cannot find key 'url_m' in \(photoDictionary), or URL is invalid.")
                        return
                    }
                    
                    photoUrls.append(imageURL)
                }
                
                completionHandler(photoUrls, nil)
            }
        }
    }
}
