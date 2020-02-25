//
//  AppDelegate.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/25.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import MultipeerConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var window: UIWindow? = .init(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
                
        return true
    }
}

