//
//  ViewController.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2020/11/10.
//

import UIKit
struct subjectView {
    var masterView: UIView!
    var separatorView: UIView!
    var levelSelect: UISegmentedControl
    var scoreSelect: UISegmentedControl
    var subjectLabel: UILabel
}
var subjectViews=[subjectView]()
struct maxGroupView {
    var barShow: Gradient
    var masterView: UIStackView
}
var maxMasterGroups=[maxGroupView]()
// These struct definitions are now removed from here and centralized in presets.swift
// struct Level { ... }
// struct Subject { ... }
// struct maxSubjectGroup { ... }
enum ScoreDisplay {
    case percentage
    case letter
}
var scoreDisplay = ScoreDisplay.percentage
var currentPreset:Preset?
var lgradstop:[Gradient?]=[] // lgrad
var lgradsbot:[Gradient?]=[] // lgrad
func loadDefaults() {
    currentPreset=presets[4]
}
func findPreset(presetId: String) {
    currentPreset=nil
    for i in 0..<presets.count {
        if (presets[i].id==presetId) {
            currentPreset=presets[i]
            break
        }
    }
}
var autosave=true
var bottomPadding:UIView? = nil
class ViewController: UIViewController {
    @IBOutlet weak var mainSubjectsStack: UIStackView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var editButtonRoundedRectMask: UIView!
    @IBOutlet weak var calculationResultDisplayView: UILabel!
    @IBOutlet weak var resetButtonRoundedRectMask: UIView!
    @IBAction func editWeight(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    @IBAction func reset(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        for i in 0..<subjectViews.count {
            subjectViews[i].scoreSelect.selectedSegmentIndex=0
            subjectViews[i].levelSelect.selectedSegmentIndex=0
        }
        recomputeGPA(segment: nil)
    }
    func erasePersistentStorage() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    @objc func saveData() {
        if (autosave) {
            autosave=false
            //clear everything
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            userData.setValue(currentPreset?.id,forKey:"preset")
            if scoreDisplay == .percentage {
                userData.setValue("percentage", forKey: "scoreDisplayMode")
            } else if scoreDisplay == .letter {
                userData.setValue("letter", forKey: "scoreDisplayMode")
            }
            let saveBits=currentPreset!.getComponents()
            var tot=0
            for i in 0..<saveBits.count {
                if (saveBits[i].type==ComponentType.maxGroup) {
                    for _ in 0..<currentPreset!.maxSubjectGroups![saveBits[i].index].subjects.count {
                        userData.setValue(subjectViews[tot].levelSelect.selectedSegmentIndex,forKey:"sellvlseg\(tot)")
                        userData.setValue(subjectViews[tot].scoreSelect.selectedSegmentIndex,forKey:"selscseg\(tot)")
                        tot=tot+1
                    }
                } else {
                    userData.setValue(subjectViews[tot].levelSelect.selectedSegmentIndex,forKey:"sellvlseg\(tot)")
                    userData.setValue(subjectViews[tot].scoreSelect.selectedSegmentIndex,forKey:"selscseg\(tot)")
                    tot=tot+1
                }
            }
            
            userData.setValue(true,forKey:"dt")
            userData.synchronize()
            autosave=true
        }
    }
    let userData=UserDefaults.standard
    @objc func updatePreset() {
        drawUI(doSave:true)
    }
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreset), name: Notification.Name("updatePreset"), object: nil)
        initPresets()
        self.navigationController?.navigationBar.prefersLargeTitles=true
        calculationResultDisplayView.text=""
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mainScrollView.layer.masksToBounds=true
        mainScrollView.layer.cornerRadius=mainScrollView.layer.bounds.width/35
        mainScrollView.layer.cornerCurve = .continuous
        mainScrollView.clipsToBounds=true
        mainScrollView.showsVerticalScrollIndicator=false
        editButtonRoundedRectMask.layer.masksToBounds=true
        editButtonRoundedRectMask.layer.cornerCurve = .continuous
        editButtonRoundedRectMask.layer.cornerRadius=editButtonRoundedRectMask.layer.bounds.height/2
        
        mainSubjectsStack.layer.masksToBounds=true
        mainSubjectsStack.layer.cornerCurve = .continuous
        mainSubjectsStack.layer.cornerRadius=mainSubjectsStack.layer.bounds.width/35
 
        resetButtonRoundedRectMask.clipsToBounds=true
        resetButtonRoundedRectMask.layer.masksToBounds=true
        resetButtonRoundedRectMask.layer.cornerCurve = .continuous
        resetButtonRoundedRectMask.layer.cornerRadius=editButtonRoundedRectMask.layer.bounds.height/2
        
        //MARK: Load from user data
        if (userData.value(forKey:"dt")==nil||userData.value(forKey:"preset")==nil) {
            loadDefaults()
            drawUI(doSave:true)
            recomputeGPA(segment:nil)
        } else {
            var selPreset=userData.string(forKey:"preset")!
            findPreset(presetId: selPreset)
            var gotPrst=false
            if (currentPreset==nil) {
                loadDefaults()
                drawUI(doSave:true)
                recomputeGPA(segment:nil)
                return
            }
            //load data
            var prest=userData.value(forKey:"preset")!
            drawUI(doSave:false)
            for i in 0..<subjectViews.count {
                var lselrem=userData.value(forKey:"sellvlseg\(i)")
                var sselrem=userData.value(forKey:"selscseg\(i)")
                if (lselrem is Int&&sselrem is Int) {
                    if ((lselrem as! Int) < subjectViews[i].levelSelect.numberOfSegments&&(sselrem as! Int) < subjectViews[i].scoreSelect.numberOfSegments&&(sselrem as! Int)>=0&&(lselrem as! Int)>=0) {
                        subjectViews[i].levelSelect.selectedSegmentIndex=lselrem as! Int
                        subjectViews[i].scoreSelect.selectedSegmentIndex=sselrem as! Int
                    } else {
                        subjectViews[i].levelSelect.selectedSegmentIndex=0
                        subjectViews[i].scoreSelect.selectedSegmentIndex=0
                    }
                } else {
                    subjectViews[i].levelSelect.selectedSegmentIndex=0
                    subjectViews[i].scoreSelect.selectedSegmentIndex=0
                }
            }
            var scoreDisplayModeString = userData.value(forKey: "scoreDisplayMode")
            if (scoreDisplayModeString != nil) {
                if (scoreDisplayModeString as! String == "percentage") {
                    scoreDisplay = .percentage
                } else if (scoreDisplayModeString as! String == "letter") {
                    scoreDisplay = .letter
                }
            }
            recomputeGPA(segment:nil)
        }
    }
    var maxGroupsCount=0
    let subjectCellHeight=108
    func drawUI(doSave:Bool) {
        if (bottomPadding != nil) {
            bottomPadding!.removeFromSuperview()
        }
        assert(currentPreset != nil,"Draw called when preset is nil!")
        for i in subjectViews {
            i.masterView.removeFromSuperview()
        }
        subjectViews.removeAll()
        for i in 0..<maxMasterGroups.count {
            maxMasterGroups[i].masterView.removeFromSuperview()
        }
        lastMaxForMaxSubjectGroups.removeAll()
        var currentSubjectComponents=currentPreset!.getComponents()
        maxGroupsCount=0
        if (currentPreset!.maxSubjectGroups != nil) {
            for i in 0..<currentPreset!.maxSubjectGroups!.count {
                maxGroupsCount+=currentPreset!.maxSubjectGroups![i].subjects.count
            }
            maxSubjectGroupAlphaAnimationTasks=[[DispatchWorkItem]](repeating: [], count: maxGroupsCount)
            lastMaxForMaxSubjectGroups=[Int](repeating:0, count:currentPreset!.maxSubjectGroups!.count)
            maxSubjectGroupGradientAnimationTasks=[[DispatchWorkItem]](repeating:[], count:currentPreset!.maxSubjectGroups!.count)
            currentMaxSubjectGroupsGradientPosition=[Double](repeating: 0, count: currentPreset!.maxSubjectGroups!.count)
            for i in 0..<currentPreset!.maxSubjectGroups!.count {
                lastMaxForMaxSubjectGroups[i] = -1
            }
        }
        let gradientWidth=7
        lgradstop.removeAll()
        lgradsbot.removeAll()
        if (currentPreset!.maxSubjectGroups != nil) {
            lgradstop=[Gradient?](repeating: nil, count: currentPreset!.maxSubjectGroups!.count)
            lgradsbot=[Gradient?](repeating: nil, count: currentPreset!.maxSubjectGroups!.count)
        }
        for i in 0..<currentSubjectComponents.count {
            if (currentSubjectComponents[i].type==ComponentType.maxGroup) {
                let maxGroupCellHorizontalStack=UIStackView()
                maxGroupCellHorizontalStack.distribution = .fill
                maxGroupCellHorizontalStack.axis = .horizontal
                maxMasterGroups.append(maxGroupView(barShow: Gradient(), masterView: maxGroupCellHorizontalStack))
                mainSubjectsStack.addArrangedSubview(maxGroupCellHorizontalStack)
                maxGroupCellHorizontalStack.translatesAutoresizingMaskIntoConstraints=false
                
                var miniCont=UIStackView()
                maxGroupCellHorizontalStack.addArrangedSubview(miniCont)
                maxGroupCellHorizontalStack.addSubview(miniCont)
                miniCont.topAnchor.constraint(equalTo: maxGroupCellHorizontalStack.topAnchor).isActive=true
                miniCont.bottomAnchor.constraint(equalTo: maxGroupCellHorizontalStack.bottomAnchor).isActive=true
                miniCont.translatesAutoresizingMaskIntoConstraints=false
                miniCont.alignment = .fill
                miniCont.axis = .vertical
                miniCont.distribution = .fill
                var gradientContainer=UIView()
                gradientContainer.translatesAutoresizingMaskIntoConstraints=false
                gradientContainer.widthAnchor.constraint(equalToConstant: CGFloat(gradientWidth)).isActive=true
                maxGroupCellHorizontalStack.insertArrangedSubview(gradientContainer,at: 0)
                var topSeparator=UIView()
                if i==0 {
                    topSeparator.translatesAutoresizingMaskIntoConstraints=false
                    topSeparator.heightAnchor.constraint(equalToConstant:2).isActive=true
                    topSeparator.backgroundColor=UIColor.init(named:"sep")
                    mainSubjectsStack.addArrangedSubview(topSeparator)
                }
                for j in 0..<currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects.count {
                    var subjcont=UIView()
                    subjcont.translatesAutoresizingMaskIntoConstraints=false
                    var amx=subjectView(masterView: subjcont, separatorView: UIView(), levelSelect: UISegmentedControl(), scoreSelect: UISegmentedControl(), subjectLabel: UILabel())
                    if (i+j != 0) {
                        var sepContView=UIView()
                        topSeparator=UIView()
                        topSeparator.translatesAutoresizingMaskIntoConstraints=false
                        topSeparator.heightAnchor.constraint(equalToConstant:2).isActive=true
                        topSeparator.backgroundColor=UIColor.init(named:"sep")
                        sepContView.addSubview(topSeparator)
                        miniCont.addArrangedSubview(sepContView)
                        sepContView.translatesAutoresizingMaskIntoConstraints=false
                        sepContView.trailingAnchor.constraint(equalTo: miniCont.trailingAnchor).isActive=true
                        topSeparator.topAnchor.constraint(equalTo: sepContView.topAnchor).isActive=true
                        topSeparator.bottomAnchor.constraint(equalTo: sepContView.bottomAnchor).isActive=true
                        topSeparator.leadingAnchor.constraint(equalTo: sepContView.leadingAnchor, constant: CGFloat(20-gradientWidth)).isActive=true
                        topSeparator.trailingAnchor.constraint(equalTo: sepContView.trailingAnchor).isActive=true
                        topSeparator.layer.cornerRadius=1
                        topSeparator.layer.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
                        topSeparator.clipsToBounds=true
                    }
                    amx.separatorView=topSeparator
                    miniCont.addArrangedSubview(subjcont)
                    subjcont.heightAnchor.constraint(equalToConstant:CGFloat(subjectCellHeight)).isActive=true
                    
                    var subjlbl=UILabel()
                    subjlbl.translatesAutoresizingMaskIntoConstraints=false
                    subjlbl.text=currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects[j].name
                    subjcont.addSubview(subjlbl)
                    subjlbl.font=UIFont.systemFont(ofSize:25)
                    subjlbl.topAnchor.constraint(equalTo: subjcont.topAnchor, constant: 15).isActive=true
                    subjlbl.leadingAnchor.constraint(equalTo: subjcont.leadingAnchor, constant: CGFloat(10-gradientWidth)).isActive=true
                    subjlbl.textColor=UIColor.init(named:"deselText")
                    
                    subjlbl=UILabel()
                    subjlbl.translatesAutoresizingMaskIntoConstraints=false
                    subjlbl.text=currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects[j].name
                    subjcont.addSubview(subjlbl)
                    subjlbl.font=UIFont.systemFont(ofSize:25)
                    subjlbl.topAnchor.constraint(equalTo: subjcont.topAnchor, constant: 15).isActive=true
                    subjlbl.leadingAnchor.constraint(equalTo: subjcont.leadingAnchor, constant: CGFloat(10-gradientWidth)).isActive=true
                    amx.subjectLabel=subjlbl
                    
                    var lvlsel=UISegmentedControl()
                    amx.levelSelect=lvlsel
                    lvlsel.apportionsSegmentWidthsByContent=true
                    lvlsel.translatesAutoresizingMaskIntoConstraints=false
                    for k in 0..<currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects[j].levels.count {
                        lvlsel.insertSegment(withTitle: String(currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects[j].levels[k].name), at: k, animated: false)
                    }
                    subjcont.addSubview(lvlsel)
                    lvlsel.selectedSegmentIndex=0
                    lvlsel.topAnchor.constraint(equalTo: subjcont.topAnchor, constant: 15).isActive=true
                    amx.levelSelect=lvlsel
                    lvlsel.addTarget(self, action: #selector(recomputeGPA), for:.valueChanged)
                    
                    var scsel=UISegmentedControl()
                    amx.scoreSelect=scsel
                    scsel.apportionsSegmentWidthsByContent=true
                    scsel.translatesAutoresizingMaskIntoConstraints=false
                    let scoreToBaseGPAMap = currentPreset!.maxSubjectGroups![currentSubjectComponents[i].index].subjects[j].customScoreToBaseGPAMap ?? currentPreset!.defaultScoreToBaseGPAMap
                    for k in 0..<scoreToBaseGPAMap.count {
                        scsel.insertSegment(withTitle: (scoreDisplay == .percentage ? scoreToBaseGPAMap[k].percentageName : scoreToBaseGPAMap[k].letterName), at: k, animated: false)
                    }
                    subjcont.addSubview(scsel)
                    scsel.selectedSegmentIndex=0
                    scsel.topAnchor.constraint(equalTo: subjcont.topAnchor, constant: 60).isActive=true
                    amx.scoreSelect=scsel
                    scsel.addTarget(self, action: #selector(recomputeGPA), for:.valueChanged)
                    
                    amx.scoreSelect.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor, constant:-10).isActive=true
                    amx.scoreSelect.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor, constant:10).isActive=true
                    amx.levelSelect.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor, constant: -10).isActive=true
                    amx.levelSelect.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor, constant: 140).isActive=true
                    subjectViews.append(amx)
                }
                var gradMsk=UIView()
                gradMsk.translatesAutoresizingMaskIntoConstraints=false
                gradientContainer.addSubview(gradMsk)
                gradMsk.widthAnchor.constraint(equalToConstant: 3).isActive=true
                gradMsk.topAnchor.constraint(equalTo: gradientContainer.topAnchor, constant: 17).isActive=true
                gradMsk.bottomAnchor.constraint(equalTo: gradientContainer.bottomAnchor, constant: -15).isActive=true
                gradMsk.leadingAnchor.constraint(equalTo: gradientContainer.leadingAnchor, constant: 3).isActive=true
                gradMsk.layer.cornerRadius=1.5
                gradMsk.clipsToBounds=true
                
                var botgrad=Gradient()
                botgrad.translatesAutoresizingMaskIntoConstraints=false
                botgrad.diagonalMode=false
                gradMsk.addSubview(botgrad)
                botgrad.widthAnchor.constraint(equalToConstant: 3).isActive=true
                botgrad.topAnchor.constraint(equalTo: gradientContainer.topAnchor, constant: 17).isActive=true
                botgrad.bottomAnchor.constraint(equalTo: gradientContainer.bottomAnchor, constant: -15).isActive=true
                botgrad.leadingAnchor.constraint(equalTo: gradientContainer.leadingAnchor, constant: 3).isActive=true
                botgrad.clipsToBounds=true
                botgrad.startColor=UIColor.init(named:"gradProm")!
                botgrad.endColor=UIColor.init(named:"gradDesel")!
                botgrad.updt()
                lgradsbot[currentSubjectComponents[i].index]=botgrad
                
                //MARK: Upgrad
                var upgrad=Gradient()
                upgrad.translatesAutoresizingMaskIntoConstraints=false
                upgrad.diagonalMode=false
                gradMsk.addSubview(upgrad)
                upgrad.widthAnchor.constraint(equalToConstant: 3).isActive=true
                upgrad.topAnchor.constraint(equalTo: gradientContainer.topAnchor, constant: 17).isActive=true
                upgrad.bottomAnchor.constraint(equalTo: gradientContainer.bottomAnchor, constant: -15).isActive=true
                upgrad.leadingAnchor.constraint(equalTo: gradientContainer.leadingAnchor, constant: 3).isActive=true
                upgrad.startColor=UIColor.init(named:"gradDesel")!
                upgrad.endColor=UIColor.init(named:"gradProm")!
                upgrad.updt()
                var upgradMsk=UIView(frame: CGRect(x: 0,y: 0,width: 4,height: 0))
                upgradMsk.backgroundColor = .black
                upgrad.mask=upgradMsk
                lgradstop[currentSubjectComponents[i].index]=upgrad
                
                continue
            }
            var mstr=UIView()
            mainSubjectsStack.addArrangedSubview(mstr)
            mstr.translatesAutoresizingMaskIntoConstraints=false
            
            var nv=subjectView(masterView: mstr, separatorView: UIView(), levelSelect: UISegmentedControl(), scoreSelect: UISegmentedControl(), subjectLabel: UILabel())
            if (i==0) {
                var bigS=UIView()
                bigS.translatesAutoresizingMaskIntoConstraints=false
                bigS.heightAnchor.constraint(equalToConstant:2).isActive=true
                bigS.backgroundColor=UIColor.init(named:"sep")
                nv.separatorView=bigS
            } else {
                var smolS=UIView()
                smolS.translatesAutoresizingMaskIntoConstraints=false
                smolS.heightAnchor.constraint(equalToConstant:2).isActive=true
                smolS.backgroundColor=UIColor.init(named:"sep")
                smolS.clipsToBounds = true
                smolS.layer.cornerRadius = 1
                smolS.layer.maskedCorners = [.layerMinXMinYCorner,.layerMinXMaxYCorner]
                nv.separatorView=smolS
            }
            mstr.addSubview(nv.separatorView)
            nv.separatorView.topAnchor.constraint(equalTo:mstr.topAnchor, constant:0).isActive=true
            nv.separatorView.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: 0).isActive=true
            
            mstr.heightAnchor.constraint(equalToConstant:CGFloat(subjectCellHeight)).isActive=true
            
            var subjlbl=UILabel()
            subjlbl.translatesAutoresizingMaskIntoConstraints=false
            subjlbl.text=currentPreset!.subjects[currentSubjectComponents[i].index].name
            mstr.addSubview(subjlbl)
            subjlbl.font=UIFont.systemFont(ofSize:25)
            subjlbl.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive=true
            subjlbl.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: 10).isActive=true
            nv.subjectLabel=subjlbl
            
            var lvlsel=UISegmentedControl()
            lvlsel.apportionsSegmentWidthsByContent=true
            lvlsel.translatesAutoresizingMaskIntoConstraints=false
            if (currentSubjectComponents[i].type==ComponentType.regular) {
                for j in 0..<currentPreset!.subjects[currentSubjectComponents[i].index].levels.count {
                    lvlsel.insertSegment(withTitle: String(currentPreset!.subjects[currentSubjectComponents[i].index].levels[j].name), at: j, animated: false)
                }
            }
            mstr.addSubview(lvlsel)
            lvlsel.selectedSegmentIndex=0
            lvlsel.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive=true
            nv.levelSelect=lvlsel
            lvlsel.addTarget(self, action: #selector(recomputeGPA), for:.valueChanged)
            
            var scsel=UISegmentedControl()
            scsel.apportionsSegmentWidthsByContent=true
            scsel.translatesAutoresizingMaskIntoConstraints=false
            let scoreToBaseGPAMap = currentPreset!.subjects[currentSubjectComponents[i].index].customScoreToBaseGPAMap ?? currentPreset!.defaultScoreToBaseGPAMap
            for j in 0..<scoreToBaseGPAMap.count {
                scsel.insertSegment(withTitle: (scoreDisplay == .percentage ? scoreToBaseGPAMap[j].percentageName : scoreToBaseGPAMap[j].letterName), at: j, animated: false)
            }
            mstr.addSubview(scsel)
            scsel.selectedSegmentIndex=0
            scsel.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 60).isActive=true
            nv.scoreSelect=scsel
            scsel.addTarget(self, action: #selector(recomputeGPA), for:.valueChanged)
            
            subjectViews.append(nv)
            if (i==0) {
                nv.separatorView.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor).isActive=true
                nv.separatorView.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor).isActive=true
            } else {
                nv.separatorView.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor, constant: 20).isActive=true
                nv.separatorView.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor).isActive=true
            }
            nv.scoreSelect.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor, constant:-10).isActive=true
            nv.scoreSelect.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor, constant:10).isActive=true
            nv.levelSelect.trailingAnchor.constraint(equalTo: mainSubjectsStack.trailingAnchor, constant: -10).isActive=true
            nv.levelSelect.leadingAnchor.constraint(equalTo: mainSubjectsStack.leadingAnchor, constant: 140).isActive=true
        }
        if doSave {
            recomputeGPA(segment: nil)
        }
        var botBuf=UIView();
        botBuf.heightAnchor.constraint(equalToConstant: 10).isActive=true
        bottomPadding=botBuf
        mainSubjectsStack.addArrangedSubview(botBuf)
    }
    var maxSubjectGroupAlphaAnimationTasks:[[DispatchWorkItem]]=[[]]
    var lastMaxForMaxSubjectGroups:[Int]=[]
    var maxSubjectGroupGradientAnimationTasks:[[DispatchWorkItem]]=[[]]
    var currentMaxSubjectGroupsGradientPosition:[Double]=[]
    @objc func recomputeGPA(segment: UISegmentedControl?) {
        print("-----GPA COMPUTE-----")
        assert(currentPreset != nil,"Preset is nil while running evaluation!")
        saveData()
        if (segment != nil) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // do anything here that'll require knowing which specific slider was changed
        }
        var ans=0.0
        var ttlCred=0.0
        var subjsen=currentPreset!.getComponents()
        var tot=0
        var mxtot=0 //to keep track of the current maxsubj ID
        for i in 0..<subjsen.count {
            if (subjsen[i].type == .regular) {
                print("Calculating for reg subject \(currentPreset!.subjects[subjsen[i].index].name)")
                let scoreToBaseGPAMap=currentPreset!.subjects[subjsen[i].index].customScoreToBaseGPAMap ?? currentPreset!.defaultScoreToBaseGPAMap;
                var bs=scoreToBaseGPAMap[subjectViews[tot].scoreSelect.selectedSegmentIndex].baseGPA-currentPreset!.subjects[subjsen[i].index].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].offset
                bs=max(bs,0)
                print("Base \(bs)")
                bs*=currentPreset!.subjects[subjsen[i].index].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].weight
                print("Weight \(currentPreset!.subjects[subjsen[i].index].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].weight)")
                ans+=bs
                ttlCred+=currentPreset!.subjects[subjsen[i].index].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].weight
                tot=tot+1
                print()
            } else {
                var selledInd=0
                var mstrBs = -10.0
                var selledtot=0
                var hasAP=false
                for j in 0..<currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count {
                    if currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[j].levels[subjectViews[tot+j].levelSelect.selectedSegmentIndex].name=="AP" {
                        hasAP=true
                        break
                    }
                }
                for j in 0..<currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count {
                    if hasAP&&currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[j].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].name != "AP" {
                        tot=tot+1
                        mxtot=mxtot+1
                        continue
                    }
                    let scoreToBaseGPAMap=currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[j].customScoreToBaseGPAMap ?? currentPreset!.defaultScoreToBaseGPAMap;
                    var bs=scoreToBaseGPAMap[subjectViews[tot].scoreSelect.selectedSegmentIndex].baseGPA-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[j].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].offset
                    bs=max(bs,0)
                    bs*=currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[j].levels[subjectViews[tot].levelSelect.selectedSegmentIndex].weight
                    if (mstrBs<bs&&abs(mstrBs-bs)>0.00001) {
                        mstrBs=bs
                        selledInd=j
                        selledtot=tot
                    }
                    tot=tot+1
                    mxtot=mxtot+1
                }
                mstrBs=max(mstrBs,0)
                ans+=mstrBs
                ttlCred+=currentPreset!.maxSubjectGroups![subjsen[i].index].subjects[selledInd].levels[subjectViews[selledtot].levelSelect.selectedSegmentIndex].weight
                let topC=17.0
                let botC=Double(subjectCellHeight*currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count-15)
                
                let offsetA=1.0/6
                let offsetB=1.0/2
                
                let coordlvl=Double(selledInd*subjectCellHeight)+Double(subjectCellHeight)/2.0
                let toptop=coordlvl-Double(subjectCellHeight)*(offsetA+offsetB)
                let topbot=coordlvl-Double(subjectCellHeight)*offsetA
                let bottop=coordlvl+Double(subjectCellHeight)*offsetA
                let botbot=coordlvl+Double(subjectCellHeight)*(offsetA+offsetB)
                
                if lastMaxForMaxSubjectGroups[subjsen[i].index] == -1 {
                    for j in 0..<currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count {
                        if (j != selledInd) {
                            subjectViews[tot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+j].subjectLabel.alpha=0
                        } else {
                            subjectViews[tot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+j].subjectLabel.alpha=1
                        }
                    }
                    lastMaxForMaxSubjectGroups[subjsen[i].index]=selledInd
                    var upgradMsk=UIView(frame: CGRect(x: 0,y: 0,width: 4,height: coordlvl-topC))
                    upgradMsk.backgroundColor = .black
                    currentMaxSubjectGroupsGradientPosition[subjsen[i].index]=coordlvl
                    lgradstop[subjsen[i].index]!.mask=upgradMsk
                    lgradstop[subjsen[i].index]!.startLocation=Double(toptop-topC)/Double(botC-topC)
                    lgradstop[subjsen[i].index]!.endLocation=Double(topbot-topC)/Double(botC-topC)
                    lgradsbot[subjsen[i].index]!.startLocation=Double(bottop-topC)/Double(botC-topC)
                    lgradsbot[subjsen[i].index]!.endLocation=Double(botbot-topC)/Double(botC-topC)
                }
                if lastMaxForMaxSubjectGroups[subjsen[i].index] != selledInd {
                    let alphaLstInd=mxtot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+lastMaxForMaxSubjectGroups[subjsen[i].index]
                    let vwsLstInd=tot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+lastMaxForMaxSubjectGroups[subjsen[i].index]
                    let alphaSelInd=mxtot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+selledInd
                    let vwsSelInd=tot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+selledInd
                                        
                    //cancel all animations on the last one
                    for j in 0..<maxSubjectGroupAlphaAnimationTasks[alphaLstInd].count {
                        maxSubjectGroupAlphaAnimationTasks[alphaLstInd][j].cancel()
                    }
                    maxSubjectGroupAlphaAnimationTasks[alphaLstInd].removeAll()
                    
                    //cancel all animations on the current one
                    for j in 0..<maxSubjectGroupAlphaAnimationTasks[mxtot-currentPreset!.maxSubjectGroups![subjsen[i].index].subjects.count+selledInd].count {
                        maxSubjectGroupAlphaAnimationTasks[alphaSelInd][j].cancel()
                    }
                    maxSubjectGroupAlphaAnimationTasks[alphaSelInd].removeAll()
                    
                    //animate selledInd to 100% opacity and lstmax to 0
                    
                    let fps=120.0
                    let totAdj=1.0
                    let totTime=0.3
                    
                    let stops=Int(fps*totTime)
                    let stopDur=totTime/Double(stops)
                    
                    //animate selledInd to 0%
                    var curOpa=Int(subjectViews[vwsSelInd].subjectLabel.alpha*CGFloat(stops))
                    
                    for j in curOpa...stops {
                        var wi=DispatchWorkItem(block: { [self] in
                            subjectViews[vwsSelInd].subjectLabel.alpha+=CGFloat(totAdj/Double(stops))
                        })
                        maxSubjectGroupAlphaAnimationTasks[alphaSelInd].append(wi)
                        DispatchQueue.main.asyncAfter(deadline: .now()+Double(j-curOpa)*stopDur, execute: wi)
                    }
                    
                    //animate lstmax to 100
                    curOpa=Int(subjectViews[vwsLstInd].subjectLabel.alpha*CGFloat(stops))
                    for j in 0...curOpa {
                        var wi=DispatchWorkItem(block: { [self] in
                            subjectViews[vwsLstInd].subjectLabel.alpha-=CGFloat(totAdj/Double(stops))
                        })
                        maxSubjectGroupAlphaAnimationTasks[alphaLstInd].append(wi)
                        DispatchQueue.main.asyncAfter(deadline: .now()+Double(j)*stopDur, execute: wi)
                    }
                    
                    //TODO: Update the gradient too
                    for j in 0..<maxSubjectGroupGradientAnimationTasks[subjsen[i].index].count {
                        maxSubjectGroupGradientAnimationTasks[subjsen[i].index][j].cancel()
                    }
                    let ttTime=0.4
                    let gradSpeed=Double(botC-topC)/ttTime //gradspeed - pixels/second
                    
                    // go to coordlvl
                    var stps=Int(ceil(Double(abs(currentMaxSubjectGroupsGradientPosition[subjsen[i].index]-coordlvl))/gradSpeed*fps))
                    for j in 0..<stps {
                        var wi=DispatchWorkItem(block: { [self] in
                            let toptopi=currentMaxSubjectGroupsGradientPosition[subjsen[i].index]-Double(subjectCellHeight)*(offsetA+offsetB)
                            let topboti=currentMaxSubjectGroupsGradientPosition[subjsen[i].index]-Double(subjectCellHeight)*offsetA
                            let bottopi=currentMaxSubjectGroupsGradientPosition[subjsen[i].index]+Double(subjectCellHeight)*offsetA
                            let botboti=currentMaxSubjectGroupsGradientPosition[subjsen[i].index]+Double(subjectCellHeight)*(offsetA+offsetB)
                            
                            var upgradMsk=UIView(frame: CGRect(x: 0,y: 0,width: 4,height: currentMaxSubjectGroupsGradientPosition[subjsen[i].index]-topC))
                            upgradMsk.backgroundColor = .black
                            lgradstop[subjsen[i].index]!.mask=upgradMsk
                            lgradstop[subjsen[i].index]!.startLocation=Double(toptopi-topC)/Double(botC-topC)
                            lgradstop[subjsen[i].index]!.endLocation=Double(topboti-topC)/Double(botC-topC)
                            lgradsbot[subjsen[i].index]!.startLocation=Double(bottopi-topC)/Double(botC-topC)
                            lgradsbot[subjsen[i].index]!.endLocation=Double(botboti-topC)/Double(botC-topC)
                            
                            if (currentMaxSubjectGroupsGradientPosition[subjsen[i].index]<coordlvl) {
                                //go up
                                currentMaxSubjectGroupsGradientPosition[subjsen[i].index]=min(currentMaxSubjectGroupsGradientPosition[subjsen[i].index]+gradSpeed/fps,coordlvl)
                            } else {
                                currentMaxSubjectGroupsGradientPosition[subjsen[i].index]=max(currentMaxSubjectGroupsGradientPosition[subjsen[i].index]-gradSpeed/fps,coordlvl)
                            }
                        })
                        maxSubjectGroupGradientAnimationTasks[subjsen[i].index].append(wi)
                        DispatchQueue.main.asyncAfter(deadline: .now()+Double(j)*ttTime/fps, execute: wi)
                    }
                    
                    lastMaxForMaxSubjectGroups[subjsen[i].index]=selledInd
                }
            }
        }
        if (ttlCred != 0) {
            ans/=ttlCred
        }
        var gpaDisp=String(Int(round(ans*1000)))
        while gpaDisp.count<4 {
            gpaDisp.insert("0", at: gpaDisp.startIndex)
        }
        calculationResultDisplayView.text="Your GPA: "+gpaDisp[gpaDisp.startIndex..<gpaDisp.index(gpaDisp.endIndex, offsetBy: -3)]+"."+gpaDisp[gpaDisp.index(gpaDisp.endIndex, offsetBy: -3)..<gpaDisp.endIndex]
    }
    
}
