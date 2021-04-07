//
//  ViewController.swift
//  AudioOutputSelector
//
//  Created by Gabriel Soria Souza on 13/02/21.
//

import Cocoa

final class AudioOutputSelectorViewController: NSViewController {

    override func loadView() {
        self.view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sound = NSSound()
        print(NSSound.obtainDefaultOutputDevice())
        print(NSSound.systemVolume)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
