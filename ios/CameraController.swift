//
//  CameraController.swift
//  ScoutApp
//
//  Created by Leo Chernyak on 06.11.2021.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import AudioToolbox
import CoreVideo
import VideoToolbox
import Photos


enum ChallangeType: NSNumber {
  case dribbling = 0
  case juggling = 1
}

enum ChallangeStatus {
  case humanAndBallDetection
  case challangeIsGoing
  case challangeIsFinished
}

enum CameraControllerError: Swift.Error {
  case captureSessionAlreadyRunning
  case captureSessionIsMissing
  case inputsAreInvalid
  case invalidOperation
  case noCamerasAvailable
  case unknown
}

@objc(CameraController)
final class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,CAAnimationDelegate {
  
  //Setting up Camera
  var isCameraNil = false;
  var challangeType: ChallangeType! = .dribbling;
  var captureSession: AVCaptureSession?
  var previewLayer: AVCaptureVideoPreviewLayer?
  var bufferSize: CGSize = .zero
  private var videoDataOutput = AVCaptureVideoDataOutput()
  private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
  private var frameCounter: Int = 0
  
  
  //Vision Parts
  private let requestHandler = VNSequenceRequestHandler()
  private var requests = [VNRequest]()
  private var trackingRequests = [VNTrackObjectRequest]()
  private var objectBounds: CGRect = CGRect()
  var inputObservation: VNDetectedObjectObservation?
  
  var detectionOverlay: CALayer?
  var touchOverlay: CALayer?
  
  
  
  //HumanDetection
  var humanArray: [Joint] = []
  private var poseNet: PoseNet?
  private var currentFrame: CGImage?
  /// The algorithm the controller uses to extract poses from the current frame.
  private var algorithm: Algorithm = .single
  /// The set of parameters passed to the pose builder when detecting poses.
  private lazy var poseBuilderConfiguration = PoseBuilderConfiguration()
  
  
  
  //Game Values
  var humanIsDetected: Bool = false
  var isHanding: Bool = false
  var challangeCondition: ChallangeStatus = .humanAndBallDetection
  
  
  //Dribbling values
  private var changeValue: CGFloat = 400
  var touches: Int = 0
  private var counterForBallStoping: Int = 0
  private var pointLevelFirst: CGFloat?
  private var touchPointLayer: CAShapeLayer = CAShapeLayer()
  private var touchPointDownloadingLayer: CAShapeLayer = CAShapeLayer()
  private var shouldChangeTouchPointPosition: Bool = false
  private var trackLayer: CAShapeLayer = CAShapeLayer()
  private var basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
  private var touchPointCoordinate: CGFloat = 400.0
  var firstSetup: Bool = true
  
  
  //Juggling values
  private var ballUpLine: Bool = false
  private var ballXcoordinate: CGFloat = 0
  private var counterForJugglingUp: Int = 0
  private var groundLevelCoordinate: CGFloat = 0
  private var stepCoordinate: CGFloat = 0
  private var shoulderCoordinate: CGFloat = 0
  private var jugglingLineCoordinate: CGFloat = 0
  var ballXArrayValues: [CGFloat] = []
  var juggleBool: Bool = false
  private var jugglingLineLayer: CAShapeLayer = CAShapeLayer()
  
  
  //Conditions for start game
  private var humanDetectionArea: CALayer?
  private var frame: CGRect?
  private var rangeX: ClosedRange<CGFloat>?
  private var rangeY: ClosedRange<CGFloat>?
  private var ballLayer: CALayer = CALayer()
  private var audioPlayer: AVAudioPlayer?
  
  
  
