//
//  WebConvenience.swift
//  On The Map
//
//  Created by Roman Sheydvasser on 4/5/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation

extension WebClient {
    
    func getFlickrUrl(latitude: Double?, longitude: Double?) -> String {
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
}
