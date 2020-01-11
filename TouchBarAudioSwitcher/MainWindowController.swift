//
//  MainWindowController.swift
//  TouchBarAudioSwitcher
//
//  Created by Naoto Ida on 11.01.20.
//

import Cocoa
import CoreAudio

fileprivate extension NSTouchBar.CustomizationIdentifier {
    static let mainTouchBar = NSTouchBar.CustomizationIdentifier("touchbar-audio-switcher")
}

fileprivate extension NSTouchBarItem.Identifier {
    static let navGroup = NSTouchBarItem.Identifier("touchbar-audio-switcher.nav-group")
}

class MainWindowController: NSWindowController, NSTouchBarDelegate {
    var outputDevices = Dictionary<AudioDeviceID, String>()
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .mainTouchBar
        touchBar.defaultItemIdentifiers = [.navGroup]
        
        return touchBar
    }
    
    @IBAction func switchOutput(_ sender: NSButton) {
        let targetDeviceName = sender.title
        var targetDeviceId: AudioDeviceID? = nil
        
        for (deviceId, deviceName) in outputDevices {
            if deviceName == targetDeviceName {
                targetDeviceId = deviceId
            }
        }
        
        guard targetDeviceId != nil else { return }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDefaultOutputDevice),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        let propertySize = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, propertySize, &targetDeviceId)
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .navGroup:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let deviceIds = getOutputDevices()
            
            var buttons: [NSButton] = [];
            for deviceId in deviceIds {
                let deviceName = getDeviceName(deviceID: deviceId)
                
                let button = NSButton(
                    title: deviceName,
                    target: nil,
                    action: #selector(switchOutput(_:))
                )
                
                outputDevices[deviceId] = deviceName
                buttons.append(button)
            }
           
            let stackView = NSStackView(views: buttons)
            stackView.spacing = 1
            item.view = stackView

            return item
        default:
            return nil
        }
    }
    
    private func getDeviceName(deviceID: AudioDeviceID) -> String {
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceNameCFString),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        var result: CFString = "" as CFString
        
        AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &propertySize, &result)
        
        return result as String
    }
    
    private static func getNumberOfDevices() -> UInt32 {
        var propertySize: UInt32 = 0
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))
        
        _ = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &propertySize)
        
        return propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
    }
    
    private func getOutputDevices() -> [AudioDeviceID] {
        var property: AudioObjectPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var dataSize: UInt32 = 0
        let status: OSStatus = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &property, 0, nil, &dataSize)
        var devices:Array<AudioDeviceID> = Array()

        if status != kAudioHardwareNoError {
            devices = []
        } else {
            let deviceCount: Int = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
            var foundDevices: Array<AudioDeviceID> = Array<AudioDeviceID>(repeating: 0, count: deviceCount)
            foundDevices.withUnsafeMutableBufferPointer { ( item: inout UnsafeMutableBufferPointer<AudioDeviceID>) -> () in
                let error: OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &property, 0, nil, &dataSize, item.baseAddress!)
                if error != kAudioHardwareNoError { print("Error occured with a device: \(error)") }
            }
            devices = Array(foundDevices)
        }
        
        return devices
    }
}
