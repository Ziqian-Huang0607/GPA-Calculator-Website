//
//  customViewController.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2020/11/15.
//

import UIKit
import SwiftUI

@IBDesignable
public class Gradient: UIView {
    @IBInspectable var startColor:   UIColor = UIColor.init(named: "grad1")! { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = UIColor.init(named: "grad2")! { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  true { didSet { updatePoints() }}

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }
    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }
    func updt() {
        updatePoints()
        updateLocations()
        updateColors()
    }

}
var selP:Preset?=nil
class customViewController: UIViewController {
    @IBOutlet weak var scoreSelectionControl: UISegmentedControl!
    var vwsa:[UIView]=[]
    var dsl = -1
    var prPrR=2
    var marg=13
    var enterID:String=""
    @IBOutlet weak var mainStk: UIStackView!
    @IBOutlet var masterStack: UIStackView!
    var grads:[UIView]=[]
    override func viewDidLoad() {
        selP=currentPreset
        if scoreDisplay == .percentage {
            scoreSelectionControl.selectedSegmentIndex = 0
        } else {
            scoreSelectionControl.selectedSegmentIndex = 1
        }
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
        // Do any additional setup after loading the view.
        var mstrGrps=Int(ceil(Double(presets.count)/Double(prPrR)))
        for i in 0..<mstrGrps {
            var nvw=UIStackView();
            nvw.translatesAutoresizingMaskIntoConstraints=false
            nvw.axis = .horizontal;
            nvw.distribution = .fillEqually
            nvw.spacing=CGFloat(marg) //MARK: automagically generate this
            for j in 0..<prPrR {
                if (i*prPrR+j>=presets.count) {
                    var vw=UIView();
                    vw.heightAnchor.constraint(equalToConstant: 70).isActive=true
                    vw.translatesAutoresizingMaskIntoConstraints=false
                    nvw.addArrangedSubview(vw);
                } else {
                    var vw=UIView();
                    vwsa.append(vw)
                    
                    vw.backgroundColor=UIColor.init(named:"presetFloat")!
                    vw.heightAnchor.constraint(equalToConstant: 70).isActive=true
                    vw.translatesAutoresizingMaskIntoConstraints=false
                    nvw.addArrangedSubview(vw);
                    
                    var grd = Gradient()
                    vw.addSubview(grd)
                    grd.translatesAutoresizingMaskIntoConstraints=false
                    grd.leadingAnchor.constraint(equalTo: vw.leadingAnchor).isActive=true
                    grd.trailingAnchor.constraint(equalTo: vw.trailingAnchor).isActive=true
                    grd.topAnchor.constraint(equalTo: vw.topAnchor).isActive=true
                    grd.bottomAnchor.constraint(equalTo: vw.bottomAnchor).isActive=true
                    grd.updt()
                    var dspt:[DispatchWorkItem]=[]
                    wrkitms.append(dspt)
                    
                    grads.append(grd)
                    if (selP!.id != presets[i*prPrR+j].id) {
                        grd.alpha=0
                    } else {
                        dsl=i*prPrR+j
                    }
                    
                    
                    var ivw=UIView();
                    ivw.translatesAutoresizingMaskIntoConstraints=false
                    vw.addSubview(ivw);
                    ivw.leadingAnchor.constraint(equalTo:vw.leadingAnchor,constant: 11).isActive=true
                    ivw.centerYAnchor.constraint(equalTo:vw.centerYAnchor).isActive=true
                    ivw.widthAnchor.constraint(equalToConstant: 30).isActive=true
//                    ivw.backgroundColor=UIColor.green
                    
                    var ttlbl=UILabel()
                    ttlbl.translatesAutoresizingMaskIntoConstraints=false
                    ttlbl.text=presets[i*prPrR+j].name
                    ttlbl.font=UIFont.systemFont(ofSize: 24, weight:.semibold)
                    ivw.addSubview(ttlbl)
                    ttlbl.leadingAnchor.constraint(equalTo: ivw.leadingAnchor).isActive=true
                    ttlbl.topAnchor.constraint(equalTo: ivw.topAnchor).isActive=true
                    
                    var subttllbl=UILabel();
                    subttllbl.translatesAutoresizingMaskIntoConstraints=false
                    if (presets[i*prPrR+j].subtitle==nil) {
                        if (presets[i*prPrR+j].subjects.count==1) {
                            subttllbl.text="1 subject"
                        } else {
                            subttllbl.text=String(presets[i*prPrR+j].subjects.count)+" subjects"
                        }
                    } else {
                        subttllbl.text=presets[i*prPrR+j].subtitle!
                    }
                    subttllbl.font=UIFont.systemFont(ofSize: 14, weight: .regular)
                    ivw.addSubview(subttllbl)
                    subttllbl.textColor=UIColor.init(named:"subttl")
                    subttllbl.leadingAnchor.constraint(equalTo: ivw.leadingAnchor).isActive=true
                    subttllbl.topAnchor.constraint(equalTo: ttlbl.bottomAnchor,constant:2).isActive=true
                    ivw.bottomAnchor.constraint(equalTo: subttllbl.bottomAnchor).isActive=true
                    
                    var emvwbtn=UIButton();
                    emvwbtn.translatesAutoresizingMaskIntoConstraints=false
                    emvwbtn.setTitle("", for: .normal)
                    vw.addSubview(emvwbtn)
                    emvwbtn.leadingAnchor.constraint(equalTo: vw.leadingAnchor).isActive=true
                    emvwbtn.trailingAnchor.constraint(equalTo: vw.trailingAnchor).isActive=true
                    emvwbtn.topAnchor.constraint(equalTo: vw.topAnchor).isActive=true
                    emvwbtn.bottomAnchor.constraint(equalTo: vw.bottomAnchor).isActive=true
                    emvwbtn.tag=i*prPrR+j
                    emvwbtn.addTarget(self, action: #selector(itmSel), for:.touchUpInside)
                    
                    vw.clipsToBounds=true
                    vw.layer.masksToBounds=true
                    vw.layer.cornerCurve = .continuous
                    vw.layer.cornerRadius=70.0/8
                }
            }
            mainStk.insertArrangedSubview(nvw,at:i*2+1)
            if (i != mstrGrps-1) {
                var plcv=UIView()
                plcv.heightAnchor.constraint(equalToConstant: 13).isActive=true
                mainStk.insertArrangedSubview(plcv,at:i*2+2)
            }
        }
        let swiftuiview=tfPromotionView()
        let hostingController=UIHostingController(rootView: swiftuiview)
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        masterStack.insertArrangedSubview(hostingController.view, at: 2)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints=false
    }
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: true)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        currentPreset=selP
        if (scoreSelectionControl.selectedSegmentIndex == 0) {
            scoreDisplay = .percentage
        } else {
            scoreDisplay = .letter
        }
        NotificationCenter.default.post(name: Notification.Name("updatePreset"), object: nil)
    }
    @IBAction func scoreSelectionChanged(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    //TODO: Handle multiple taps lmao
    var wrkitms:[[DispatchWorkItem]]=[[]]
    @objc func itmSel(button:UIButton) {
        var tg=Int(button.tag)
        
        if selP!.id != presets[tg].id {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            let fps=120.0
            let totAdj=1.0
            let totTime=0.4
            //adjust totAdj in totTime with fps fps
            
            let stops=Int(fps*totTime)
            let stopDur=totTime/Double(stops)
            
            // animate tg to 100% opacity
            for i in 0..<wrkitms[tg].count {
                wrkitms[tg][i].cancel()
            }
            var curOpa=Int(grads[tg].alpha*CGFloat(stops))
            //animate to 30
            for i in curOpa...stops {
                var wi=DispatchWorkItem(block: { [self] in
                    grads[tg].alpha=CGFloat(grads[tg].alpha+CGFloat(totAdj/Double(stops)))
                })
                wrkitms[tg].append(wi)
                DispatchQueue.main.asyncAfter(deadline: .now()+Double(i-curOpa)*stopDur, execute: wi)
            }
            
            //animate dsl to 0% opacity
            for i in 0..<wrkitms[dsl].count {
                wrkitms[dsl][i].cancel()
            }
            var curdsl=dsl
            curOpa=Int(grads[curdsl].alpha*CGFloat(stops))
            for i in 0...curOpa {
                var wi=DispatchWorkItem(block: { [self] in
                    grads[curdsl].alpha=CGFloat(grads[curdsl].alpha-CGFloat(totAdj/Double(stops)))
                })
                wrkitms[curdsl].append(wi)
                DispatchQueue.main.asyncAfter(deadline: .now()+Double(i)*stopDur, execute: wi)
            }
            dsl=tg;
            
            selP=presets[tg]
        }
    }
}
