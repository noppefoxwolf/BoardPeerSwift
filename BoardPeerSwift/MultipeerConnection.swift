//
//  MultipeerConnection.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/26.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import MultipeerConnectivity

class OutputStreamContainer<T: Codable> {
    let outputStream: OutputStream
    let separator: Data
    
    init(outputStream: OutputStream, separator: Data = "\n".data(using: .utf8)!) {
        self.outputStream = outputStream
        self.separator = separator
        self.outputStream.schedule(in: .main, forMode: .default)
        self.outputStream.open()
    }
    
    deinit {
        self.outputStream.close()
    }
    
    func write(data: T) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(data) + separator
        data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
          if let baseAddress = body.baseAddress, body.count > 0 {
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            outputStream.write(pointer, maxLength: data.count)
          }
        }
    }
}

class InputStreamContainer<T: Codable> {
    private let inputStream: InputStream
    private let separator: Data
    private let threadLoop: ThreadLoop = .init()
    private var data: Data = Data()
    var onDecoded: ((T) -> Void)? = nil
    
    init(inputStream: InputStream, separator: Data = "\n".data(using: .utf8)!) {
        self.inputStream = inputStream
        self.separator = separator
        threadLoop.onUpdate = { [weak self] in
            guard let self = self else { return }
            if self.inputStream.hasBytesAvailable {
                try? self.process()
            }
        }
        threadLoop.start()
        inputStream.open()
    }
    
    deinit {
        threadLoop.stop()
        inputStream.close()
    }
    
    private func process() throws {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        while inputStream.hasBytesAvailable {
            let size = inputStream.read(buffer, maxLength: bufferSize)
            self.data.append(buffer, count: size)
        }
        
        let isTruncateLastChunk = self.data.suffix(separator.count) != separator
        var splitedData = self.data.split(separator: separator)
        
        if splitedData.isEmpty {
            return
        }
        
        if isTruncateLastChunk {
            splitedData.removeLast()
        }
        self.data.removeSubrange(0..<splitedData.map({ $0.count + separator.count }).reduce(0, +))
        
        for data in splitedData {
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(T.self, from: data)
            onDecoded?(decodedData)
        }
    }
}

public class MultipeerConnection<T: Codable> {
    private let serviceName: String
    private let session: MCSession
    private let peerID: MCPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let sessionDelegator: MCSessionDelegator = .init()
    private let browserViewControllerDelegator: MCBrowserViewControllerDelegator = .init()
    private let advertiser: MCAdvertiserAssistant
    private var outputStream: OutputStreamContainer<T>? = nil
    private var inputStream: InputStreamContainer<T>? = nil
    private let frameQueue: FrameQueue = FrameQueue<T>()
    var isConnedted: Bool { !session.connectedPeers.isEmpty }
    var isBrowserDismissAutomatically: Bool {
        get { sessionDelegator.isDismissAutomatically }
        set { sessionDelegator.isDismissAutomatically = newValue }
    }
    var bufferingFrameCount: Int {
        get { frameQueue.bufferingCount }
        set { frameQueue.bufferingCount = newValue }
    }
    
    public init(serviceName: String) {
        self.serviceName = serviceName
        session = MCSession(peer: peerID)
        session.delegate = sessionDelegator
        advertiser = MCAdvertiserAssistant(serviceType: serviceName, discoveryInfo: nil, session: session)
        sessionDelegator.delegate = self
    }
    
    deinit {
        frameQueue.stop()
    }
    
    public func send(data: T) {
        try? outputStream?.write(data: data)
    }
    
    public func onUpdate(_ closure: @escaping ((T) -> Void)) {
        frameQueue.onUpdate = closure
    }
    
    public func presentBrowser(from: UIViewController) {
        let vc = MCBrowserViewController(serviceType: serviceName, session: session)
        vc.delegate = browserViewControllerDelegator
        sessionDelegator.browser = vc
        from.present(vc, animated: true, completion: nil)
        startTink()
    }
    
    public func startTink() {
        advertiser.start()
    }
}

extension MultipeerConnection: MCSessionDelegatorDelegate {
    func didReceived(stream: OutputStream) {
        advertiser.stop()
        outputStream = OutputStreamContainer(outputStream: stream)
    }
    
    func didReceived(stream: InputStream) {
        advertiser.stop()
        inputStream = InputStreamContainer(inputStream: stream)
        inputStream?.onDecoded = { [weak self] (data) in
            self?.frameQueue.enqueue(data)
        }
        frameQueue.start()
        
    }
}

protocol MCSessionDelegatorDelegate: class {
    func didReceived(stream: OutputStream)
    func didReceived(stream: InputStream)
}

class MCSessionDelegator: NSObject, MCSessionDelegate {
    var isDismissAutomatically: Bool = false
    weak var browser: MCBrowserViewController? = nil
    weak var delegate: MCSessionDelegatorDelegate? = nil
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            do {
                let name = "\(peerID.displayName).\(Date().timeIntervalSinceReferenceDate)"
                let stream = try session.startStream(withName: name, toPeer: peerID)
                delegate?.didReceived(stream: stream)
                
                if isDismissAutomatically {
                    DispatchQueue.main.async { [weak self] in
                        self?.browser?.dismiss(animated: true, completion: nil)
                    }
                }
            } catch {
            }
        case .connecting:
            break
        case .notConnected:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        delegate?.didReceived(stream: stream)
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}

class MCBrowserViewControllerDelegator: NSObject, MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            browserViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async {
            browserViewController.dismiss(animated: true, completion: nil)
        }
    }
}

