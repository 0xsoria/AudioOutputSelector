//
//  NSSound+Extensions.swift
//  AudioOutputSelector
//
//  Created by Gabriel Soria Souza on 07/04/21.
//

import CoreAudioKit

extension NSSound {
    
    public static var systemVolume: Float {
        get {
            return self.getSystemVolume()
        }
        set {
            self.setSystemVolume(newValue)
        }
    }
    
    public static var systemVolumeIsMuted: Bool {
        get {
            return self.getSystemVolumeIsMuted()
        }
        set {
            self.systemVolumeSetMuted(newValue)
        }
    }
    
    public class func systemVolumeFadeToMute(seconds: Float = 3, blocking: Bool = true) {
        if systemVolumeIsMuted {
            return
        }
        if blocking {
            fadeSystemVolumeToMutePrivate(seconds: seconds)
        } else {
            DispatchQueue.global().async {
                self.fadeSystemVolumeToMutePrivate(seconds: seconds)
            }
        }
    }
    
    class func obtainDefaultOutputDevice() -> AudioDeviceID {
        var deviceID: AudioDeviceID = kAudioObjectUnknown
        var size: UInt32 = UInt32(MemoryLayout.size(ofValue: deviceID))
        var address: AudioObjectPropertyAddress
        
        address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                             mScope: kAudioObjectPropertyScopeGlobal,
                                             mElement: kAudioObjectPropertyElementMaster)
        
        
        if(!AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &address)) {
            print("Unable to get default audio device")
            return deviceID
        }
        
        let error: OSStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                         &address,
                                                         UInt32(0),
                                                         nil,
                                                         &size,
                                                         &deviceID)
        if error != noErr {
            print("Unable to get default audio device")
            return deviceID
        }
        
        return deviceID
    }
    
    private class func getSystemVolume() -> Float {
        var defaultDeviceId: AudioDeviceID = kAudioObjectUnknown
        var size: UInt32 = UInt32(MemoryLayout.size(ofValue: defaultDeviceId))
        var error: OSStatus
        var volume: Float32 = 0
        var address: AudioObjectPropertyAddress
        
        defaultDeviceId = obtainDefaultOutputDevice()
        if defaultDeviceId == kAudioObjectUnknown {
            return 0.0
        }
        
        address = AudioObjectPropertyAddress(mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                                             mScope: kAudioDevicePropertyScopeOutput,
                                             mElement: kAudioObjectPropertyElementMaster)
        
        if (!AudioObjectHasProperty(defaultDeviceId, &address)) {
            return 0.0
        }
        
        error = AudioObjectGetPropertyData(defaultDeviceId,
                                           &address,
                                           0,
                                           nil,
                                           &size,
                                           &volume)
        if error != noErr {
            print("Unable to read volume for device 0x%0x", defaultDeviceId)
            return 0.0
        }
        
        volume = volume > 1.0 ? 1.0 : (volume < 0.0 ? 0.0 : volume)
        
        return volume
    }
    
    private class func setSystemVolume(_ volume: Float, muteOff: Bool = true) {
        var newVolume = volume
        var address: AudioObjectPropertyAddress
        var defaultDeviceId: AudioDeviceID
        var error: OSStatus = noErr
        var muted: UInt32
        var canSetVol: DarwinBoolean = true
        var muteValue: Bool
        var hasMute: Bool = true
        var canMute: DarwinBoolean = true
        
        defaultDeviceId = obtainDefaultOutputDevice()
        if (defaultDeviceId == kAudioObjectUnknown) {
            return
        }
        
        newVolume = volume > 1.0 ? 1.0 : (volume < 0.0 ? 0.0  : volume)
        if (newVolume != volume) {
            print("Tentative volume (%5.2f) was out of range; reset to %5.2f", volume, newVolume)
        }
        
        address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                             mScope: kAudioDevicePropertyScopeOutput,
                                             mElement: kAudioObjectPropertyElementMaster)
        
        muteValue = (newVolume < 0.05)
        if muteValue {
            address.mSelector = kAudioDevicePropertyMute
            hasMute = AudioObjectHasProperty(defaultDeviceId,
                                             &address)
            if hasMute {
                error = AudioObjectIsPropertySettable(defaultDeviceId,
                                                      &address,
                                                      &canMute)
                if error != noErr || !canMute.boolValue {
                    canMute = false
                    print("Should mute device 0x%0x but did not succeed", defaultDeviceId)
                }
            } else {
                canMute = false
            }
        } else {
            address.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume
        }
        
        if (!AudioObjectHasProperty(defaultDeviceId, &address)) {
            print("The device 0x%0x does not have a volume to set", defaultDeviceId)
            return
        }
        
        error = AudioObjectIsPropertySettable(defaultDeviceId,
                                              &address,
                                              &canSetVol)
        
        if error != noErr || !canSetVol.boolValue {
            print("The volume of device 0x%0x cannot be set", defaultDeviceId)
            return
        }
        
        if muteValue && hasMute && canMute.boolValue {
            muted = 1
            error = AudioObjectSetPropertyData(defaultDeviceId,
                                               &address,
                                               0,
                                               nil,
                                               UInt32(MemoryLayout.size(ofValue: muted)),
                                               &muted)
            
            if error != noErr {
                print("The device 0x%0x was not muted", defaultDeviceId)
                return
            }
        } else {
            error = AudioObjectSetPropertyData(defaultDeviceId,
                                               &address,
                                               0,
                                               nil,
                                               UInt32(MemoryLayout.size(ofValue: newVolume)),
                                               &newVolume)
            if error != noErr {
                print("The device 0x%0x was unable to set volume", defaultDeviceId)
            }
            if muteOff && hasMute && canMute.boolValue {
                address.mSelector = kAudioDevicePropertyMute
                muted = 0
                error = AudioObjectSetPropertyData(defaultDeviceId,
                                                   &address,
                                                   0,
                                                   nil,
                                                   UInt32(MemoryLayout.size(ofValue: muted)),
                                                   &muted)
            }
        }
        if error != noErr {
            print("Unable to set volume for device 0x%0x", defaultDeviceId)
        }
    }
    
    private class func systemVolumeSetMuted(_ mute: Bool) {
        var defaultDeviceId: AudioDeviceID = kAudioObjectUnknown
        var address: AudioObjectPropertyAddress
        var hasMute: Bool
        var canMute: DarwinBoolean = true
        var error: OSStatus = noErr
        var muted: UInt32 = 0
        
        defaultDeviceId = obtainDefaultOutputDevice()
        if defaultDeviceId == kAudioObjectUnknown {
            return
        }
        
        address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                             mScope: kAudioDevicePropertyScopeOutput,
                                             mElement: kAudioObjectPropertyElementMaster)
        
        muted = mute ? 1 : 0
        
        hasMute = AudioObjectHasProperty(defaultDeviceId,
                                         &address)
        
        
        if hasMute {
            error = AudioObjectIsPropertySettable(defaultDeviceId,
                                                  &address,
                                                  &canMute)
            if error == noErr && canMute.boolValue {
                error = AudioObjectSetPropertyData(defaultDeviceId,
                                                   &address,
                                                   0,
                                                   nil,
                                                   UInt32(MemoryLayout.size(ofValue: muted)),
                                                   &muted)
                if error != noErr {
                    print("Cannot change mute status of device 0x%0x", defaultDeviceId)
                }
            }
        }
    }
    
    private class func fadeSystemVolumeToMutePrivate(seconds: Float) {
        var secs = seconds > 0 ? seconds : (seconds*(-1.0))
        secs = (secs > 10.0) ? 10.0 : secs
        
        let currentVolume = self.systemVolume
        let delta = currentVolume / (seconds * 2)
        var secondsLeft = secs
        
        while secondsLeft > 0 {
            self.systemVolume += delta
            Thread.sleep(forTimeInterval: 0.5)
            secondsLeft -= 0.5
        }
        systemVolumeIsMuted = true
        setSystemVolume(currentVolume, muteOff: false)
    }
    
    private class func getSystemVolumeIsMuted() -> Bool {
        var defaultDeviceId: AudioDeviceID = kAudioObjectUnknown
        var address: AudioObjectPropertyAddress
        var hasMute: Bool
        var canMute: DarwinBoolean = true
        var error: OSStatus = noErr
        var muted: UInt32 = 0
        var mutedSize = UInt32(MemoryLayout.size(ofValue: muted))

        defaultDeviceId = obtainDefaultOutputDevice()
        if defaultDeviceId == kAudioObjectUnknown {
            return false
        }

        address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyMute,
                                             mScope: kAudioDevicePropertyScopeOutput,
                                             mElement: kAudioObjectPropertyElementMaster)

        hasMute = AudioObjectHasProperty(defaultDeviceId, &address)
        
        if hasMute {
            error = AudioObjectIsPropertySettable(defaultDeviceId,
                                                  &address,
                                                  &canMute)
            if error == noErr && canMute.boolValue {
                error = AudioObjectGetPropertyData(defaultDeviceId,
                                                   &address,
                                                   0,
                                                   nil,
                                                   &mutedSize,
                                                   &muted)
                if muted != 0 {
                    return true
                }
            }
        }

        return false
    }
}
