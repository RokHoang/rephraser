//
//  GlobalHotkeyManager.swift
//  rephraser
//
//  Created by Rok Hoang on 7/7/25.
//

import Foundation
import Carbon
import AppKit
import UserNotifications

class GlobalHotkeyManager: ObservableObject {
    private var eventTap: CFMachPort?
    private var keyPressCount = 0
    private var lastKeyPressTime: CFTimeInterval = 0
    private let maxSequenceInterval: CFTimeInterval = 0.5
    
    weak var appState: AppState?
    
    init(appState: AppState) {
        self.appState = appState
        setupEventTap()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon!).takeUnretainedValue() as GlobalHotkeyManager? else {
                    return Unmanaged.passUnretained(event)
                }
                
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        guard let appState = appState else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let hotkeyConfig = appState.customHotkey
        
        if hotkeyConfig.matches(keyCode: keyCode, flags: flags) {
            let currentTime = CFAbsoluteTimeGetCurrent()
            
            if currentTime - lastKeyPressTime <= maxSequenceInterval {
                keyPressCount += 1
            } else {
                keyPressCount = 1
            }
            
            lastKeyPressTime = currentTime
            
            if keyPressCount >= hotkeyConfig.sequenceCount {
                keyPressCount = 0
                DispatchQueue.main.async {
                    self.triggerRephrasing()
                }
            }
        } else {
            keyPressCount = 0
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func triggerRephrasing() {
        guard let appState = appState else { 
            return 
        }
        
        if appState.claudeAPIKey.isEmpty {
            showNotification(title: "Rephraser", message: "Please configure your Claude API key in settings")
            return
        }
        
        let textManager = TextManager(appState: appState)
        textManager.processSelectedText()
    }
    
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }
}