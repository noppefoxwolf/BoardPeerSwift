//
//  ViewController.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/25.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let drawable: Drawable = .init(frame: .zero)
    let clearButton: UIButton = .init(frame: .zero)
    let connection: MultipeerConnection = MultipeerConnection<DrawData>(serviceName: "hoge")
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .white
        view.addSubview(drawable)
        drawable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            drawable.topAnchor.constraint(equalTo: view.topAnchor),
            drawable.leftAnchor.constraint(equalTo: view.leftAnchor),
            drawable.rightAnchor.constraint(equalTo: view.rightAnchor),
            drawable.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panReceived(_:)))
        drawable.addGestureRecognizer(pan)
        view.addSubview(clearButton)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(cleanScreen(_:)), for: .touchUpInside)
        NSLayoutConstraint.activate([
            clearButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            clearButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            clearButton.heightAnchor.constraint(equalToConstant: 44),
        ])
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.black, for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connection.bufferingFrameCount = 0
        connection.isBrowserDismissAutomatically = true
        connection.onUpdate { [weak self] (drawData) in
            let point = CGPoint(x: drawData.x, y: drawData.y)
            self?.drawable.draw(point: point, state: drawData.state)
            
            if drawData.state == .cancelled {
                self?.drawable.clear()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !connection.isConnedted {
            connection.presentBrowser(from: self)
        }
    }
    
    @objc func panReceived(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: sender.view)
        drawable.draw(point: point, state: sender.state)
        
        let dummyData: [String] = (0..<100).map({ _ in "a" })
        let drawData = DrawData(x: point.x, y: point.y, state: sender.state, dummyData: dummyData)
        connection.send(data: drawData)
    }

    @objc func cleanScreen(_ sender: UIButton) {
        drawable.clear()
        
        let drawData = DrawData(x: 0, y: 0, state: .cancelled, dummyData: [])
        connection.send(data: drawData)
    }
}

struct DrawData: Codable {
    let x: CGFloat
    let y: CGFloat
    let state: UIPanGestureRecognizer.State
    let dummyData: [String]
}

extension UIPanGestureRecognizer.State: Codable {}
