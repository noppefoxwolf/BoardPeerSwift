//
//  Drawable.swift
//  BoardPeerSwift
//
//  Created by Tomoya Hirano on 2020/02/26.
//  Copyright © 2020 Tomoya Hirano. All rights reserved.
//

import UIKit

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