  private var trackingIsOn: Bool = false
  private var lastObservation: VNDetectedObjectObservation?
  
  
  
  
  
  
  //MARK: Play Score Sound
  private func playScoreSound() {
    guard let url = Bundle.main.url(forResource: "touch_kol_1", withExtension: "mp3") else {
      print("error to get the mp3 file")
      return
    }
    
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: url)
    } catch {
      print("audio file error")
    }
    audioPlayer?.play()
  }
  
  //MARK: Check is Human in Detection Area
  private func checkJointsWithFrame(joints:[Joint]) -> Bool {
    guard let humanDetectionArea = humanDetectionArea,
          let frame = previewLayer?.convert(humanDetectionArea.frame, to: detectionOverlay) else { return false }
    
    var positions: [CGPoint] = []
    for joint in joints {
      positions.append(joint.position)
    }
    let result = positions.allSatisfy({frame.contains($0) })
    return result
  }
  
  //MARK: Check Animation Status
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    //        print("End Animation \(flag)")
    DispatchQueue(label: "animationStatus").async {
      self.shouldChangeTouchPointPosition = flag
    }
  }
  
  //MARK: Orientation exit field
  public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
    let exifOrientation: CGImagePropertyOrientation
    exifOrientation = .leftMirrored
    return exifOrientation
  }
  
  func handle() {
    print("Handling")
  }
  
  
  //MARK: AV Delegate Methods and Buffer wrapper
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    frameCounter += 1
    if (frameCounter % 2 == 0) //every 15 frames
    {
      defer {
        frameCounter = 0
      }
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return
      }
      
      //MARK: Human Detection
      var image: CGImage?
      VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
      CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
      currentFrame = image
      DispatchQueue(label: "poseNet").async {
        guard let image = image else { return }
        self.poseNet?.predict(image)
      }
      
      //MARK: Ball Detection and Tracking
      do {
        if !trackingIsOn {
          //MARK: Ball Detection
          print("Object Detectiom")
          try self.requestHandler.perform(self.requests, on: pixelBuffer, orientation: .leftMirrored)
        } else {
          //MARK: Ball Tracking
          let request = VNTrackObjectRequest(detectedObjectObservation:
                                              lastObservation!) { [unowned self] request, error in
            print("Strange Handler 2 \(request.results?.count ?? 0)")
            self.handle()
            DispatchQueue.main.async {
              if request.results != nil {
                self.requests = [request]
              } else {
                trackingIsOn = false
              }
            }
          }
          request.trackingLevel = .fast
          do {
            print("Object Tracking")
            try self.requestHandler.perform(self.requests, on: pixelBuffer, orientation: .leftMirrored)
          }
          catch {
            trackingIsOn = false
            print(error)
          }
        }
      } catch {
        print("Tracking failed of track.")
      }
    }
  }
  
  func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {}
  
  //MARK: Main Function with camera and vision setup
  func prepare(completionHandler: @escaping (Error?) -> Void){
    //MARK: Vision Detection setup
    @discardableResult
    func setupVision() -> NSError? {
      // Setup Vision parts
      let error: NSError! = nil
      guard let modelURL = Bundle.main.url(forResource: "SoccerBall3.0", withExtension: "mlmodelc") else {
        return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
      }
      do {
        let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        print("Vision started working")
        let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
          DispatchQueue.main.async(execute: {
            // perform all the UI updates on the main queue
            if let results = request.results {
              drawVisionRequestResults(results)
            }
          })
        })
        objectRecognition.imageCropAndScaleOption = .scaleFill
        if let overlay = detectionOverlay {
          objectRecognition.regionOfInterest = overlay.frame
        }
        
        requests = [objectRecognition]
      } catch let error as NSError {
        print("Model loading went wrong: \(error)")
      }
      
      return error
    }
    
    
    //MARK: Draw Tracking Results
    
    
    //MARK: Draw Vision Results
    func drawVisionRequestResults(_ results: [Any]) {
      defer {
        detectionOverlay?.sublayers = nil
        humanArray = [Joint]()
      }
      
      if shouldChangeTouchPointPosition {
        changeTouchPointPos()
        shouldChangeTouchPointPosition = false
      }
      
      for observation in results where observation is VNRecognizedObjectObservation {
        guard let objectObservation = observation as? VNRecognizedObjectObservation else {
          print("Stop tracking")
          trackingIsOn = false
          continue
        }
        
        lastObservation = objectObservation
        trackingIsOn = true
        
        
        // Select only the label with the highest confidence.
        let topLabelObservation = objectObservation.labels[0]
        objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
        
        
        ballLayer = createBallLayer(objectBounds, color: .green)
        ballLayer.backgroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
        detectionOverlay?.addSublayer(ballLayer)
        //Draw ball on detection overlay
        //                if topLabelObservation.identifier == "ball"
        //                //                    && objectBounds.width < 250
        //                {
        //                    ballLayer = createBallLayer(objectBounds, color: .green)
        //                    ballLayer.backgroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
        //                    detectionOverlay.addSublayer(ballLayer)
        //
        //                }
        
        
        
        if firstSetup {
          frame = previewLayer?.convert(humanDetectionArea?.frame ?? .zero, to: detectionOverlay)
          rangeX = (frame?.minX ?? .zero) ... (frame?.maxX ?? .zero)
          rangeY = (frame?.minY ?? .zero) ... (frame?.maxY ?? .zero)
          if topLabelObservation.identifier == "ball" && (rangeX?.contains(objectBounds.midX) ?? false) && (rangeY?.contains(objectBounds.midY) ?? false) && objectBounds.width < 250 && humanIsDetected {
            switch challangeType {
            case .dribbling:
              guard let touchOverlay = touchOverlay else { return }
              touchPointLayer = createTouchPointRectLayerWithBounds(CGRect(x: touchOverlay.bounds.maxX - touchOverlay.frame.width * 0.370, y: 200 , width: touchOverlay.frame.width * 0.224, height: touchOverlay.frame.width * 0.224))
              pointLevelFirst = touchOverlay.bounds.maxX - touchOverlay.frame.width * 0.370
              touchPointLayer.cornerRadius = touchOverlay.frame.width * 0.224/2
              touchOverlay.addSublayer(touchPointLayer)
              challangeCondition = .challangeIsGoing
              firstSetup = false
            case .juggling:
              if stepCoordinate != 0 {
                let groundLayer = createJugglingLine(CGRect(x: stepCoordinate, y: 0, width: 20, height: 1920))
                jugglingLineLayer = createJugglingLine(CGRect(x: jugglingLineCoordinate, y: 0, width: 20, height: 1920))
                //                                touchOverlay!.addSublayer(groundLayer)
                //Uncomment line for adding juggling line
                //                                touchOverlay!.addSublayer(groundLayer)
                groundLevelCoordinate = stepCoordinate
                challangeCondition = .challangeIsGoing
                firstSetup = false
              }
              
              
              print("Juggling first setup")
            case .none:
              print("Challange Type was not determine")
            }
            
            
            
          }
        } else {
          switch challangeType {
          case .dribbling:
            let rangeXTouchPoint = touchPointLayer.frame.minX ... touchPointLayer.frame.maxX
            let rangeYTouchPoint = touchPointLayer.frame.minY ... touchPointLayer.frame.maxY
            
            if (rangeXTouchPoint.contains(objectBounds.minX) || rangeXTouchPoint.contains(objectBounds.midX) || rangeXTouchPoint.contains(objectBounds.maxX)) && (rangeYTouchPoint.contains(objectBounds.minY) || rangeYTouchPoint.contains(objectBounds.midY) || rangeYTouchPoint.contains(objectBounds.maxY)) {
              counterForBallStoping += 1
              if counterForBallStoping == 2 {
                playScoreSound()
                touches += 1
                counterForBallStoping = 0
                changeTouchPointPos()
              }
            }
          case .juggling:
            
            //                            if !juggleBool {
            //                                //MARK: Juggling Mode
            //                                if (objectBounds.minX < jugglingLineLayer.frame.maxX) && objectBounds.minX > shoulderCoordinate  {
            //                                    juggleBool = true
            //                                    touches += 1
            //                                }
            //                            } else if (objectBounds.minX > jugglingLineLayer.frame.maxX) && objectBounds.minX > shoulderCoordinate  {
            //                                juggleBool = false
            //                            }
            //
            
            //MARK: Juggling Algorithm with line
            if objectBounds.maxX < groundLevelCoordinate {
              ballXArrayValues.append(objectBounds.midX)
              
              let numberOfTouches = countJuggilngTouches()
              if touches != numberOfTouches {
                touches = numberOfTouches
                playScoreSound()
              }
              
            }
            //MARK: Juggling Algorithm with line
            
          case .none:
            print("Challange type was not determine")
          }
          
        }
        
        updateLayerGeometry()
        CATransaction.commit()
      }
    }
    
    
    func countJuggilngTouches() -> Int {
      var numberOfTouches = 0
      print(numberOfTouches)
      var movingUp = true
      var ballCenterValue: CGFloat = 0.0
      
      for (index, ballCenter) in ballXArrayValues.enumerated() {
        if index != 0 {
          if index == 1 {
            if ballCenter < ballXArrayValues[0] {
              movingUp = true
            } else {
              movingUp = false
            }
            ballCenterValue = ballCenter
          } else {
            if ballCenter + 20 < ballCenterValue {
              if movingUp == false {
                numberOfTouches += 1
              }
              movingUp = true
              ballCenterValue = ballCenter
            } else if ballCenter > ballCenterValue + 20 {
              if movingUp == true {
                //                                numberOfTouches += 1
              }
              movingUp = false
              ballCenterValue = ballCenter
            }
          }
        }
      }
      
      return numberOfTouches
    }
    
    //MARK: Create Juggling Line
    func createJugglingLine(_ bounds: CGRect) -> CAShapeLayer {
      let shapeLayer = CAShapeLayer()
      shapeLayer.bounds = bounds
      shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
      shapeLayer.name = "JugglingLine"
      shapeLayer.backgroundColor = UIColor.clear.cgColor
      shapeLayer.cornerRadius = 10
      shapeLayer.strokeColor = UIColor(red: 1, green: 0.908, blue: 0.079, alpha: 1).cgColor
      shapeLayer.lineDashPattern = [70, 32]
      shapeLayer.lineWidth = 20
      let path = CGMutablePath()
      path.addLines(between: [CGPoint(x: bounds.minX, y: bounds.minY), CGPoint(x: bounds.maxX - bounds.width, y: bounds.maxY)])
      shapeLayer.path = path
      return shapeLayer
    }
    
    
    //MARK: Check Hands On a Ball
    func checkHandsTouchBall(joint: Joint, objectBounds: CGRect) -> Bool {
      var isHanding: Bool = false
      let rectOfHand = CGRect(x: joint.position.x, y: joint.position.y, width: 50, height: 50)
      if objectBounds.midY >= rectOfHand.minY - 20 && objectBounds.midY <= rectOfHand.maxY + 20 && objectBounds.midX >= rectOfHand.minX - 20 &&
          objectBounds.midX <= rectOfHand.maxX + 20 {
        isHanding = true
      } else {
        isHanding = false
      }
      return isHanding
    }
    
    //MARK: Function change touch point position randomly
    func changeTouchPointPos() {
      touchPointLayer.removeAllAnimations()
      
      //Desicion two
      let levelOne = [100,300,500,700,900,1100,1300,1500,1700,1800]
      let levelTwo = [250,450,650,850,1050,1250,1450,1650]
      let level: [Int]! = levelTwo
      
      
      var random = CGFloat(level.randomElement()!)
      while random == touchPointCoordinate - 200 || random == touchPointCoordinate + 200 || random == touchPointCoordinate {
        random = CGFloat(level.randomElement()!)
      }
      touchPointCoordinate = random
      touchPointLayer.position.y = touchPointCoordinate
      touchPointDownloadingLayer.add(basicAnimation, forKey: "urSoBasic")
    }
    
    
    //MARK: Update layers on Detection Overlay
    func updateLayerGeometry() {
      guard let bounds = previewLayer?.bounds else { return }
      
      var scale: CGFloat
      let xScale: CGFloat = bounds.size.width / self.bufferSize.height
      let yScale: CGFloat = bounds.size.height / self.bufferSize.width
      scale = fmax(xScale, yScale)
      if scale.isInfinite {
        scale = 1.0
      }
      
      CATransaction.begin()
      CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
      detectionOverlay?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
      detectionOverlay?.position = CGPoint(x: bounds.midX, y: bounds.midY)
      touchOverlay?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
      touchOverlay?.position = CGPoint(x: bounds.midX, y: bounds.midY)
      CATransaction.commit()
    }
    
    //MARK: Draw Ball Layer
    func createBallLayer(_ bounds: CGRect, color: UIColor) -> CALayer {
      if bounds.size.width > bounds.size.height {
        let radius: CGFloat = bounds.size.width / 2
        let increment = bounds.size.width / 2 - bounds.size.height / 2
        let path = UIBezierPath(roundedRect: CGRect(x: bounds.origin.x - 5, y: bounds.origin.y - 5 - increment, width: radius * 2 + 10, height: radius * 2 + 10), cornerRadius: radius + 5)
        let circlePath = UIBezierPath(roundedRect: CGRect(x: bounds.origin.x + 5, y: bounds.origin.y - increment + 5, width: radius * 2 - 10, height: radius * 2 - 10), cornerRadius: radius - 5)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = color.cgColor
        fillLayer.opacity = 0.5
        return fillLayer
      } else {
        let radius: CGFloat = bounds.size.height / 2
        
        let increment = bounds.size.height / 2 - bounds.size.width / 2
        
        let path = UIBezierPath(roundedRect: CGRect(x: bounds.origin.x - 5 - increment, y: bounds.origin.y - 5, width: radius * 2 + 10, height: radius * 2 + 10), cornerRadius: radius + 5)
        let circlePath = UIBezierPath(roundedRect: CGRect(x: bounds.origin.x + 5 - increment, y: bounds.origin.y + 5, width: radius * 2 - 10, height: radius * 2 - 10), cornerRadius: radius - 5)
        path.append(circlePath)
        path.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = color.cgColor
        fillLayer.opacity = 0.5
        return fillLayer
      }
    }
    
    
    //MARK: Draw TouchPoint into the screen
    func createTouchPointRectLayerWithBounds(_ bounds: CGRect) -> CAShapeLayer {
      let shapeLayer = CAShapeLayer()
      shapeLayer.bounds = bounds
      shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
      //            shapeLayer.position = CGPoint(x: bounds.minX, y: bounds.midY)
      shapeLayer.name = "TouchPoint"
      shapeLayer.backgroundColor = UIColor(red: 1, green: 0.908, blue: 0.079, alpha: 1).cgColor
      shapeLayer.cornerRadius = 7
      let center = CGPoint(x: bounds.midX, y: bounds.midY)
      let circularPath = UIBezierPath(arcCenter: center, radius: bounds.width/2, startAngle: CGFloat.pi, endAngle: -CGFloat.pi, clockwise: false)
      trackLayer.path = circularPath.cgPath
      trackLayer.strokeColor = UIColor(red: 0.114, green: 0.412, blue: 0.322, alpha: 1).cgColor
      trackLayer.lineWidth = 25
      trackLayer.fillColor = UIColor.clear.cgColor
      trackLayer.lineCap = CAShapeLayerLineCap.round
      touchPointDownloadingLayer.path = circularPath.cgPath
      touchPointDownloadingLayer.strokeColor =  UIColor.white.cgColor
      touchPointDownloadingLayer.lineWidth = 25
      touchPointDownloadingLayer.fillColor = UIColor(red: 1, green: 0.908, blue: 0.079, alpha: 1).cgColor
      touchPointDownloadingLayer.lineCap = CAShapeLayerLineCap.round
      touchPointDownloadingLayer.strokeEnd = 0
      
      trackLayer.addSublayer(touchPointDownloadingLayer)
      shapeLayer.addSublayer(trackLayer)
      
      basicAnimation.toValue = 1
      basicAnimation.duration = 4
      basicAnimation.fillMode = .forwards
      basicAnimation.isRemovedOnCompletion = false
      basicAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
      basicAnimation.delegate = self
      return shapeLayer
    }
    
    //MARK: Setup camera session
    func setupCameraSession() throws {
      self.captureSession = AVCaptureSession()
      var deviceInput: AVCaptureDeviceInput!
      // Select a video device, make an input
      let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
      
      
      if(videoDevice == nil){
        isCameraNil = true;
        
        DispatchQueue.main.async {
          let alert = UIAlertView()
          alert.title = "Ошибка"
          alert.message = "Камера на вашем устройстве не доступна"
          alert.addButton(withTitle: "Ок")
          alert.show()
        }
        return;
      }
      
      do {
        deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
      } catch {
        throw CameraControllerError.inputsAreInvalid
      }
      
      captureSession?.beginConfiguration()
      let deviceType = UIDevice().name
      let devicesArray = ["iPhone 11","iPhone 11 Pro","iPhone 11 Pro Max","iPhone SE 2nd gen", "iPhone 12 Mini", "iPhone 12","iPhone 12 Pro", "iPhone 12 Mini","iPhone 12","iPhone 12 Pro", "iPhone 12 Pro Max", "iPhone 7 Plus", "iPhone XS"]
      if devicesArray.contains(deviceType) {
        //            session.sessionPreset = .hd4K3840x2160
        captureSession?.sessionPreset = .hd1920x1080
      } else {
        captureSession?.sessionPreset = .hd1920x1080
      }
      // Add a video input
      guard captureSession?.canAddInput(deviceInput) ?? false else {
        //                throw CameraControllerError.invalidOperation
        captureSession?.commitConfiguration()
        return
      }
      captureSession?.addInput(deviceInput)
      if captureSession?.canAddOutput(videoDataOutput) ?? false {
        captureSession?.addOutput(videoDataOutput)
        // Add a video data output
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
      } else {
        //                throw CameraControllerError.invalidOperation
        captureSession?.commitConfiguration()
        return
      }
      
      let captureConnection = videoDataOutput.connection(with: .video)
      // Always process the frames
      captureConnection?.isEnabled = true
      do {
        try  videoDevice!.lockForConfiguration()
        let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
        bufferSize.width = CGFloat(dimensions.height)
        bufferSize.height = CGFloat(dimensions.width)
        videoDevice!.unlockForConfiguration()
      } catch {
        throw CameraControllerError.invalidOperation
      }
      captureSession?.commitConfiguration()
    }
    
    //MARK: Start capture session function
    func startCaptureSession() {
      captureSession?.startRunning()
    }
    
    //MARK: Running Queue
    DispatchQueue(label: "prepare").async { [weak self] in
      do {
        do {
          self?.poseNet = try PoseNet()
        } catch {
          fatalError("Failed to load model. \(error.localizedDescription)")
        }
        self?.poseNet?.delegate = self
        try setupCameraSession()
        setupVision()
        startCaptureSession()
      }
      
      catch {
        DispatchQueue.main.async{
          completionHandler(error)
        }
        
        return
      }
      DispatchQueue.main.async {
        completionHandler(nil)
      }
    }
    
  }
  
  //MARK: Adding layers and Display them on the screen
  func displayPreview(on view: UIView) throws {
    guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
    
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    previewLayer.connection?.videoOrientation = .landscapeLeft
    
    
    let humanDetectionArea = CALayer() //human and ball detection area layer
    humanDetectionArea.name = "HumanDetectionOverlay"
    humanDetectionArea.bounds = CGRect(x: 0.0, y: 0.0, width:UIScreen.screens.first!.bounds.width * 0.296 , height:  UIScreen.screens.first!.bounds.height  * 0.964)
    humanDetectionArea.position = CGPoint(x: UIScreen.screens.first!.bounds.width / 2, y: UIScreen.screens.first!.bounds.height / 2)
    previewLayer.addSublayer(humanDetectionArea)
    self.humanDetectionArea = humanDetectionArea
    
    let detectionOverlay = CALayer() // container layer that has all the renderings of the observations
    detectionOverlay.name = "DetectionOverlay"
    detectionOverlay.bounds = CGRect(x: 0.0,
                                     y: 0.0,
                                     width: bufferSize.width,
                                     height: bufferSize.height)
    
    detectionOverlay.position = previewLayer.position
    previewLayer.addSublayer(detectionOverlay)
    self.detectionOverlay = detectionOverlay
    
    let touchOverlay = CALayer() // container layer that has all the touchpoints
    touchOverlay.name = "TouchOverlay"
    touchOverlay.bounds = CGRect(x: 0.0,
                                 y: 0.0,
                                 width: bufferSize.width,
                                 height: bufferSize.height)
    touchOverlay.position = previewLayer.position
    previewLayer.addSublayer(touchOverlay)
    self.touchOverlay = touchOverlay
    
    view.layer.insertSublayer(previewLayer, at: 0)
    previewLayer.frame = view.frame
    self.previewLayer = previewLayer
  }
  
}



