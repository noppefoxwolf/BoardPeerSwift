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
var _session: MCSession!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var window: UIWindow? = .init(frame: UIScreen.main.bounds)
    
    var peerId: MCPeerID!
    var advertiser: MCAdvertiserAssistant!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let deviceName = UIDevice.current.name
        peerId = MCPeerID(displayName: deviceName)
        _session = MCSession(peer: peerId)
        
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        advertiser = MCAdvertiserAssistant(serviceType: pizarraService, discoveryInfo: ["dummy_key":"dummy_val"], session: _session)
        advertiser.start()
        
        return true
    }
}

