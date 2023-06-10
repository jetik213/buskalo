//
//  QRScannerViewController.swift
//  buskalo
//
//  Created by crizcode on 2/26/23.
//  Copyright © 2023 crizcode. All rights reserved.

import UIKit
import AVFoundation
import CoreImage

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    @IBOutlet weak var scanner: UIImageView!
    @IBOutlet weak var urlscanner: UILabel!
    
        let captureSession = AVCaptureSession()
        var previewLayer: AVCaptureVideoPreviewLayer!
        var qrCodeFrameView: UIView?
        var scannedImage: UIImage? {
            didSet {
                processImage()
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            initializeCaptureSession()
            initializePreviewLayer()
            initializeQRCodeFrameView()
        }

        private func initializeCaptureSession() {
            guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }

            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(input)

                let captureMetadataOutput = AVCaptureMetadataOutput()
                captureSession.addOutput(captureMetadataOutput)
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            } catch {
                print(error)
                return
            }

            captureSession.startRunning()
        }

        private func initializePreviewLayer() {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = scanner.layer.bounds

            scanner.layer.addSublayer(previewLayer)
        }

        private func initializeQRCodeFrameView() {
            qrCodeFrameView = UIView()
            qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView?.layer.borderWidth = 2
            scanner.addSubview(qrCodeFrameView!)
            scanner.bringSubviewToFront(qrCodeFrameView!)
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }

            if metadataObj.type == AVMetadataObject.ObjectType.qr {
                let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObj)

                qrCodeFrameView?.frame = barCodeObject!.bounds

                if metadataObj.stringValue != nil {
               }
            }
        }

        func processImage() {
            guard let image = scannedImage else { return }

            let context = CIContext(options: nil)
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

            if let ciImage = CIImage(image: image), let features = detector?.features(in: ciImage) {
                for feature in features as! [CIQRCodeFeature] {
                    urlscanner.text = feature.messageString
                    print("Contenido del código QR: \(feature.messageString ?? "")")
                }
            }
        }

    @IBAction func buttonScannear(_ sender: Any) {
            let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .photoLibrary
                present(picker, animated: true, completion: nil)
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }

                scannedImage = image
                scanner.image = image

                dismiss(animated: true, completion: nil)
            
        }
}
