//
//  ViewController.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2020/11/10.
//  Modified by willuhd on 2025/11/22.
//
//  - new level selection logic for more levels on many screen types
//  - live update for autofetch
//  - adapts to refined in-memory data models
//

import UIKit

// MARK: - Memory Models

struct subjectView {
    var masterView: UIView!
    var separatorView: UIView!
    var levelSegment: UISegmentedControl?
    var levelButton: UIButton?
    var scoreSelect: UISegmentedControl
    var subjectLabel: UILabel
}

var subjectViews = [subjectView]()
var currentPreset: Preset?
var activeSubjects: [Subject] = []

enum ScoreDisplay {
    case percentage
    case letter
}
var scoreDisplay = ScoreDisplay.percentage
var autosave = true
var bottomPadding: UIView? = nil

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mainSubjectsStack: UIStackView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var editButtonRoundedRectMask: UIView!
    @IBOutlet weak var calculationResultDisplayView: UILabel!
    @IBOutlet weak var resetButtonRoundedRectMask: UIView!
    
    let userData = UserDefaults.standard
    
    @IBAction func editWeight(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @IBAction func reset(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        for i in 0..<subjectViews.count {
            subjectViews[i].scoreSelect.selectedSegmentIndex = 0
            
            if let seg = subjectViews[i].levelSegment {
                seg.selectedSegmentIndex = 0
            } else if let btn = subjectViews[i].levelButton {
                btn.tag = 0
                if let firstLevel = activeSubjects[i].levels.first {
                    btn.setTitle(firstLevel.name, for: .normal)
                }
            }
        }
        recomputeGPA(sender: nil)
    }
    
    // MARK: - Update Logic
    
    @objc func updatePreset() {
        // UI updates must be on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            initPresets() // forces a reload
            if let currentId = currentPreset?.id {
                // try to get the last module selection of the user
                if let refreshedPreset = presets.first(where: { $0.id == currentId }) {
                    currentPreset = refreshedPreset
                } else {
                    // fallback if no longer matches
                    currentPreset = presets.first
                }
            } else {
                // 1st launch cold start
                if let id = self.userData.string(forKey: "preset"), let p = presets.first(where: { $0.id == id }) {
                    currentPreset = p
                } else {
                    currentPreset = presets.first
                }
            }
            
            // refresh everything + redraw dynamically
            if let p = currentPreset {
                activeSubjects = getActiveSubjects(for: p)
                self.drawUI(doSave: true)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Save current state before layout changes
        recomputeGPA(sender: nil)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            // Re-draw UI when the rotation animation is complete and bounds are updated
            self.drawUI(doSave: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        if currentPreset != nil {
            updatePreset()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // user sees something immediately even during update
        // the update will change the UI dynamically
        initPresets()
        
        // listen for download complete
        NotificationCenter.default.addObserver(self, selector: #selector(updatePreset), name: Notification.Name("updatePreset"), object: nil)
        
        // check for new versions
        OTAUpdater.shared.checkForUpdates()
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        calculationResultDisplayView.text = ""
        
        mainScrollView.layer.masksToBounds = true
        mainScrollView.layer.cornerRadius = mainScrollView.layer.bounds.width / 35
        mainScrollView.layer.cornerCurve = .continuous
        mainScrollView.showsVerticalScrollIndicator = false
        
        editButtonRoundedRectMask.layer.masksToBounds = true
        editButtonRoundedRectMask.layer.cornerCurve = .continuous
        editButtonRoundedRectMask.layer.cornerRadius = editButtonRoundedRectMask.layer.bounds.height / 2
        
        mainSubjectsStack.layer.masksToBounds = true
        mainSubjectsStack.layer.cornerCurve = .continuous
        mainSubjectsStack.layer.cornerRadius = mainSubjectsStack.layer.bounds.width / 35
        
        resetButtonRoundedRectMask.clipsToBounds = true
        resetButtonRoundedRectMask.layer.masksToBounds = true
        resetButtonRoundedRectMask.layer.cornerCurve = .continuous
        resetButtonRoundedRectMask.layer.cornerRadius = editButtonRoundedRectMask.layer.bounds.height / 2

        if let mode = userData.string(forKey: "scoreDisplayMode") {
            scoreDisplay = (mode == "letter") ? .letter : .percentage
        }
        
        updatePreset()
    }
    
    // MARK: - drawing
    
    let subjectCellHeight = 108
    
    func drawUI(doSave: Bool) {
        if bottomPadding != nil { bottomPadding!.removeFromSuperview() }
        for i in subjectViews { i.masterView.removeFromSuperview() }
        subjectViews.removeAll()
        
        guard let _ = currentPreset else { return }
        
        for i in 0..<activeSubjects.count {
            let mstr = UIView()
            mainSubjectsStack.addArrangedSubview(mstr)
            mstr.translatesAutoresizingMaskIntoConstraints = false
            mstr.heightAnchor.constraint(equalToConstant: CGFloat(subjectCellHeight)).isActive = true
            
            var nv = subjectView(masterView: mstr, separatorView: UIView(), levelSegment: nil, levelButton: nil, scoreSelect: UISegmentedControl(), subjectLabel: UILabel())
            
            let sep = UIView()
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.heightAnchor.constraint(equalToConstant: 2).isActive = true
            sep.backgroundColor = UIColor(named: "sep")
            mstr.addSubview(sep)
            nv.separatorView = sep
            sep.topAnchor.constraint(equalTo: mstr.topAnchor).isActive = true
            sep.trailingAnchor.constraint(equalTo: mstr.trailingAnchor).isActive = true
            sep.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: (i == 0 ? 0 : 20)).isActive = true
            if i != 0 {
                sep.layer.cornerRadius = 1
                sep.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            }
            
            let levels = activeSubjects[i].levels
            
            let containerWidth = self.view.bounds.width - 40
            let nameWidth = (activeSubjects[i].name as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 25)]).width
            var segmentsWidth: CGFloat = 0
            for l in levels {
                segmentsWidth += (l.name as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 13)]).width + 24
            }
            let requiredWidth = nameWidth + segmentsWidth

            // if won't fit into the UI -> use a combobox
            let isTooWide = requiredWidth > containerWidth
            
            var anchorView: UIView!
            
            if isTooWide {
                let btn = UIButton(type: .system)
                btn.translatesAutoresizingMaskIntoConstraints = false
                btn.backgroundColor = UIColor.secondarySystemFill
                btn.layer.cornerRadius = 6
                btn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
                btn.setTitle(levels.first?.name ?? "", for: .normal)
                btn.tag = 0
                btn.addTarget(self, action: #selector(presentLevelSelector(_:)), for: .touchUpInside)
                mstr.addSubview(btn)
                btn.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive = true
                btn.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: -10).isActive = true
                nv.levelButton = btn
                anchorView = btn
            } else {
                let lvl = UISegmentedControl()
                lvl.apportionsSegmentWidthsByContent = true
                lvl.translatesAutoresizingMaskIntoConstraints = false
                for (k, level) in levels.enumerated() {
                    lvl.insertSegment(withTitle: level.name, at: k, animated: false)
                }
                mstr.addSubview(lvl)
                lvl.selectedSegmentIndex = 0
                lvl.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive = true
                lvl.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: -10).isActive = true
                lvl.setContentHuggingPriority(.defaultLow, for: .horizontal)
                lvl.setContentCompressionResistancePriority(.required, for: .horizontal)
                lvl.addTarget(self, action: #selector(recomputeGPA), for: .valueChanged)
                nv.levelSegment = lvl
                anchorView = lvl
            }
            
            let lbl = UILabel()
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.text = activeSubjects[i].name
            lbl.font = UIFont.systemFont(ofSize: 25)
            lbl.lineBreakMode = .byTruncatingTail
            mstr.addSubview(lbl)
            lbl.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 15).isActive = true
            lbl.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: 10).isActive = true
            lbl.trailingAnchor.constraint(equalTo: anchorView.leadingAnchor, constant: -20).isActive = true
            lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            nv.subjectLabel = lbl
            
            let sc = UISegmentedControl()
            sc.apportionsSegmentWidthsByContent = true
            sc.translatesAutoresizingMaskIntoConstraints = false
            let map = activeSubjects[i].customScoreToBaseGPAMap ?? commonScoreMap
            for (k, item) in map.enumerated() {
                sc.insertSegment(withTitle: (scoreDisplay == .percentage ? item.percentageName : item.letterName), at: k, animated: false)
            }
            mstr.addSubview(sc)
            sc.selectedSegmentIndex = 0
            sc.topAnchor.constraint(equalTo: mstr.topAnchor, constant: 60).isActive = true
            sc.leadingAnchor.constraint(equalTo: mstr.leadingAnchor, constant: 10).isActive = true
            sc.trailingAnchor.constraint(equalTo: mstr.trailingAnchor, constant: -10).isActive = true
            sc.addTarget(self, action: #selector(recomputeGPA), for: .valueChanged)
            nv.scoreSelect = sc
            
            subjectViews.append(nv)
        }
        
        if !doSave {
            for i in 0..<subjectViews.count {
                let savedLvlIndex = userData.value(forKey: "sellvlseg\(i)") as? Int ?? 0
                if let seg = subjectViews[i].levelSegment, savedLvlIndex < seg.numberOfSegments {
                    seg.selectedSegmentIndex = savedLvlIndex
                } else if let btn = subjectViews[i].levelButton, savedLvlIndex < activeSubjects[i].levels.count {
                    btn.tag = savedLvlIndex
                    btn.setTitle(activeSubjects[i].levels[savedLvlIndex].name, for: .normal)
                }
                if let s = userData.value(forKey: "selscseg\(i)") as? Int, s < subjectViews[i].scoreSelect.numberOfSegments {
                    subjectViews[i].scoreSelect.selectedSegmentIndex = s
                }
            }
        }
        
        let botBuf = UIView()
        botBuf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        bottomPadding = botBuf
        mainSubjectsStack.addArrangedSubview(botBuf)
        
        if doSave { recomputeGPA(sender: nil) }
    }
    
    @objc func presentLevelSelector(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        guard let subjectIndex = subjectViews.firstIndex(where: { $0.levelButton === sender }) else { return }
        let subject = activeSubjects[subjectIndex]
        let alert = UIAlertController(title: "Select Level", message: nil, preferredStyle: .actionSheet)
        for (index, level) in subject.levels.enumerated() {
            let action = UIAlertAction(title: level.name, style: .default) { [weak self] _ in
                sender.setTitle(level.name, for: .normal)
                sender.tag = index
                self?.recomputeGPA(sender: sender)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func recomputeGPA(sender: Any?) {
        if sender != nil {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        if autosave {
            userData.setValue(currentPreset?.id, forKey: "preset")
            userData.setValue(scoreDisplay == .percentage ? "percentage" : "letter", forKey: "scoreDisplayMode")
            for i in 0..<subjectViews.count {
                let lvlIdx = subjectViews[i].levelSegment?.selectedSegmentIndex ?? subjectViews[i].levelButton?.tag ?? 0
                userData.setValue(lvlIdx, forKey: "sellvlseg\(i)")
                userData.setValue(subjectViews[i].scoreSelect.selectedSegmentIndex, forKey: "selscseg\(i)")
            }
        }
        
        var totalWeightedPoints = 0.0
        var totalWeight = 0.0
        
        for i in 0..<activeSubjects.count {
            let subj = activeSubjects[i]
            
            let lvlIdx: Int
            if let seg = subjectViews[i].levelSegment {
                lvlIdx = seg.selectedSegmentIndex
            } else if let btn = subjectViews[i].levelButton {
                lvlIdx = btn.tag
            } else {
                lvlIdx = 0
            }
            
            let scrIdx = subjectViews[i].scoreSelect.selectedSegmentIndex
            let map = subj.customScoreToBaseGPAMap ?? commonScoreMap
            let safeLvlIdx = min(max(0, lvlIdx), subj.levels.count - 1)
            let level = subj.levels[safeLvlIdx]
            
            // calculate the minimum offset available for this subject
            // subtract minOffset from the current level's offset
            let minOffset = subj.levels.map { $0.offset }.min() ?? 0.0
            let effectiveOffset = max(0, level.offset - minOffset)
            
            let base = map[scrIdx].baseGPA
            
            let weightForPoints = level.weightOverride ?? subj.weight
            let weightForCredits = subj.weight
            
            let subjectGPA = max(0, base - effectiveOffset)
            let points = subjectGPA * weightForPoints
            
            totalWeightedPoints += points
            totalWeight += weightForCredits
        }
        
        let finalGPA = totalWeight > 0 ? totalWeightedPoints / totalWeight : 0.0
        let gpaDisp = String(format: "%.3f", finalGPA)
        calculationResultDisplayView.text = "Your GPA: \(gpaDisp)"
    }
}
