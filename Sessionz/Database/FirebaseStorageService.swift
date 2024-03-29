//
//  FirebaseStorageService.swift
//  Sessionz
//
//  Created by C4Q on 5/31/18.
//  Copyright © 2018 C4Q. All rights reserved.
//

import UIKit
import Toucan 
import FirebaseStorage
import FirebaseDatabase

enum ImageType: String {
    case userProfileImg = "users"
}

class FirebaseStorageService {
    private init() {
        // Get a reference to the storage service using the default Firebase App
        storage = Storage.storage()
        // Create a storage reference from our storage service
        storageRef = storage.reference()
        
    }
    static let service = FirebaseStorageService()
    weak var delegate: StorageServiceDelegate?
    
    //storage references
    private var storage: Storage!
    private var storageRef: StorageReference!
    private var userProfileImgRef: StorageReference!
    
    
    func storeImage(withImageType imageType: ImageType, imageUID: String, image: UIImage){
        //Resize the image
        guard let resizedImage = Toucan(image: image).resize(CGSize(width: 400, height: 400)).image else {return}
        //Convert data to PNG representation
        guard let data = UIImagePNGRepresentation(resizedImage) else {return}
        
        //Initialize storage meta data and set its content type
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        //Uploads the file to the path under the specific image type
        //ImageUID will be the same as the database post UID that it is associated with i.e) 12345 == 12345
        let uploadTask = storageRef.child(imageType.rawValue).child(imageUID).putData(data, metadata: metadata) { (storageMetaData, error) in
            if let error = error {
                print("uploadTask error: \(error)")
            } else if let storageMetaData = storageMetaData{
                print("storageMetadata: \(storageMetaData)")
                //there are alot of properties on storageMetaData!!
            }
        }
        
        //When upload is successful call the delegate and alert user of changes
        uploadTask.observe(.success) { (snapshot) in
            self.delegate?.didStoreImage(self)
            if let downloadedURL = snapshot.metadata?.downloadURL(){
                let imageURL = String(describing: downloadedURL)
                //set that url string at the correct reference: EX) whatever bucket/uid/image = pic
                Database.database().reference(withPath: imageType.rawValue).child(imageUID).child("image").setValue(imageURL)
            }
        }
        
        //If upload is unsucessful call the delegate andalert the user of changes
        uploadTask.observe(.failure) { (snapshot) in
            self.delegate?.didFailStoreImage(self, error: "Error with notifying user when upload fails")
        }
    }
    
    func retrieveImage(imageURL: String,
                       completionHandler: @escaping (UIImage) -> Void,
                       errorHandler: @escaping (Error) -> Void) {
        ImageHelper.manager.getImage(from: imageURL,
                                     completionHandler: { completionHandler($0)},
                                     errorHandler: { errorHandler($0) })
    }
    
}
