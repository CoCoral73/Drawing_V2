//
//  ViewController.swift
//  MyDrawing
//
//  Created by 김정원 on 2023/11/05.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var Undo: UIBarButtonItem!
    @IBOutlet var Redo: UIBarButtonItem!
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var Pen: UIButton!
    @IBOutlet var Eraser: UIButton!
    @IBOutlet var ColorWell: UIColorWell!
    
    var lineWidth: CGFloat = 3.0
    var lineWidthSelected = [false, false, true, false, false]
    var lastLineWidth: CGFloat = 3.0
    var eraserWidthSelected = [true, false, false, false, false]
    var lastEraserWidth: CGFloat = 2.0
    var lineColor = UIColor.black
    var history = [UIImage]()
    var now = -1
    var firstPoint: CGPoint!
    var lastPoint: CGPoint!
    var path: UIBezierPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        ColorWell.selectedColor = UIColor.black
        ColorWell.addTarget(self, action: #selector(ViewController.colorWellDidChange(_:)), for: .valueChanged)
        
        Undo.isEnabled = false
        Redo.isEnabled = false
        Pen.isSelected = true
    }

    @objc func colorWellDidChange(_ sender: UIColorWell) {
        lineColor = ColorWell.selectedColor!
    }

    @IBAction func btnUndo(_ sender: UIBarButtonItem) {
        now -= 1
        Redo.isEnabled = true
        if now >= 0 { imgView.image = history[now] }
        else {
            imgView.image = nil
            Undo.isEnabled = false
        }
    }
    @IBAction func btnRedo(_ sender: UIBarButtonItem) {
        now += 1
        Undo.isEnabled = true
        imgView.image = history[now]
        if now + 1 == history.count { Redo.isEnabled = false }
    }
    @IBAction func btnPen(_ sender: UIButton) {
        if Pen.isSelected {
            let PVC = PenPopoverViewController()
            PVC.lineWidthSelected = lineWidthSelected
            PVC.act1 = { [weak self] in self?.lineWidth = 1.0; (0...4).forEach { self?.lineWidthSelected[$0] = false; self?.lineWidthSelected[0] = true }; self?.lastLineWidth = 1.0 }
            PVC.act2 = { [weak self] in self?.lineWidth = 2.0; (0...4).forEach { self?.lineWidthSelected[$0] = false; self?.lineWidthSelected[1] = true }; self?.lastLineWidth = 2.0 }
            PVC.act3 = { [weak self] in self?.lineWidth = 3.0; (0...4).forEach { self?.lineWidthSelected[$0] = false; self?.lineWidthSelected[2] = true }; self?.lastLineWidth = 3.0 }
            PVC.act4 = { [weak self] in self?.lineWidth = 4.0; (0...4).forEach { self?.lineWidthSelected[$0] = false; self?.lineWidthSelected[3] = true }; self?.lastLineWidth = 4.0 }
            PVC.act5 = { [weak self] in self?.lineWidth = 5.0; (0...4).forEach { self?.lineWidthSelected[$0] = false; self?.lineWidthSelected[4] = true }; self?.lastLineWidth = 5.0 }
            
            PVC.view.backgroundColor = UIColor.white
            PVC.preferredContentSize = CGSize(width: 300, height: 60)
            PVC.modalPresentationStyle = .popover
            if let pres = PVC.presentationController {
                pres.delegate = self
            }
            
            self.present(PVC, animated: true)
            if let popover = PVC.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
                popover.permittedArrowDirections = .down
            }
        }
        else {
            Pen.isSelected = true
            Eraser.isSelected = false
            
            lineColor = ColorWell.selectedColor!
            lineWidth = lastLineWidth
        }
        
    }
    @IBAction func btnEraser(_ sender: UIButton) {
        if Eraser.isSelected {
            let EVC = EraserPopoverViewController()
            EVC.lineWidthSelected = eraserWidthSelected
            EVC.actAll = { [weak self] in self?.imgView.image = nil; self?.history.removeAll(); self?.now = -1; self?.Undo.isEnabled = false; self?.Redo.isEnabled = false }
            EVC.act1 = { [weak self] in self?.lineWidth = 10.0; (0...4).forEach { self?.eraserWidthSelected[$0] = false; self?.eraserWidthSelected[0] = true; self?.lastEraserWidth = 10.0 }}
            EVC.act2 = { [weak self] in self?.lineWidth = 30.0; (0...4).forEach { self?.eraserWidthSelected[$0] = false; self?.eraserWidthSelected[1] = true; self?.lastEraserWidth = 30.0 }}
            EVC.act3 = { [weak self] in self?.lineWidth = 50.0; (0...4).forEach { self?.eraserWidthSelected[$0] = false; self?.eraserWidthSelected[2] = true; self?.lastEraserWidth = 50.0 }}
            EVC.act4 = { [weak self] in self?.lineWidth = 70; (0...4).forEach { self?.eraserWidthSelected[$0] = false; self?.eraserWidthSelected[3] = true; self?.lastEraserWidth = 70.0 }}
            EVC.act5 = { [weak self] in self?.lineWidth = 100.0; (0...4).forEach { self?.eraserWidthSelected[$0] = false; self?.eraserWidthSelected[4] = true; self?.lastEraserWidth = 100.0 }}
            
            EVC.view.backgroundColor = UIColor.white
            EVC.preferredContentSize = CGSize(width: 300, height: 90)
            EVC.modalPresentationStyle = .popover
            if let pres = EVC.presentationController {
                pres.delegate = self
            }
            
            self.present(EVC, animated: true)
            if let popover = EVC.popoverPresentationController {
                popover.sourceView = sender
                popover.sourceRect = sender.bounds
                popover.permittedArrowDirections = .down
            }
        }
        else {
            Pen.isSelected = false
            Eraser.isSelected = true
            
            lineWidth = lastEraserWidth
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        firstPoint = touch.location(in: imgView)
        lastPoint = firstPoint
        path = UIBezierPath()
        path?.move(to: firstPoint!)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if firstPoint.y <= 0 || firstPoint.y >= imgView.frame.height { return }
        
        let touch = touches.first! as UITouch
        let currPoint = touch.location(in: imgView)
        let midPoint = midPoint(lastPoint, currPoint)
        path?.addQuadCurve(to: midPoint, controlPoint: lastPoint)
        drawing()
        
        lastPoint = currPoint
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if firstPoint.y <= 0 || firstPoint.y >= imgView.frame.height { return }
        
        path?.addQuadCurve(to: lastPoint, controlPoint: lastPoint)
        drawing()
        
        if Eraser.isSelected == true {
            if now == -1 && imgView.image == nil { return }
            else if now > 0 && history[now] == imgView.image { return }
        }
        
        if now + 1 == history.count {
            history.append(imgView.image!)
        }
        else {
            history[now + 1] = imgView.image!
            history.removeSubrange((now + 2)...)
            Redo.isEnabled = false
        }
        now += 1
        Undo.isEnabled = true
    }
    func midPoint(_ p1:CGPoint, _ p2:CGPoint) -> CGPoint {
        let x = (p1.x + p2.x) / 2
        let y = (p1.y + p2.y) / 2
        return CGPoint(x: x, y: y)
    }
    
    func drawing() {
        let renderer = UIGraphicsImageRenderer(size: imgView.bounds.size)
        let image = renderer.image { context in
            imgView.image?.draw(in: imgView.bounds)
            
            path?.lineCapStyle = .round
            path?.lineWidth = lineWidth
            if Eraser.isSelected { context.cgContext.setBlendMode(.clear) }
            else { lineColor.setStroke();  }
            path?.stroke()
        }
        imgView.image = image
    }
}

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
