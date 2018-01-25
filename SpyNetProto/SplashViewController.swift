//
//  SplashViewController.swift
//  SpyNetProto
//
//  Created by Edward Han on 2/5/17.
//  Copyright © 2017 Edward Han. All rights reserved.
//

import UIKit
import INTULocationManager

class SplashViewController: UIViewController {
  
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let userUIDfake = "Vk8DAXariGZWyIiVdO4apcatEo73"
       
       imageView.image = #imageLiteral(resourceName: "raven")
        Session.sharedSession.setCurrentUser() { success in
            if success {
      
                LocationService.getLocation() { success in
                    if success {
                        
                        self.performSegue(withIdentifier: "toRadar", sender: self)
                    }
                    else {
                        
                        print("no location")
                    }
                }
            }
            
            else {
                print("no user")
                self.performSegue(withIdentifier: "toLoginFromSplash", sender: self)
            }
        }
        
        
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



}




