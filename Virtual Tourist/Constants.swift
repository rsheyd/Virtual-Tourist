//
//  Constants.swift
//  On The Map
//
//  Created by Roman Sheydvasser on 4/5/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

extension WebClient {
    struct Constants {
        static let flickrAPIKey = "7d9eeb6568c2637b23e2041a429d492d"
        static let parseAppId = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let restApiKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
        static let studentLocationMethod = "https://parse.udacity.com/parse/classes/StudentLocation"
        static let getStudentLocationsMethod = "https://parse.udacity.com/parse/classes/StudentLocation?limit=100&order=-updatedAt"
        static let sessionMethod = "https://www.udacity.com/api/session"
        static let userInfoMethod = "https://www.udacity.com/api/users/"
        static let keyAndIdHeaders = ["X-Parse-Application-Id":parseAppId,"X-Parse-REST-API-Key":restApiKey]
        static let loginHeaders = ["Accept":"application/json","Content-Type":"application/json"]
        static let postLocationHeaders = ["X-Parse-Application-Id":parseAppId,"X-Parse-REST-API-Key":restApiKey,"Content-Type":"application/json"]
    }
}