extension CameraController: PoseNetDelegate {
  
  func createHumanPoint(_ bounds: CGRect) -> CALayer {
    let shapeLayer = CALayer()
    shapeLayer.bounds = bounds
    shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    shapeLayer.name = "HumanPoint"
    shapeLayer.backgroundColor = UIColor(red: 1, green: 0.908, blue: 0.079, alpha: 1).cgColor
    shapeLayer.cornerRadius = 7
    return shapeLayer
  }
  
  //MARK: Human Body Recognition
  func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
    defer {
      currentFrame = nil
    }
    guard let currentFrame = currentFrame else {
      return
    }
    
    lazy var poseBuilder = PoseBuilder(output: predictions,configuration: poseBuilderConfiguration, inputImage: currentFrame)
    //        let poses = [poseBuilder.pose]
    lazy var arrayOfJoints:[Joint] = []
    
    
    for i in [poseBuilder.pose] {
      let array = i.joints
      for j in array {
        lazy var position = CGPoint(x: j.value.position.y, y:  0.0 + (bufferSize.height - j.value.position.x))
        //MARK: Check confiedence of the joints for reduce duplicate points
        if j.value.confidence > 0.5 {
          lazy var joint = Joint(name: j.value.name, cell: j.value.cell, position: position, confidence: j.value.confidence, isValid: true)
          if joint.name == .leftAnkle ||  joint.name == .rightAnkle{
            stepCoordinate = joint.position.x
          }
          
          if joint.name == .rightShoulder || joint.name == .leftShoulder {
            shoulderCoordinate = joint.position.x
          }
          
          if joint.name == .rightKnee ||  joint.name == .leftKnee{
            jugglingLineCoordinate = joint.position.x
            jugglingLineLayer.position.x = jugglingLineCoordinate
          }
          
          //                    let humanPoint = createHumanPoint(CGRect(x: joint.position.x, y:joint.position.y, width: 20, height: 20))
          //                    humanPoint.cornerRadius = 10
          //                    // Uncomment to see drawing human points
          //                    detectionOverlay.addSublayer(humanPoint)
          
          if !humanIsDetected {
            arrayOfJoints.append(joint)
          }
        }
      }
    }
    humanArray = arrayOfJoints
    if humanArray.count > 6 && !humanIsDetected {
      print("Human is detected")
      humanIsDetected = true
    }
  }
  
}



extension Array where Element: BinaryFloatingPoint {
  
  /// The average value of all the items in the array
  var average: Double {
    if self.isEmpty {
      return 0.0
    } else {
      let sum = self.reduce(0, +)
      return Double(sum) / Double(self.count)
    }
  }
  
}


