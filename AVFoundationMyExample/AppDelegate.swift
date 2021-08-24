//
//  AppDelegate.swift
//  AVFoundationMyExample
//
//  Created by Евгений Полюбин on 24.08.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow.init()
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        
        window.rootViewController = vc
        self.window = window
        window.makeKeyAndVisible()
        
        return true
    }

    

}

