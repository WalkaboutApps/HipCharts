//
//  MapDrawingView.swift
//  MapStretch
//
//  Created by Tyler on 4/16/17.
//  Copyright © 2017 Walkabout Apps. All rights reserved.
//

import UIKit

class MapDrawingUIView: UIView, VMViewInterface {
    let path = UIBezierPath()
    var drawingLayer: CAShapeLayer!
    var vm: MapDrawingVM! { return _untypedVM as? MapDrawingVM }
    private var touchesBeganInMenu = false
    fileprivate let scaleNumberFormatter = NumberFormatter()
    
    @IBOutlet fileprivate var menuContainerView: UIView!
    @IBOutlet fileprivate var clearButton: UIButton!
    @IBOutlet fileprivate var undoButton: UIButton!
    @IBOutlet fileprivate var distanceLabel: UILabel!
    @IBOutlet fileprivate var startView: UIView!
    @IBOutlet fileprivate var endView: UIView!


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawingLayer = createDrawingLayer()
        layer.addSublayer(drawingLayer)
        scaleNumberFormatter.usesSignificantDigits = true
        scaleNumberFormatter.maximumSignificantDigits = 3
        scaleNumberFormatter.maximumFractionDigits = 2
    }
    
    private func createDrawingLayer() -> CAShapeLayer{
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.yellow.cgColor
        layer.lineWidth = 5
        layer.lineCap = CAShapeLayerLineCap.round
        layer.fillColor = nil
        layer.lineJoin = CAShapeLayerLineJoin.round
        return layer
    }
    
    func update(){
        menuContainerView.isHidden = vm.drawArea
        path.replaceWithInterpolatedPoints(interpolationPoints: vm?.points ?? [], close: vm.drawArea)
        drawingLayer.path = path.cgPath
        undoButton.isHidden = (vm?.history.count ?? 0) == 0
        clearButton.isHidden = (vm?.history.count ?? 0) < 2
        undoButton.isEnabled = vm?.touchesInProgress == false
        clearButton.isEnabled = vm?.touchesInProgress == false

        if let distance = vm?.lenghthOfPathMeters, let units = scaleNumberFormatter.string(from: NSNumber(value: distance * vm.measurementUnit.perMeter)) {
            distanceLabel.text = "\(units) \(vm.measurementUnit.displayString)"
        }
        else{
            distanceLabel.text = "Draw to measure distance"
        }
        
        // start and end views
        startView.isHidden = vm.points.count == 0
        endView.isHidden = vm.points.count == 0
        if vm.points.count > 0 {
            startView.center = vm.points.first!
            endView.center = vm.points.last!
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        UIView.animate(withDuration: 1.5, delay: 0.0, options: [.autoreverse, .repeat], animations: {
            self.startView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.endView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }, completion: nil)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if menuContainerView.frame.contains(point){
            return true
        }
        return vm?.shouldHandleTouch(at: point, event: event) ?? false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let point = touches.first?.location(in: self) else { return }
        guard menuContainerView.frame.contains(point) == false else {
            touchesBeganInMenu = true
            return
        }
        touchesBeganInMenu = false
        vm?.touchesBegan(at: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard touchesBeganInMenu == false else { return }
        guard let point = touches.first?.location(in: self) else { return }
        vm?.touchesContinue(at: [point])
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard touchesBeganInMenu == false else { return }
        vm?.touchesEnded()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard touchesBeganInMenu == false else { return }
        vm?.touchesEnded()
    }
}


// MARK: - IBAction
extension MapDrawingUIView {
    @IBAction fileprivate func undoAction(sender: UIButton){
        vm?.undo()
    }
    
    @IBAction fileprivate func exitAction(){
        fadeOut(duration: 0.3) { [weak self] (_) in
            self?.removeFromSuperview()
        }
        vm?.exit()
    }
    
    @IBAction fileprivate func clearAction(){
        vm?.clear()
    }
    
}
