////
////  ViewController.swift
////  VRKitExample
////
////  Created by Leon Lee on 03/14/2018.
////  Copyright © 2018 Leon Lee. All rights reserved.
////
//
import UIKit
import OmniVirtSDK

class PlayerViewController: UIViewController, VRPlayerDelegate {

    @IBOutlet weak var player: VRPlayer!
    var isExpanded: Bool = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        player.delegate = self;

        // Use this method to disable interface
        //
        // player.interface = Mode.OFF;

        player.load(withContentID: 20053);
        player.cardboard = .On

        // For manually creating VRplayer without storyboard, please uncomment the following code.

        /*let _player = VRPlayer.create();
         _player.load(withContentID: 20);
         _player.frame = self.view.frame;
         self.view.addSubview(_player);
         _player.layoutSubviews();*/

//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(PlayerViewController.rotate(_:)),
//            name: NSNotification.Name.UIDeviceOrientationDidChange,
//            object: nil)
    }

    func rotate(_ notification: Notification) {
        if (UIDevice.current.orientation == UIDeviceOrientation.faceUp || UIDeviceOrientationIsPortrait(UIDevice.current.orientation))
        {
            if (isExpanded) {
//                logHeight.constant = 0.0;
            }
            else {
//                logHeight.constant = 380.0;
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func playerLoaded(_ player: VRPlayer, withMaximumQuality maximum:Int, andCurrentQuality current:Quality, andCardboardMode mode:Mode) {
//        log.text! += "Loaded maximumQuality: " + String(describing: maximum) + " currentQuality: " + String(describing: current) + "\n"
//
        // Use this method to start playing
        //
        // player.play()
    }
    func playerStarted(_ player: VRPlayer) {
//        log.text! += "Started\n"
    }
    func playerPaused(_ player: VRPlayer) {
//        log.text! += "Paused\n"
    }
    func playerEnded(_ player: VRPlayer) {
//        log.text! += "Ended\n"
    }
    func playerSkipped(_ player: VRPlayer) {
//        log.text! += "Skipped\n"
    }
    func playerDurationChanged(_ player: VRPlayer, withValue value:Double) {
        // log.text! += "Duration changed to " + String(value) + "\n"
    }
    func playerProgressChanged(_ player: VRPlayer, withValue value:Double) {
        // log.text! += "Progress changed to " + String(value) + "\n"
    }
    func playerBufferChanged(_ player: VRPlayer, withValue value:Double) {
        // log.text! += "Buffer changed to " + String(value) + "\n"
    }
    func playerSeekChanged(_ player: VRPlayer, withValue value:Double) {
//        log.text! += "Seek changed to " + String(value) + "\n"
    }
    func playerCardboardChanged(_ player: VRPlayer, withMode value:Mode) {
//        log.text! += "Cardboard changed to " + String(describing: value) + "\n"
    }
    func playerVolumeChanged(_ player: VRPlayer, withLevel value:Double) {
//        log.text! += "Audio changed to " + String(value) + "\n"
    }
    func playerQualityChanged(_ player: VRPlayer, withQuality value:Quality) {
//        log.text! += "Quality changed to " + String(describing: value) + "\n"
    }
    func playerExpanded(_ player: VRPlayer) {
//        log.text! += "Expanded\n"
        isExpanded = true;

        if (UIDevice.current.orientation == UIDeviceOrientation.faceUp || UIDeviceOrientationIsPortrait(UIDevice.current.orientation))
        {
//            logHeight.constant = 0.0
        }
    }
    func playerCollapsed(_ player: VRPlayer) {
//        log.text! += "Collapsed\n"
        isExpanded = false;

        if (UIDevice.current.orientation == UIDeviceOrientation.faceUp || UIDeviceOrientationIsPortrait(UIDevice.current.orientation))
        {
//            logHeight.constant = 380.0
        }
    }
    func playerLatitudeChanged(_ player: VRPlayer, withLatitude value:Double) {
        // log.text! += "Latitude changed to " + String(value) + "\n"
    }
    func playerLongitudeChanged(_ player: VRPlayer, withLongitude value:Double) {
        // log.text! += "Longitude changed to " + String(value) + "\n"
    }
    func playerSwitched(_ player: VRPlayer, withScene name: String, withHistory history: [String]) {
//        log.text! += "Switched to " + name + "\n"
    }
    
    
    @IBAction func backButton(_ sender: Any) {
        self.player.delegate = nil
    }

    @IBAction func homeButton(_ sender: Any) {
        self.player.delegate = nil
    }
    
}


