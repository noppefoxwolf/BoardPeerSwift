//
//  ViewController.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/25.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {
    var appdelegate: AppDelegate { UIApplication.shared.delegate as! AppDelegate }
    var output: OutputStream!
    let drawable: Drawable = .init(frame: .zero)
    var browser: MCBrowserViewController! = nil
    let position: UILabel = .init(frame: .zero)
    
    override func loadView() {
        super.loadView()
        view.addSubview(drawable)
        drawable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            drawable.topAnchor.constraint(equalTo: drawable.topAnchor),
            drawable.leftAnchor.constraint(equalTo: drawable.leftAnchor),
            drawable.rightAnchor.constraint(equalTo: drawable.rightAnchor),
            drawable.bottomAnchor.constraint(equalTo: drawable.bottomAnchor),
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appdelegate.session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requireDeviceConnected()
    }
    
    private func requireDeviceConnected() {
        if (self.appdelegate.session.connectedPeers.count == 0) {
            self.browser = MCBrowserViewController(serviceType: pizarraService, session: appdelegate.session)
            self.browser.delegate = self
            present(browser, animated: true, completion: nil)
        }
    }
    
    func panReceived(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: sender.view)
        drawable.draw(point: point, state: sender.state)
        
        let data = DrawData(state: sender.state, point: sender.location(in: sender.view))
        output.write(data.bytes, maxLength: data.length)
    }

    func cleanScreen(_ sender: UIButton) {
        drawable.clear()
        
        let data = DrawData(state: .cancelled, point: .zero)
        output.write(data.bytes, maxLength: data.length)
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    
}

class DrawData: NSData {
    init(state: UIGestureRecognizer.State, point: CGPoint) {
        var state = state
        var x = point.x
        var y = point.y

        let data = NSMutableData()
        data.append(&x, length: MemoryLayout.size(ofValue: x))
        data.append(&y, length: MemoryLayout.size(ofValue: y))
        data.append(&state, length: MemoryLayout.size(ofValue: state))
        
        super.init(data: data as Data)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Drawable: UIView {
    private let layout: UIImageView = .init(frame: .zero)
    private let tmpLayout: UIImageView = .init(frame: .zero)
    private var lastPoint: CGPoint? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(layout)
        addSubview(tmpLayout)
        layout.translatesAutoresizingMaskIntoConstraints = false
        tmpLayout.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layout.topAnchor.constraint(equalTo: topAnchor),
            layout.leftAnchor.constraint(equalTo: leftAnchor),
            layout.rightAnchor.constraint(equalTo: rightAnchor),
            layout.bottomAnchor.constraint(equalTo: bottomAnchor),
            tmpLayout.topAnchor.constraint(equalTo: topAnchor),
            tmpLayout.leftAnchor.constraint(equalTo: leftAnchor),
            tmpLayout.rightAnchor.constraint(equalTo: rightAnchor),
            tmpLayout.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clear() {
        UIGraphicsBeginImageContext(self.layout.frame.size)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(red: 255, green: 255, blue: 255, alpha: 1)
        ctx?.fill(self.tmpLayout.bounds)
        self.layout.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func draw(point: CGPoint, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            lastPoint = point;
        case .changed:
            let currentPoint = point
            
            UIGraphicsBeginImageContext(self.layout.frame.size)
            
            tmpLayout.image?.draw(in: layout.bounds)
            
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.move(to: lastPoint!)
            ctx.addLine(to: currentPoint)
            ctx.setLineCap(.round)
            ctx.setLineWidth(10)
            ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            ctx.setBlendMode(.normal)
            ctx.strokePath()
            
            tmpLayout.image = UIGraphicsGetImageFromCurrentImageContext()
            
            tmpLayout.alpha = 1
            
            UIGraphicsEndImageContext()
            
            lastPoint = currentPoint
        case .ended:
            UIGraphicsBeginImageContext(self.layout.frame.size)
            layout.image?.draw(in: layout.bounds, blendMode: .normal, alpha: 1)
            tmpLayout.image?.draw(in: layout.bounds, blendMode: .normal, alpha: 1)
            self.layout.image = UIGraphicsGetImageFromCurrentImageContext()
            self.tmpLayout.image = nil
            UIGraphicsEndImageContext()
        default:
            break
        }
    }
}
