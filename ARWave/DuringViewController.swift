//
//  DuringViewController.swift
//  ARWave
//
//  Created by Leon Lee on 4/11/18.
//  Copyright © 2018 Leon Lee. All rights reserved.
//

import UIKit
import ARKit

class DuringViewController: UIViewController, ARSCNViewDelegate {

    let modelNode = SCNNode()
    var isDetecing = true

    @IBOutlet weak var messageBox: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        messageBox.text = "Scan a flat area..."
        addTapGestureToSceneView()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchRecognized(pinch:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(pan:)))
        self.view.addGestureRecognizer(pinchGesture)
        self.view.addGestureRecognizer(panGesture)
        
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let standardConfiguration: ARWorldTrackingConfiguration = {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            return configuration
        }()
        
        // Run the view's session
        sceneView.session.run(standardConfiguration)
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        if isDetecing {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            // 2
            let width = CGFloat(planeAnchor.extent.x)
            let height = CGFloat(planeAnchor.extent.z)
            let plane = SCNPlane(width: width, height: height)
            
            // 3
            plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
            
            // 4
            let planeNode = SCNNode(geometry: plane)
            
            // 5
            let x = CGFloat(planeAnchor.center.x)
            let y = CGFloat(planeAnchor.center.y)
            let z = CGFloat(planeAnchor.center.z)
            planeNode.position = SCNVector3(x,y,z)
            planeNode.eulerAngles.x = -.pi / 2
            
            // 6
            node.addChildNode(planeNode)
            isDetecing = false
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        messageBox.text = "Tab to place a table. Don't worry about the table. You will use this later."
    }
    
    @objc func addTableToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        modelNode.position = SCNVector3(x,y,z)

        guard let shipScene = SCNScene(named: "art.scnassets/test.dae")
            else { return }
        
        let wrapperNode = SCNNode()
        for child in shipScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        modelNode.addChildNode(wrapperNode)
        sceneView.scene.rootNode.addChildNode(modelNode)
        messageBox.text = "Step 1. Drop to the floor."
    }
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DuringViewController.addTableToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func pinchRecognized(pinch: UIPinchGestureRecognizer) {
        modelNode.runAction(SCNAction.scale(by: pinch.scale, duration: 0.01))
    }
    
    @objc func panRecognized(pan: UIPanGestureRecognizer) {
        
        let xPan = pan.velocity(in: sceneView).x/1000
        /*
         y pan is a not tuned for user expereience
         let yPan = pan.velocity(in: sceneView).y/10000
         */
        
        modelNode.runAction(SCNAction.rotateBy(x: 0, y: xPan, z: 0, duration: 0.01))
    }
    
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

