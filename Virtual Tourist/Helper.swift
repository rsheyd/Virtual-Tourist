//
//  Helper.swift
//  On The Map
//
//  Created by Roman Sheydvasser on 2/28/17.
//  Copyright © 2017 RLabs. All rights reserved.
//

import UIKit

class Helper: UIViewController {
    static func displayAlertOnMain(_ message: String?) {
        if let message = message {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

// allows displayAlert/UI changes to be called from separate class (i.e. this one)
extension UIApplication {
    
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
