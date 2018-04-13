//
//  DraggableAnnotationView.swift
//  NavigationTutorial
//
//  Created by Nathan Hsu on 2018-04-11.
//  Copyright © 2018 Nathan Hsu. All rights reserved.
//

import Foundation
import Mapbox

// This allows the View Controller to call calculate route when we end dragging.
protocol AnnotationViewDelegate {
    func didEndDragging()
}

// MGLAnnotationView subclass
class DraggableAnnotationView: MGLAnnotationView {
    
    var delegate: AnnotationViewDelegate? = nil
    var dropPin: UIImageView!
    
    init(reuseIdentifier: String, size: CGFloat) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        // `isDraggable` is a property of MGLAnnotationView, disabled by default.
        isDraggable = true
        
        // This property prevents the annotation from changing size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Begin setting up the waypoint pin view so the point is centered.
        dropPin = UIImageView(image: UIImage(named: "triangle"))
        let dropPinHeight = dropPin.frame.height
        let touchAreaWidth = dropPin.frame.width * 1.5
        let touchAreaHeight = dropPinHeight * 1.5
        let touchAreaSize = CGSize(width: touchAreaWidth, height: touchAreaHeight)
        
        self.frame.size = touchAreaSize
        
        dropPin.center = self.center
        dropPin.frame = dropPin.frame.offsetBy(dx: 0, dy: -(dropPinHeight * 0.25))
        self.addSubview(dropPin)
        self.transform = CGAffineTransform(translationX: 0, y: -(dropPinHeight * 0.25))

    }
    
    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)
        
        switch dragState {
        case .starting:
            print("Starting", terminator: "")
            startDragging()
        case .dragging:
            print(".", terminator: "")
        case .ending, .canceling:
            print("Ending")
            endDragging()
        case .none:
            return
        }
    }
    
    // When the user interacts with an annotation, animate opacity and scale changes.
    func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)
        
        // Initialize haptic feedback generator and give the user a light thud.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
            hapticFeedback.impactOccurred()
        }
    }
    
    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)
        
        // Give the user more haptic feedback when they drop the annotation.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .heavy)
            hapticFeedback.impactOccurred()
        }
        
        // after dropping, re-calculate route
        delegate?.didEndDragging()
    }
}
