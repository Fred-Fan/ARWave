//
//  ViewController.swift
//  ARWave
//
//  Created by Leon Lee on 2/22/18.
//  Copyright © 2018 Leon Lee. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    // SCENE
    var placed = Set<String>()

    @IBOutlet weak var beforeSecureText: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    let bubbleDepth : Float = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction
    let modelNode = SCNNode()
    var latestProbability : Float = 0.0
    @IBOutlet weak var targetButton: UIButton!
    @IBOutlet weak var messageBox: UILabel!
    @IBOutlet weak var checkMarkImage: UIImageView!
    var isDetecting = true
    var finishScanning = false
    var x : CGFloat = 0.0
    var y : CGFloat = 0.0
    var z : CGFloat = 0.0
    var modelCount: Int = 0
    var finishPlacing = false
    var rightAnswer: Int = 0
    var currentTap = ""
    let allModels : Set = ["TV", "paintingframe", "bookshelf"]
    
    var quiz = [ "bookcase": [["A: Use furniture straps", "B: Use heavy books", "C: No need."], ["explanation 1", "explanation 2", "explanation 3"]],
                 "TV": [["A: Use TV straps", "B: Use putty", "C: No need."], ["explanation 1", "explanation 2", "explanation 3"]],
                 "paintingframe": [["A: Use closed hook to secure wall.", "B: Just standard hooks", "C: Use putty"], ["explanation 1", "explanation 2", "explanation 3"]]
                ]
    var count = ["bookcase": false,
                 "TV": false,
                 "paintingframe": false]
    
    
    // COREML
    var visionRequests = [VNRequest]()
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.layer.cornerRadius = 6
        beforeSecureText.isHidden = true
        playButton.isHidden = true
        targetButton.isHidden = true
        messageBox.text = "Scan floor at chest level to record height"
        // Set the view's delegate
        sceneView.delegate = self
        checkMarkImage.isHidden = true
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable Default Lighting - makes the 3D text a bit poppier.
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Add tap guesture
        
        // Set up Vision Model
        guard let selectedModel = try? VNCoreMLModel(for: my_model_bear().model) else { // (Optional) This can be replaced with other models on https://developer.apple.com/machine-learning/
            fatalError("Could not load model. Ensure model has been dragle and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        // Set up Vision-CoreML Request
        let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
        visionRequests = [classificationRequest]
        
        // Begin Loop to Update CoreML
        loopCoreMLUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Enable plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func handleTap(rec: UITapGestureRecognizer){
        
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                guard let tappedNode = hits.first?.node else {return}
                if tappedNode.name == nil {
                    return
                }
                self.currentTap = tappedNode.name!
                self.displayQuiz()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if self.isDetecting {
            guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
            self.x =  CGFloat(planeAnchor.transform.columns.3.x)
            self.y =  CGFloat(planeAnchor.transform.columns.3.y)
            self.z =  CGFloat(planeAnchor.transform.columns.3.z)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.messageBox.text = "Height recorded"
                self.checkMarkImage.isHidden = false
            }
            
            // Wait for 3 seconds to start scanning room
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.checkMarkImage.isHidden = true
                self.messageBox.text = "Scan room at eye level"
                self.targetButton.isHidden = false
            }
            self.finishScanning = true
            self.isDetecting = false
        }
    }
    
    
    func placeVirtualObject() {
        if !self.finishPlacing && self.finishScanning && self.latestProbability >= 0.92 && !self.placed.contains(self.latestPrediction) && self.allModels.contains(self.latestPrediction){
            // add node to scnView
            modelNode.position = SCNVector3Make(Float(self.x), Float(self.y), Float(self.z))
            guard let shipScene = SCNScene(named: "art.scnassets/" + self.latestPrediction + ".dae")
                else { return }
            let wrapperNode = SCNNode()
            for child in shipScene.rootNode.childNodes {
                child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                wrapperNode.addChildNode(child)
            }
            modelNode.addChildNode(wrapperNode)
            sceneView.scene.rootNode.addChildNode(modelNode)
            self.modelCount += 1
            // Add placed objects to set
            self.placed.insert(self.latestPrediction)
        }
        
        if self.modelCount == 3 && !self.finishPlacing {
            self.finishPlacing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.targetButton.isHidden = true
                self.messageBox.text = "Models created"
                self.checkMarkImage.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.messageBox.text = "We identified big objects that need to be secured."
                self.checkMarkImage.isHidden = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.messageBox.isHidden = true
                self.checkMarkImage.isHidden = true
                self.beforeSecureText.isHidden = false
                self.playButton.isHidden = false
            }
        }
    }
    
    
    @IBAction func playAction(_ sender: UIButton) {
        self.beforeSecureText.isHidden = true
        self.playButton.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
    }
    
    func readyToSergue() {
        if self.count["bookcase"]! && self.count["TV"]! && self.count["paintingframe"]! {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "beforedone") as UIViewController
                self.present(nextViewController, animated:true, completion:nil)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.messageBox.text = "Continue. Tap other furnitures to secure!"
                self.messageBox.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                self.messageBox.isHidden = true
            }
        }
    }
    
    func displayQuiz() {
        var furniture = self.currentTap
        if self.currentTap == "Screen" || self.currentTap == "Speakers" || self.currentTap == "LCD" || self.currentTap == "Stand" {
            furniture = "TV"
        } else if self.currentTap == "bookshelf" || self.currentTap == "bookcase"{
            furniture = "bookcase"
        }
        let alertController = UIAlertController(title: "How do you secure " + furniture + " ?",
                                                message: "",
                                                preferredStyle: .alert)
        let action1 = UIAlertAction(title: self.quiz[furniture]![0][0], style: .default, handler:{ (action) -> Void in
            let messageController = UIAlertController(title: "Congratulations!",
                                                      message: "You make the right choice. " + self.quiz[furniture]![1][0],
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            messageController.addAction(okAction)
            self.count[furniture] = true
            self.present(messageController, animated: true, completion: self.readyToSergue)
        })
        let action2 = UIAlertAction(title: self.quiz[furniture]![0][1], style: .default, handler:{ (action) -> Void in
            let messageController = UIAlertController(title: "Try again!",
                                                      message: self.quiz[furniture]![1][1],
                                                      preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            messageController.addAction(okAction)
            self.present(messageController, animated: true, completion: self.displayQuiz)
        })
        let action3 = UIAlertAction(title: self.quiz[furniture]![0][2], style: .default, handler:{ (action) -> Void in
            let messageController = UIAlertController(title: "Try again!",
                                                      message: self.quiz[furniture]![1][2],
                                                      preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            messageController.addAction(okAction)
            self.present(messageController, animated: true, completion: self.displayQuiz)
        })
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        self.present(alertController, animated: true)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // Do any desired updates to SceneKit here.
        }
    }
    
    // MARK: - Status Bar: Hide
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Interaction
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create 3D Text
            let node : SCNNode = createNewBubbleParentNode(latestPrediction)
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
        }
    }
    
    func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        bubble.alignmentMode = kCAAlignmentCenter
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - CoreML Vision Handling
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        dispatchQueueML.async {
            // 1. Run Update.
            self.updateCoreML()
            // 2. Loop this function.
            self.loopCoreMLUpdate()
        }
        
    }
    
    func classificationCompleteHandler(request: VNRequest, error: Error?) {
        // Catch Errors
        if error != nil {
            print("Error: " + (error?.localizedDescription)!)
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        // Get Classifications
        let classifications = observations[0...1] // top 2 results
            .flatMap({ $0 as? VNClassificationObservation })
            .map({ "\($0.identifier) \(String(format:"- %.2f", $0.confidence))" })
            .joined(separator: "\n")
        
        
        DispatchQueue.main.async {
            // Print Classifications
            
            // Store the latest prediction
            var objectName:String = "…"
            objectName = classifications.components(separatedBy: "-")[0]
            objectName = objectName.components(separatedBy: ",")[0]
            self.latestPrediction = objectName.trimmingCharacters(in: .whitespacesAndNewlines)
            self.latestProbability = (classifications.components(separatedBy: "-")[1] as NSString).floatValue
            self.placeVirtualObject()
        }
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        if pixbuff == nil { return }
        let ciImage = CIImage(cvPixelBuffer: pixbuff!)
        // Note: Not entirely sure if the ciImage is being interpreted as RGB, but for now it works with the Inception model.
        // Note2: Also uncertain if the pixelBuffer should be rotated before handing off to Vision (VNImageRequestHandler) - regardless, for now, it still works well with the Inception model.
        
        ///////////////////////////
        // Prepare CoreML/Vision Request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        // let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage!, orientation: myOrientation, options: [:]) // Alternatively; we can convert the above to an RGB CGImage and use that. Also UIInterfaceOrientation can inform orientation values.
        
        ///////////////////////////
        // Run Image Request
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
        
    }
    
}

extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

