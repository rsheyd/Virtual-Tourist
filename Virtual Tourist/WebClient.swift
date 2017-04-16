//
//  Json.swift
//  On The Map
//
//  Created by Roman Sheydvasser on 2/28/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import Foundation

class WebClient: NSObject {
    
    
    // MARK: Properties
    
    var session = URLSession.shared
    
    // MARK: Functions
    
    func taskViaHttp(url: String, httpMethod: String, httpHeaders: [String:String]?, httpBody: String?, completionHandlerForRequest: @escaping (_ jsonData: Data?, _ errorString: String?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: url)!)
        request.httpMethod = httpMethod
        request.allHTTPHeaderFields = httpHeaders
        if let httpBody = httpBody {
            request.httpBody = httpBody.data(using: String.Encoding.utf8)
        }
        
        taskWithHttpRequest(request, completionHandlerForTask: completionHandlerForRequest)
    }
    
    func taskWithHttpRequest(_ request: NSMutableURLRequest, completionHandlerForTask: @escaping (_ jsonData: Data?, _ errorString: String?) -> Void) {
            
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            guard let data = data else {
                Helper.displayAlertOnMain("Data was not returned.")
                return
            }
            
            guard (error == nil) else {
                completionHandlerForTask(nil, "Network request could not be processed due to error: \(String(describing: error))")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 403 else {
                completionHandlerForTask(nil, "Account not found or invalid credentials.")
                return
            }
            
            completionHandlerForTask(data, nil)
        }
        task.resume()
    }
    
    func parseJsonData(data: Data, isUdacityApi: Bool) -> [String:AnyObject]? {
        
        var jsonDictionary: [String:AnyObject]?
        var newData = data
        
        if isUdacityApi {
            let range = Range(uncheckedBounds: (5, data.count))
            newData = data.subdata(in: range) /* subset response data! */
        }
        
        do {
            jsonDictionary = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as? [String:AnyObject]
            return jsonDictionary
        } catch {
            Helper.displayAlertOnMain("Could not parse the data as JSON: '\(data)'")
        }
        
        return nil
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> WebClient {
        struct Singleton {
            static var sharedInstance = WebClient()
        }
        return Singleton.sharedInstance
    }
}
