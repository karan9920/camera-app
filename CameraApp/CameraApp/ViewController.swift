//
//  ViewController.swift
//  CameraApp
//
//  Created by Karan Saglani on 25/05/21.
//

import UIKit
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker = UIImagePickerController()
    var imageView = UIImageView()
    var path = UIBezierPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
    }
    @IBAction func btnOpenCameraClicked(_ sender: Any) {
        openCamera()
    }
    @IBAction func didPressShootButton(){
        imagePicker.takePicture()
    }
    @objc func saveImage()
    {
    
        imageByApplyingMaskingBezierPath(path, imageView.frame)
        
    }
    @objc func openCamera()
    {
        imagePicker = UIImagePickerController()
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera))
        {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.cameraDevice = .front
            //imagePickers?.view.frame = customCameraView.bounds
            imagePicker.view.contentMode = .scaleToFill
            imagePicker.allowsEditing = true
            imagePicker.showsCameraControls = false
            imagePicker.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            //Mark:- this part is handling camera in full screen in a custom view
            
            let screenSize = view.bounds.size
            let cameraAspectRatio = CGFloat(4.0 / 3.0)
            let cameraImageHeight = screenSize.width * cameraAspectRatio
            let scale = screenSize.height / cameraImageHeight
            imagePicker.cameraViewTransform = CGAffineTransform(translationX: 0, y: (screenSize.height - cameraImageHeight)/2)
            imagePicker.cameraViewTransform = (imagePicker.cameraViewTransform.scaledBy(x: scale, y: scale))
            imagePicker.cameraOverlayView = addOverlay()
            
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath, _ pathFrame: CGRect){
        
        UIGraphicsBeginImageContext(pathFrame.size)
        path.addClip()
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let imageData = image.pngData()
        let imageWithTransparentBackground = UIImage.init(data: imageData!)
        UIPasteboard.general.image = imageWithTransparentBackground
        
        // Save the image to the camera roll.
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: imageWithTransparentBackground!)
        }, completionHandler: { success, error in
            if success {
                let alert = UIAlertController(title: "", message: "Image saved", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    for each in self.view.subviews{
                        if each.tag == 101{
                            each.removeFromSuperview()
                        }
                    }
                    print("Ok button tapped")
                    
                  })
                alert.addAction(ok)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                
            }
            else if let error = error {
                let alert = UIAlertController(title: "", message: error.localizedDescription, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Error", message: "Could not save image.", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
            }
        })
        
    }
    
    func deg2rad(_ number: Double) -> CGFloat{
        return CGFloat(number * Double.pi/180)
    }
    
    func addSilhouetteForCamera() -> UIView?{
        
        let myView = UIView()
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.imagePicker.view.frame.width, height: self.imagePicker.view.frame.height), cornerRadius: 0)
        
        // Semicircle for the silhouette
        let semicircle = UIBezierPath(arcCenter: CGPoint(x: self.imagePicker.view.center.x, y: self.imagePicker.view.center.y), radius: 150, startAngle: deg2rad(0), endAngle: deg2rad(180), clockwise: false)
        
        // Chin area of the silhouette
        let freeform = UIBezierPath()
        freeform.move(to: CGPoint(x: self.imagePicker.view.center.x - 150, y: self.imagePicker.view.center.y))
        freeform.addCurve(to: CGPoint(x: self.imagePicker.view.center.x + 150, y: self.imagePicker.view.center.y), controlPoint1: CGPoint(x: self.imagePicker.view.center.x - 120, y: self.imagePicker.view.center.y + 340), controlPoint2: CGPoint(x: self.imagePicker.view.center.x + 120, y: self.imagePicker.view.center.y + 340))
        
        path.append(semicircle)
        path.append(freeform)
        path.usesEvenOddFillRule = true
        
        // Adding the canvas as a sublayer
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.opacity = 0.7
        
        let button = UIButton(type: .custom)
        button.isUserInteractionEnabled = true
        button.frame = CGRect(x: view.frame.midX - 75, y: view.frame.height - 120, width: 150, height: 150)
        let config = UIImage.SymbolConfiguration(
            pointSize: 45, weight: .medium, scale: .default)
        let image = UIImage(systemName: "camera", withConfiguration: config)
        
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(self.didPressShootButton), for: .touchUpInside)
        button.tintColor = UIColor.white
        button.contentMode = .scaleToFill
        imagePicker.view.addSubview(button)
        
        myView.layer.addSublayer(fillLayer)
        return myView
    }
    
    func addOverlay() -> UIView? {
        return self.addSilhouetteForCamera()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: false, completion: { [self] in
        
            // Add the preview
            let view: UIImageView = UIImageView()
            view.image = info[.originalImage] as? UIImage
            imageView = view
            imageView.tag = 101
            
            // Add retake button
            let button: UIButton = UIButton(type: .custom)
            button.setTitle("Retake", for: .normal)
            button.frame = CGRect(x: self.view.frame.minX + 20, y: self.view.frame.maxY - 101, width: 100, height: 53)
            button.layer.cornerRadius = 25
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
            button.addTarget(self, action: #selector(self.openCamera), for: .touchUpInside)
            
            // Add save photo button
            let qbutton: UIButton = UIButton(type: .custom)
            qbutton.setTitle("Save", for: .normal)
            qbutton.frame = CGRect(x: self.view.frame.maxX - 120, y: self.view.frame.maxY - 101, width: 100, height: 53)
            qbutton.layer.cornerRadius = 25
            qbutton.layer.borderWidth = 1
            qbutton.layer.borderColor = UIColor.white.cgColor
            qbutton.addTarget(self, action: #selector(self.saveImage), for: .touchUpInside)
            
            let path1 = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height), cornerRadius: 0)

            view.frame = self.view.frame
            print(view.frame.size.height)
            view.frame.size.height = self.view.frame.height * 0.75
            print(view.frame.size.height)
            print(view.frame.size.width)
            let semicircle = UIBezierPath(arcCenter: CGPoint(x: view.center.x, y: view.center.y), radius: (view.frame.width * 0.23), startAngle: deg2rad(0), endAngle: deg2rad(180), clockwise: false)
            
            let freeform = UIBezierPath()
            freeform.move(to: CGPoint(x: view.center.x - (view.frame.width * 0.23), y: view.center.y))
            freeform.addCurve(to: CGPoint(x: view.center.x + (view.frame.width * 0.23), y: view.center.y), controlPoint1: CGPoint(x: view.center.x - (view.frame.width * 0.181), y: view.center.y + (view.frame.height * 0.342)), controlPoint2: CGPoint(x: view.center.x + (view.frame.width * 0.181), y: view.center.y + (view.frame.height * 0.342))) // 230))
            
            path1.append(semicircle)
            path1.append(freeform)
            let pathCrop = UIBezierPath()
            pathCrop.append(semicircle)
            pathCrop.append(freeform)
            
            self.path = pathCrop
            
            let fillLayer1 = CAShapeLayer()
            fillLayer1.path = path1.cgPath
            fillLayer1.opacity = 0.7
            
            // Add everything
            self.view.addSubview(view)
            self.view.addSubview(button)
            self.view.addSubview(qbutton)
            view.layer.addSublayer(fillLayer1)
            
            print(view.frame.size.height)
        })
    }
}
