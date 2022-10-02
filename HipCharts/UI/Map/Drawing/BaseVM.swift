//
//  BaseVM.swift
//  MapStretch
//
//  Created by Tyler on 3/29/17.
//  Copyright © 2017 Walkabout Apps. All rights reserved.
//

import UIKit

protocol VMViewInterface: AnyObject {
    var _untypedVM: VM? {get set}
    func update()
    func bind(to vm: VM?)
}

private var vmAssociatedObjectKey: UInt8 = 100

extension VMViewInterface {
    var _untypedVM: VM? {
        get{
            return objc_getAssociatedObject(self, &vmAssociatedObjectKey) as? VM
        }
        set{
            objc_setAssociatedObject(self, &vmAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func bind(to vm: VM?){
        vm?._untypedView = self
        _untypedVM = vm
        update()
    }
}

class VM: NSObject {
    weak var _untypedView: VMViewInterface?
    
    func updateView(){
        _untypedView?.update()
    }
}
