//
//  FaceViewController.swift
//  faceDetectionDemo2
//
//  Created by 雪 禹 on 6/21/16.
//  Copyright © 2016 XueYu. All rights reserved.
//

import UIKit
import AVFoundation

class FaceViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {
    
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var faceRectCALayer: CALayer!
    
    fileprivate var currentCameraFace: AVCaptureDevice?
    fileprivate var sessionQueue: DispatchQueue = DispatchQueue(label: "videoQueue", attributes: [])
    
    fileprivate var session: AVCaptureSession!
    fileprivate var backCameraDevice: AVCaptureDevice?
    fileprivate var frontCameraDevice: AVCaptureDevice?
    fileprivate var metadataOutput: AVCaptureMetadataOutput!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(FaceViewController.pinch))
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        setupSession()
        setupPreview()
        setupFace()
        startSession()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark: - Setup pinch gesture recognizer
    
    func pinch(gestureRecognizer: UIPinchGestureRecognizer) {
        print("pinch")
        if gestureRecognizer.state == UIGestureRecognizerState.began || gestureRecognizer.state == UIGestureRecognizerState.changed {
            self.view.transform = self.view.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
            gestureRecognizer.scale = 1
        }
    }
    
    // MARK: - Setup session and preview
    
    func setupSession(){
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        let avaliableCameraDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        for device in avaliableCameraDevices as! [AVCaptureDevice]{
            if device.position == .back {
                backCameraDevice = device
            } else if device.position == .front{
                frontCameraDevice = device
            }
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCameraDevice)
            if session.canAddInput(input){
                session.addInput(input)
            }
        } catch {
            print("Error handling the camera Input: \(error)")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        }
        

    }
    
    
    func setupPreview(){
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.affineTransform()
        
//        previewLayer.zPosition = 1
        view.layer.addSublayer(previewLayer)
        
    }
    
    
    func startSession() {
        if !session.isRunning{
            session.startRunning()
        }
    }
    
    func setupFace(){
        faceRectCALayer = CALayer()
        faceRectCALayer.zPosition = 1
        faceRectCALayer.borderColor = UIColor.red.cgColor
        faceRectCALayer.borderWidth = 3.0
        print("previewLayer.sublayers:%@",previewLayer.sublayers!)
//        previewLayer.addSublayer(faceRectCALayer)
    }
    
    func mySetupFace(_ faces : Array<CGRect>) {
//        previewLayer.sublayers = nil
//        previewLayer.sublayers?.forEach {
//            $0.removeFromSuperlayer()
//        }
//        print("\n")
//        print(previewLayer.sublayers?.count)
        for (idx, e) in (previewLayer.sublayers?.enumerated())! {
            if (idx > 0) {
                e.removeFromSuperlayer();
            }
        }
        
//        print("2 previewLayer.sublayers:%@",previewLayer.sublayers!)
        for face in faces {
            let faceRect = CALayer()
            faceRect.zPosition = 1
            faceRect.borderColor = UIColor.red.cgColor
            faceRect.borderWidth = 3.0
            faceRect.frame = face
//            faceRect.backgroundColor = UIColor(white: 1, alpha: 0.5).cgColor
            previewLayer.addSublayer(faceRect)
        }
        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        var faces = [CGRect]()
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if metadataObject.type == AVMetadataObjectTypeFace {
                    let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                    let face = transformedMetadataObject?.bounds
                    faces.append(face!)
            }
        }
        
        print("FACE",faces)
        
        if faces.count > 0 {
//            setlayerHidden(false)
            DispatchQueue.main.async(execute: {
                () -> Void in
                self.mySetupFace(faces)
//                self.faceRectCALayer.frame = self.findMaxFaceRect(faces)
            })
        } else {
            DispatchQueue.main.async(execute: {
                () -> Void in
                for (idx, e) in (self.previewLayer.sublayers?.enumerated())! {
                    if (idx > 0) {
                        e.removeFromSuperlayer();
                    }
                }
            })
//            previewLayer.sublayers = nil;
//            setlayerHidden(true)
        }
    }
    
    func setlayerHidden(_ hidden: Bool) {
        if (faceRectCALayer.isHidden != hidden){
            print("hidden:" ,hidden)
            DispatchQueue.main.async(execute: { 
                () -> Void in
                self.faceRectCALayer.isHidden = hidden
            })
        }
    }
    
    func findMaxFaceRect(_ faces : Array<CGRect>) -> CGRect {
        if (faces.count == 1) {
            return faces[0]
        }
        var maxFace = CGRect.zero
        var maxFace_size = maxFace.size.width + maxFace.size.height
        for face in faces {
            let face_size = face.size.width + face.size.height
            if (face_size > maxFace_size) {
                maxFace = face
                maxFace_size = face_size
            }
        }
        return maxFace
    }
    

    

}
