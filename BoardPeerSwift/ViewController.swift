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
    var output: OutputStream!
    let drawable: Drawable = .init(frame: .zero)
    let clearButton: UIButton = .init(frame: .zero)
    var browser: MCBrowserViewController! = nil
    let position: UILabel = .init(frame: .zero)
    var data: Data = Data()
    
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
        _session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requireDeviceConnected()
    }
    
    @objc func panReceived(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: sender.view)
        drawable.draw(point: point, state: sender.state)
        
        let drawData = DrawData(x: point.x, y: point.y, state: sender.state)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(drawData) + "\n".data(using: .utf8)!
        try! data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
          if let baseAddress = body.baseAddress, body.count > 0 {
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            try! output.write(pointer, maxLength: data.count)
          }
        }
    }

    @objc func cleanScreen(_ sender: UIButton) {
        drawable.clear()
        
        let drawData = DrawData(x: 0, y: 0, state: .cancelled)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(drawData) + "\n".data(using: .utf8)!
        try! data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
          if let baseAddress = body.baseAddress, body.count > 0 {
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            try! output.write(pointer, maxLength: data.count)
          }
        }
    }
}

struct DrawData: Codable {
    let x: CGFloat
    let y: CGFloat
    let state: UIPanGestureRecognizer.State
}

extension UIPanGestureRecognizer.State: Codable {}

extension ViewController: MCSessionDelegate {
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        stream.delegate = self
        stream.schedule(in: .main, forMode: .default)
        stream.open()
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected with ", peerID.displayName)
            do {
                self.output = try _session.startStream(withName: "touches", toPeer: _session.connectedPeers[0])
                self.output.delegate = self
                
                self.output.schedule(in: .main, forMode: .default)
                self.output.open()
                
                DispatchQueue.main.async {
                    self.browser.dismiss(animated: true, completion: nil)
                }
            } catch {
                self.output = nil
                print("ERROR: ", error.localizedDescription)
            }
        case .connecting:
            print("Waiting for ", peerID.displayName)
        case .notConnected:
            print("Disconnected from ", peerID.displayName)
        }
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    
    private func requireDeviceConnected() {
        if (_session.connectedPeers.count == 0) {
            self.browser = MCBrowserViewController(serviceType: pizarraService, session: _session)
            self.browser.delegate = self
            present(browser, animated: true, completion: nil)
        }
    }
    
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            browserViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            browserViewController.dismiss(animated: true, completion: {
                self.requireDeviceConnected()
            })
        }
    }
}

extension ViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard output != aStream else { return }
        switch eventCode {
        case .openCompleted:
            print("Conectado")
        case .endEncountered:
            print("Cerrando stream")
            aStream.remove(from: .main, forMode: .default)
            aStream.close()
            self.output = nil
        case .hasBytesAvailable:
            let inputStream = aStream as! InputStream
            
            

            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
            }
            
            while inputStream.hasBytesAvailable {
                let size = inputStream.read(buffer, maxLength: bufferSize)
                self.data.append(buffer, count: size)
            }
            //print("a", self.data.count)
            let separator = "\n".data(using: .utf8)!
            let isTruncateLastChunk = self.data.suffix(separator.count) != separator
            var splitedData = self.data.split(separator: separator)
            print(String(data: self.data, encoding: .utf8)!)
            print(splitedData.count)
            if isTruncateLastChunk {
                splitedData.removeLast()
            }
            self.data.removeSubrange(0..<splitedData.map({ $0.count + separator.count }).reduce(0, +))
            
            //print("b", self.data.count)
            
            for data in splitedData {
                let decoder = JSONDecoder()
                let drawData = try! decoder.decode(DrawData.self, from: data)
                let point = CGPoint(x: drawData.x, y: drawData.y)
                drawable.draw(point: point, state: drawData.state)
                //self.position.text = [NSString stringWithFormat:@"%f - %f", x, y];
                if drawData.state == .cancelled {
                    drawable.clear()
                    return
                }
            }
        default:
            print("Event: ", eventCode.rawValue)
        }
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

extension Data {
    func split(separator: Data) -> [Data] {
        var chunks: [Data] = []
        var pos = startIndex
        // Find next occurrence of separator after current position:
        while let r = self[pos...].range(of: separator) {
            // Append if non-empty:
            if r.lowerBound > pos {
                chunks.append(self[pos..<r.lowerBound])
            }
            // Update current position:
            pos = r.upperBound
        }
        // Append final chunk, if non-empty:
        if pos < endIndex {
            chunks.append(self[pos..<endIndex])
        }
        return chunks
    }
}
