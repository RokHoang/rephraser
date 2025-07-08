//
//  HotkeyConfig.swift
//  rephraser
//
//  Created by Rok Hoang on 7/8/25.
//

import Foundation
import Carbon

struct HotkeyConfig: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: UInt32
    let displayName: String
    let sequenceCount: Int
    
    static let defaultHotkey = HotkeyConfig(
        keyCode: 8, // C key
        modifiers: UInt32(cmdKey),
        displayName: "Cmd+C (3x)",
        sequenceCount: 3
    )
    
    static let availableHotkeys: [HotkeyConfig] = [
        HotkeyConfig(keyCode: 8, modifiers: UInt32(cmdKey), displayName: "Cmd+C (3x)", sequenceCount: 3),
        HotkeyConfig(keyCode: 11, modifiers: UInt32(cmdKey), displayName: "Cmd+B (3x)", sequenceCount: 3),
        HotkeyConfig(keyCode: 17, modifiers: UInt32(cmdKey), displayName: "Cmd+T (3x)", sequenceCount: 3),
        HotkeyConfig(keyCode: 15, modifiers: UInt32(cmdKey), displayName: "Cmd+R (3x)", sequenceCount: 3),
        HotkeyConfig(keyCode: 8, modifiers: UInt32(cmdKey | shiftKey), displayName: "Cmd+Shift+C (2x)", sequenceCount: 2),
        HotkeyConfig(keyCode: 11, modifiers: UInt32(cmdKey | shiftKey), displayName: "Cmd+Shift+B (2x)", sequenceCount: 2),
        HotkeyConfig(keyCode: 17, modifiers: UInt32(cmdKey | shiftKey), displayName: "Cmd+Shift+T (2x)", sequenceCount: 2),
        HotkeyConfig(keyCode: 15, modifiers: UInt32(cmdKey | shiftKey), displayName: "Cmd+Shift+R (2x)", sequenceCount: 2)
    ]
    
    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        guard keyCode == self.keyCode else { return false }
        
        let requiredFlags = CGEventFlags(rawValue: UInt64(modifiers))
        return flags.contains(requiredFlags)
    }
}