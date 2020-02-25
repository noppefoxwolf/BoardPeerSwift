//
//  AppDelegate.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/25.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import MultipeerConnectivity

let pizarraService = "jmg-pizarra"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var session: MCSession!
    var peerId: MCPeerID!
    var advertiser: MCAdvertiserAssistant!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let deviceName = UIDevice.current.name
        peerId = MCPeerID(displayName: deviceName)
        session = MCSession(peer: peerId)
        
        advertiser = MCAdvertiserAssistant(serviceType: pizarraService, discoveryInfo: ["dummy_key":"dummy_val"], session: session)
        advertiser.start()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

