//
//  Utils.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/26.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import MultipeerConnectivity

class DisplayLink: NSObject {
    private var displayLink: CADisplayLink? = nil
    private var runLoop: RunLoop? = nil
    private var runLoopMode: RunLoop.Mode? = nil
    
    var onUpdate: ((CADisplayLink) -> Void)? = nil
    
    func start(runLoop: RunLoop = .main, mode: RunLoop.Mode = .default) {
        guard displayLink == nil else { return }
        self.runLoop = runLoop
        self.runLoopMode = mode
        displayLink = CADisplayLink(target: self, selector: #selector(update(_:)))
        displayLink?.preferredFramesPerSecond = 0
        displayLink?.add(to: runLoop, forMode: mode)
    }
    
    func stop() {
        guard let runLoop = runLoop else { return }
        guard let mode = runLoopMode else { return }
        displayLink?.remove(from: runLoop, forMode: mode)
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update(_ sender: CADisplayLink) {
        onUpdate?(sender)
    }
}

class ThreadLoop {
    private var shouldKeepRunning: Bool = false
    private let grobalQueue = DispatchQueue(label: "dev.noppe.inputStream", qos: .userInteractive, attributes: .init())
    var onUpdate: (() -> Void)? = nil
    
    func start() {
        guard !shouldKeepRunning else { return }
        shouldKeepRunning = true
        grobalQueue.async { [weak self] in
            guard let self = self else { return }
            while self.shouldKeepRunning {
                self.onUpdate?()
            }
        }
    }
    
    func stop() {
        guard shouldKeepRunning else { return }
        shouldKeepRunning = false
    }
}

class FrameQueue<T> {
    private var quque: [T] = []
    private let workerQueue: DispatchQueue = .init(label: "dev.noppe.sss", attributes: .init())
    private let displayLink: DisplayLink = .init()
    var bufferingCount: Int = 2
    
    var onUpdate: ((T) -> Void)? = nil
    
    func enqueue(_ data: T) {
        workerQueue.sync {
            quque.append(data)
        }
    }
    
    func start() {
        displayLink.onUpdate = { [weak self] _ in
            guard let self = self else { return }
            self.workerQueue.sync {
                guard self.quque.count > self.bufferingCount else { return }
                let first = self.quque.removeFirst()
                DispatchQueue.main.async {
                    self.onUpdate?(first)
                }
            }
        }
        displayLink.start()
    }
    
    func stop() {
        displayLink.stop()
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
