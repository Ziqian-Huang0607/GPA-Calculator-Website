//
//  presets.swift
//  GPA Calculator
//
//  Created by WillUHD on 2025/11/18.
//
//  New stuff implemented:
//      - parse plist data to compatible in-memory GPA model
//      - now we just need a plist, no need to hard-code stuff
//

import Foundation

// MARK: - Data Models

struct ScoreToBaseGPAMap: Decodable {
    var percentageName:String
    var letterName:String
    var baseGPA:Double
}

struct Level: Decodable {
    var name: String
    var weight: Double
    var offset: Double
}

struct Subject: Decodable {
    var name: String
    var levels:[Level]
    var customScoreToBaseGPAMap:[ScoreToBaseGPAMap]?
}

struct maxSubjectGroup: Decodable {
    var insertAt:Int
    var subjects:[Subject]
}

struct Preset: Decodable {
    var id:String
    var name: String
    var subtitle: String?
    var subjects:[Subject]
    var defaultScoreToBaseGPAMap:[ScoreToBaseGPAMap]
    var maxSubjectGroups:[maxSubjectGroup]?
    
    // This is a computed property, so it's ignored by the decoder.
    // It's used by the UI to correctly structure the views.
    func getComponents() -> [Components] {
        var rturn:[Components]=[]
        for i in 0..<subjects.count {
            rturn.append(Components(index: i, type: .regular))
        }
        if let maxGroups = maxSubjectGroups {
            for i in 0..<maxGroups.count {
                // Safely insert the component at the specified index, clamping to valid bounds.
                let insertionIndex = min(max(0, maxGroups[i].insertAt), rturn.count)
                rturn.insert(Components(index:i, type:.maxGroup), at: insertionIndex)
            }
        }
        return rturn
    }
}

// MARK: - UI Logic Models
// These models are used for UI generation and do not need to be Decodable.

struct Components {
    var index:Int
    var type:ComponentType
}

enum ComponentType {
    case regular
    case maxGroup
}

// MARK: - Global State

var presets:[Preset] = []

// MARK: - Initialization

// This function now loads and decodes the preset data from the "Presets.plist" file.
// It replaces the previous hardcoded, imperative setup.
func initPresets() {
    guard let plistURL = Bundle.main.url(forResource: "presets", withExtension: "plist") else {
        fatalError("Could not find Presets.plist in the app bundle. Make sure it's added to the target.")
    }
    
    guard let data = try? Data(contentsOf: plistURL) else {
        fatalError("Could not load data from Presets.plist.")
    }
    
    let decoder = PropertyListDecoder()
    
    do {
        presets = try decoder.decode([Preset].self, from: data)
    } catch {
        // The error provides detailed information if the plist structure doesn't match the Decodable structs.
        fatalError("Failed to decode Presets.plist: \(error)")
    }
}
