//
//  ViewController.swift
//  photoclicker
//
//  Created by Mac on 26/01/24.
//

import UIKit
import CoreImage
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var shareButton: UIButton!
    var imagePicker: UIImagePickerController!
    @IBOutlet weak var editImageButton: UIButton!
    @IBOutlet weak var openCameraButton: UIButton!
    @IBOutlet weak var imagePickerView: UIImageView!
    var selectedImage: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        imagePickerView.image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        selectedImage = imagePickerView.image?.fixOrientation()
    }
    @IBAction func openCameraActio(_ sender: Any) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary // comment to disable taking photo from photoLibrary
        //imagePicker.sourceType = .camera // uncomment this line to take image from camera
        present(imagePicker, animated: true, completion: nil)
        
    }
    @IBAction func shareAction(_ sender: Any) {
        guard let imageToShare = imagePickerView.image else {
            let alertController = UIAlertController(title: "No Image Clicked", message: "Please click image", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController,animated: true, completion: nil)
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [imagePickerView.image as Any], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // for iPad
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList
        ]
        
        present(activityViewController, animated: true, completion: nil)
        
    }
    @IBAction func editImageAction(_ sender: Any) {
        guard let image = selectedImage else {
            let alertController = UIAlertController(title: "No Image Clicked", message: "Please click image", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController,animated: true, completion: nil)
            
            
            return
        }
        
        let editedImage = performImageEditing(on: image)
        imagePickerView.image = image
        
    }
    
    func performImageEditing(on image: UIImage) -> UIImage {
        guard let cgImage = selectedImage?.cgImage, let openGLContext = EAGLContext(api: .openGLES3) else {
            return selectedImage!
        }
        if let ciImage = CIImage(image: image) {
            let filter = CIFilter(name: "CISepiaTone")!
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            //            filter.setValue(0.0, forKey: kCIInputSaturationKey)
            //            filter.setValue(0.0, forKey: kCIInputBrightnessKey)
            filter.setValue(0.80, forKey: kCIInputIntensityKey)
            print("brightness \(filter)")
            let context = CIContext(eaglContext: openGLContext)
            if let output = filter.value(forKey: kCIOutputImageKey) as? CIImage, let cgiImageResult = context.createCGImage(output, from: output.extent) {
                selectedImage = UIImage(cgImage: cgiImageResult)
            }
            return selectedImage!
        }
        
        
        return image
    }
}
    extension UIImage {
        
        func fixOrientation() -> UIImage {
            
            // No-op if the orientation is already correct
            if ( self.imageOrientation == UIImage.Orientation.up ) {
                return self;
            }
            
            // We need to calculate the proper transformation to make the image upright.
            // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
            var transform: CGAffineTransform = CGAffineTransform.identity
            
            if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
                transform = transform.translatedBy(x: self.size.width, y: self.size.height)
                transform = transform.rotated(by: CGFloat(Double.pi))
            }
            
            if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
            }
            
            if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
                transform = transform.translatedBy(x: 0, y: self.size.height);
                transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
            }
            
            if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            }
            
            if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
                transform = transform.translatedBy(x: self.size.height, y: 0);
                transform = transform.scaledBy(x: -1, y: 1);
            }
            
            // Now we draw the underlying CGImage into a new context, applying the transform
            // calculated above.
            let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                           bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                           space: self.cgImage!.colorSpace!,
                                           bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
            
            ctx.concatenate(transform)
            
            if ( self.imageOrientation == UIImage.Orientation.left ||
                 self.imageOrientation == UIImage.Orientation.leftMirrored ||
                 self.imageOrientation == UIImage.Orientation.right ||
                 self.imageOrientation == UIImage.Orientation.rightMirrored ) {
                ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
            } else {
                ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
            }
            
            // And now we just create a new UIImage from the drawing context and return it
            return UIImage(cgImage: ctx.makeImage()!)
        }
    }
