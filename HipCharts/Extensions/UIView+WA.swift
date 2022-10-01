//
//  File.swift
//  MapStretch
//
//  Created by Tyler on 1/23/17.
//  Copyright © 2017 Walkabout Apps. All rights reserved.
//

import UIKit

extension UIView{
    func addSubviewStretchedToBounds(_ view: UIView){
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        self.addSubview(view)
    }
    
    func insertSubviewStretchedToBounds(_ view: UIView, at index: Int){
        self.addSubviewStretchedToBounds(view)
        self.insertSubview(view, at: index)
    }
    
    var heightConstraint: NSLayoutConstraint? {
        return constraints.first(where: { $0.firstAttribute == .height && $0.secondItem == nil })
    }
    
    var widthConstraint: NSLayoutConstraint? {
        return constraints.first(where: { $0.firstAttribute == .width && $0.secondItem == nil })
    }
    
    func collapseHeightConstraintAndHide(){
        heightConstraint?.constant = 0
        isHidden = true
    }
    
    func rotateForever(){
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {  [weak self] in
            self?.transform = self!.transform.rotated(by: .pi)
        }) { [weak self] (finished) in
            if finished {
                self?.rotateForever()
            }
            else {
                self?.transform = .identity
            }
        }
    }
    
    func fadeIn(duration: TimeInterval){
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.alpha = 1
            }, completion: nil)
    }
    
    func fadeOut(duration: TimeInterval, completion: ((Bool) -> ())? = nil){
        alpha = 0.9
        UIView.animate(withDuration: duration, delay: 0, options: .beginFromCurrentState, animations: { [weak self] in
            self?.alpha = 0
            }, completion: completion)
    }
}
