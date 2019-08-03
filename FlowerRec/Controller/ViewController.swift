//
//  ViewController.swift
//  FlowerType
//
//  Created by Duale on 7/30/19.
//  Copyright © 2019 Duale. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SDWebImage
import Social
import Alamofire
import SwiftyJSON

class ViewController: UIViewController,UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    let url = "https://en.wikipedia.org/w/api.php"
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        //        imagePicker.sourceType = .camera
        alertCamOrPhoto()
        imagePicker.allowsEditing = true
        navigationController?.navigationBar.barTintColor = .green
        descripLabel.textColor = UIColor.green
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var camera: UIBarButtonItem!
    @IBOutlet weak var imageViewCaptured: UIImageView!
    @IBOutlet weak var descripLabel: UILabel!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imagePicked = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let cImage = CIImage(image: imagePicked) else {
                fatalError("Unfound image")
            }
            imageViewCaptured.image = imagePicked
            detectFlowerCapture (image : cImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cameraCaptured(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func detectFlowerCapture (image : CIImage)  {
        // this is getting the model var from the ml model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Unfound Image")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] , let firstFlowerInder = results.first else {
                fatalError("No image found")
            }
            //            print(results)
            // set this into the title of the navigat
            self.navigationItem.title = firstFlowerInder.identifier.capitalized
            // we are calling this from wikipedia info
            self.getWikiData(name: firstFlowerInder.identifier)
            print("=========")
            print(firstFlowerInder.identifier)
        }
        
        
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do { try handler.perform([request]) }
        catch { print(error) }
    }
    
    func getWikiData (name : String ) {
        let params : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : name, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]
        
        Alamofire.request(url , method: .get , parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                let res = JSON(response.result.value!)
                //               print(res)
                
                let pageId = res["query"]["pageids"][0].stringValue
                let floDes = res["query"]["pages"][pageId]["extract"].stringValue
                let floUrl = res["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageViewCaptured.sd_setImage(with: URL(string: floUrl))
                self.descripLabel.text = floDes
                
            } else {
                print("Error getting the json")
            }
        }
    }
    
    func alertCamOrPhoto () {
        let alert = UIAlertController(title: "Choose Image Source", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Get image from camera", style: .default, handler: { (action: UIAlertAction) in
            self.getImageNeed(fromSourceType: .camera)
        }))
        
        alert.addAction(UIAlertAction(title: "Get image from Photo Album", style: .default, handler: { (action: UIAlertAction) in
            self.getImageNeed(fromSourceType: .photoLibrary)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getImageNeed(fromSourceType sourceType: UIImagePickerController.SourceType) {
        imagePicker.sourceType = sourceType
        cameraCaptured(camera)
    }
    
}

