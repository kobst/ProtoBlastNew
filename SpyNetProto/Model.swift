//
//  Model.swift
//  SpyNetProto
//
//  Created by Edward Han on 1/27/17.
//  Copyright © 2017 Edward Han. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import CoreLocation
import GeoFire
import AVFoundation
import ProjectOxfordFace
import TwitterKit

// change time to date...
// extension on attempt to convert time to date...
// maybe lat lon as doubles.......


class Attempt {
    var lat: CLLocationDegrees
    var lon: CLLocationDegrees
    var time: String
    var target: String
    var taker: String
    var photo = UIImage(named: "beckett")!
    var success: Bool
    
    init(target: String, taker: String, location: CLLocation, photo: UIImage, success: Bool) {
        lat = location.coordinate.latitude
        lon = location.coordinate.longitude
        time = String(describing: Date())
        self.target = target
        self.taker = taker
        self.photo = photo
        self.success = success
    }
    
    
    init(snapshot: DataSnapshot) {
        
        let dict = snapshot.value as! [String : Any]
        lat = dict["lat"] as! CLLocationDegrees
        lon = dict["lon"] as! CLLocationDegrees
        time = dict["time"] as! String
        target = dict["target"] as! String
        taker = dict["taker"] as! String
        let successString = dict["success"] as! String
        success = successString == "fail" ? false : true
        
        let imageUrlString = dict["photo"] as! String
        let imageURL = URL(string: imageUrlString)
      
        Model.shared.fetchImage(stringURL: imageURL!) { (image) in
            if let returnedImage = image {
                
                self.photo = returnedImage
                
            }

        }
        
        
        
    }
    
    
    
}

struct PermisisionManager {
    static var cameraAccessGranted : Bool {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized
    }
    
    static func requestCameraAccess(completion: @escaping (_ granted : Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
        case .restricted, .denied:
            DispatchQueue.main.async { completion(false) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

}


class Model {
    
    let msApiKey = "c978b7500d5b4a2e97bd20fdfb9bf03f"
    let msApiKey2 = "8a26a031b4454ec0802ec99ddc7a3f7d"
   
//    let allCategories: [TargetSpriteNew.Category] = [.tweet, .spyGame, .eater38, .timeOutEvent]
    
    
    var myLat: CGFloat?
    var myLong: CGFloat?
    
    // make this cllocation2d....
    var myLocation: CLLocation?
    
    
    
    static var shared = Model()

    private init(){}
    
    let scaleAdjust = CGFloat(15000)
    
    var loggedInUser: User?
//    var queryUsers: [User] = []
//    var queryTargets: [TargetSprite] = []
//    var sceneTargetSprites: [TargetSpriteVar] = []
//    var targetSprites: [TargetSprite] = []
//    var sceneTweets: [TweetData] = []
//    var sceneTargets: [Target] = []
    
    var targetSpriteNew: [TargetSpriteNew] = [] {
        didSet {
            if targetSpriteNew.count > userTargets.count {
                ()
            }
        }
    }
    
    

    var myDraggedLocation: CLLocationCoordinate2D?
    
    var myHeading: CLLocationDirection?
    var myScreenOrigin = CGPoint(x: 0, y: 100)
    var dateFormatter = DateFormatter()

    var userTargets: [UserTarget] = []
    var tweetTargets: [TweetTarget] = []
    var userTargetsByDistance: [UserTarget] {
        return userTargets.sorted(by: {$0.distance < $1.distance})
    }
    
    var tweetTargetsByDistance: [TweetTarget] {
        return tweetTargets.sorted(by: {$0.distance < $1.distance})
    }
    var targetSprNewByDistance: [TargetSpriteNew] {
        
        return targetSpriteNew.sorted(by: {$0.distance < $1.distance})
        
    }
    
    
    weak var addTargetDelegate: AddTargetProtocol?
    
    weak var addBlipDelegate: AddBlips?
    
    weak var moveSpriteDelegate: MoveSprites?
    
    weak var addScnTargetDelegate: CreateScnTargets?
    
    weak var moveScnTargetDelegate: MoveSceneTargets?
    

    
    let ref = Database.database().reference()
//    let geoFire = GeoFire(firebaseRef: FIRDatabase.database().reference(withPath: "user_locations"))

    func moveScnTargets(translation: CGPoint) {
        
        moveScnTargetDelegate?.handlePan(translation: translation)
    }
    
    func fetchUser(UID: String, completionHandler: @escaping (User?) -> ()){
        ref.child("users").child(UID).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                let newUser = User(snapshot: snapshot)
                completionHandler(newUser)
            }
            else {
                completionHandler(nil)
            }
        })
    }
    
    
    func makeFakeLocation() -> CLLocation {

        let count = fakeLocations.count - 1
        let random = Int(arc4random()) % count
        let key = fakeLocations[random]
        return coordinates[key]!

    }
    
    
    func updateMyLocation(myLocation: CLLocation) {
        let geoFire = GeoFire(firebaseRef: ref.child("user_locations"))
        
        let userID = Model.shared.loggedInUser!.uid
        let uid = Session.sharedSession.currentUser?.uid

        let fakeLocation = makeFakeLocation()
        geoFire!.setLocation(fakeLocation, forKey: userID) { (error) in
//        geoFire!.setLocation(myLocation, forKey: userID) { (error) in
            if (error != nil) {
                debugPrint("An error occured: \(error.debugDescription)")
            } else {
                print("Saved location successfully!")
            }
        }
    }
    
    


    func getTargetNew(myLocation: CLLocation) {
        
        var uids = [(String, CLLocation)]()
        
        let geoFire = GeoFire(firebaseRef: ref.child("user_locations"))
        //        var targets = [Target]()
        //        let fakeLocation = makeFakeLocation()
        let circleQuery = geoFire?.query(at: myLocation, withRadius: 2.5)
        
        circleQuery?.observe(.keyEntered, with: { [weak self] (string, location) in
            if let validUID = string, let locationBack = location {
                
                let tuple = (validUID, locationBack)
                uids.append(tuple)
                
                self?.ref.child("users/\(validUID)").observe(.value, with: { [weak self] snapshot in
            
                    let userTarget = UserTarget(snapshot: snapshot, location: locationBack)
                
                    self?.userTargets.append(userTarget)
                
                    self?.addBlipDelegate?.addTargetBlips(target: userTarget)
                })
            
            }}
            )
        
    }
    
    
    func moveSprites(translation: CGPoint) {
        
        moveSpriteDelegate?.handlePanFrom(translation: translation)
        
    }
    
    func getTargetsNewVerComp(myLocation: CLLocation, closure: (@escaping() -> Void)) {
        
        var uids = [(String, CLLocation)]()
        
        let geoFire = GeoFire(firebaseRef: ref.child("user_locations"))
        //        var targets = [Target]()
        //        let fakeLocation = makeFakeLocation()
        if let circleQuery = geoFire?.query(at: myLocation, withRadius: 2.5) {
            
            _ = circleQuery.observe(.keyEntered, with: {(string, location) in
                if let validUID = string, let locationBack = location {
                    let tuple = (validUID, locationBack)
                    uids.append(tuple)
                    }
                }
            )
            circleQuery.observeReady( {
                print(uids.count)
                print("\n-------observeReady-------\n ")
                for (x,y) in uids {
                    
                    self.ref.child("users/\(x)").observe(.value, with: { [weak self] snapshot in
                        
                        let userTarget = UserTarget(snapshot: snapshot, location: y)
                        
                        self?.userTargets.append(userTarget)
                        
                        self?.addBlipDelegate?.addTargetBlips(target: userTarget)
//
//                        self?.addTargetDelegate?.addTargetSpritesNew(target: userTarget)
                        self?.addTargetDelegate?.addTargetSpritesNew(target: userTarget, pos: CGPoint(x: 0.0, y: 0.0))
//                        self?.addScnTargetDelegate?.createScnTargets(target: userTarget)
                        
                        print(uids.count)
                    })
                }
    
                closure()
                
                
            })
    }
    }
    
    
    
    
    
    func getTargetsNewVerComp2(myLocation: CLLocation, closure: (@escaping() -> Void)) {
        
        var uids = [(String, CLLocation)]()
        
        let geoFire = GeoFire(firebaseRef: ref.child("user_locations"))
  
        let dG = DispatchGroup()
        
        if let circleQuery = geoFire?.query(at: myLocation, withRadius: 2.5) {
            
            _ = circleQuery.observe(.keyEntered, with: {[weak self](string, location) in
                if let validUID = string, let locationBack = location {
                    let tuple = (validUID, locationBack)
                    uids.append(tuple)
                    
                    dG.enter()
                    
                    self?.ref.child("users/\(validUID)").observe(.value, with: { [weak self] snapshot in
                        
                        let userTarget = UserTarget(snapshot: snapshot, location: locationBack)
                        
                        self?.userTargets.append(userTarget)
                        
                        self?.addBlipDelegate?.addTargetBlips(target: userTarget)
                        
                        print(uids.count)
                        
                        dG.leave()
                    })
                    
                }
            }
            )
            circleQuery.observeReady( {
               
                dG.notify(queue: .main, execute: { 
                     print("\n-------observeReady-------\n ")
                     print(uids.count)
                    closure()
                    
                })
//                for (x,y) in uids {
//                    
//                    self.ref.child("users/\(x)").observe(.value, with: { [weak self] snapshot in
//                        
//                        let userTarget = UserTarget(snapshot: snapshot, location: y)
//                        
//                        self?.userTargets.append(userTarget)
//                        
//                        self?.addBlipDelegate?.addTargetBlips(target: userTarget)
//                        
//                        print(uids.count)
//                    })
//                }
                
            })
        }
    }
    
    
    
    
    
    func setNewAttempt(attempt: Attempt) {
        
        let result = attempt.success ? "success" : "fail"
        let baseRef = Database.database().reference()
        let ref = baseRef.child("attempts").childByAutoId()
        let data = UIImageJPEGRepresentation(attempt.photo, 0.1)!
        let storageRef = Storage.storage().reference()
        let imageUID = NSUUID().uuidString
        let imageRef = storageRef.child(imageUID)
        imageRef.putData(data, metadata: nil).observe(.success) { (snapshot) in
            let imageURL = snapshot.metadata?.downloadURL()?.absoluteString
            
            let attemptData = [
                "target": attempt.target,
                "taker": attempt.taker,
                "lat": attempt.lat,
                "lon": attempt.lon,
                "time": attempt.time,
                "photo": imageURL ?? "no photo available",
                "success": result
        ] as [String : Any]
        
        ref.setValue(attemptData)
        
    }
    
    }
    

   
    func fetchImage(stringURL: URL, completionHandler: @escaping (UIImage?) -> ()) {
        DispatchQueue.global(qos: .background).async {
//            let url = URL(string: stringURL)!
            URLSession.shared.dataTask(with: stringURL) { (data, _, _) in
                guard let responseData = data else {
                    completionHandler(nil)
                    return
                }
                let image = UIImage(data: responseData)
                DispatchQueue.main.async {
                    completionHandler(image)
                }
                
                }.resume()
        }
    }
    
    class Mask {
        var taken: Bool = false
        var value: UInt32
        init(value: UInt32) {
            self.value = value
        }
    }
    
//    var arrayMasks: [Mask] {
//        Mask(value: 1 << 0),
//        Mask(value: 1 << 1),
//        Mask(value: 1 << 2),
//        Mask(value: 1 << 3)
//    
//    }
    
    var categoryMasks: [(UInt32, Bool)] = [
//    (0x1 << 0, false),
    (0x1 << 1, false),
    (0x1 << 2, false),
    (0x1 << 3, false),
    (0x1 << 4, false),
    (0x1 << 5, false),
    (0x1 << 6, false),
    (0x1 << 7, false),
    (0x1 << 8, false),
    (0x1 << 9, false),
    (0x1 << 10, false),
    (0x1 << 11, false),
    (0x1 << 12, false),
    (0x1 << 13, false),
    (0x1 << 14, false),
    (0x1 << 15, false),
    (0x1 << 16, false),
    (0x1 << 17, false),
    (0x1 << 18, false),
    (0x1 << 19, false),
    (0x1 << 21, false),
    (0x1 << 22, false),
    (0x1 << 23, false),
    (0x1 << 24, false),
    (0x1 << 25, false),
    (0x1 << 26, false),
    (0x1 << 27, false),
    (0x1 << 28, false),
    (0x1 << 29, false),
    (0x1 << 30, false),
    (0x1 << 31, false)
    ]
    
    
    
    var categoryMasksVer2: [UInt32] = [0x1 << 1, 0x1 << 2, 0x1 << 3, 0x1 << 4, 0x1 << 5, 0x1 << 6, 0x1 << 7, 0x1 << 8, 0x1 << 9, 0x1 << 10, 0x1 << 11, 0x1 << 12, 0x1 << 13, 0x1 << 14, 0x1 << 15, 0x1 << 16, 0x1 << 17, 0x1 << 18, 0x1 << 19, 0x1 << 20, 0x1 << 21, 0x1 << 22, 0x1 << 23, 0x1 << 24, 0x1 << 25, 0x1 << 26, 0x1 << 27, 0x1 << 28, 0x1 << 29, 0x1 << 30]
        
    
    var bitMaskOccupied = Array(repeating: false, count: 31)
    
 
    
////    var categoryMasksBinary: [(UInt32, Bool)] = [
////        (0b1, false),
////        (0b10 << 1, false),
////        (0b11 << 2, false),
////        (0b100 << 3, false),
////        (0b101 << 4, false),
////        (0b110 << 5, false),
////        (0b111 << 6, false),
////        (0b1000 << 7, false),
////        (0b1001 << 8, false),
////        (0b1010 << 9, false),
////        (0b1011 << 10, false),
////        (0b1100 << 11, false),
////        (0b1101 << 12, false),
////        (0b1110 << 13, false),
////        (0b1011 << 14, false),
////        (0b1100 << 15, false),
////        (0b1101 << 16, false),
////        (0b1111 << 17, false),
////        (0b10000 << 18, false),
////        (0b10001 << 19, false),
////        (0b10010 << 21, false),
////        (0b10011 << 22, false),
////        (0b10100 << 23, false),
////        (0b10101 << 24, false),
////        (0b10111 << 25, false),
////        (0b11000 << 26, false),
////        (0b11001 << 27, false),
////        (0b11010 << 28, false),
////        (0b11011 << 29, false),
////        (0b11100 << 30, false),
////        (0b11101 << 31, false)
////    ]
//    
//    
//    func assignBitMask() -> UInt32? {
//      
//        for i in 0...categoryMasks.count {
//            if categoryMasks[i].1 == false {
//                categoryMasks[i].1 = true
//                return categoryMasks[i].0
//                break
//            }
//            print("\(i)..\n..")
//        }
//
//        return nil
//    }
    
    
    func assignBitMask2() -> UInt32? {
        
        guard let openIndex = bitMaskOccupied.index(of: false) else {
            return nil
        }
        
        bitMaskOccupied[openIndex] = true
        return categoryMasksVer2[openIndex]
        
    }
    
    
    func removeBitMask2(mask: UInt32) {
        let index = categoryMasksVer2.index(of: mask)
        bitMaskOccupied[index!] = false
    }
    
    
//    
//    func removeBitMask(maskNum: UInt32) {
//        print("MADE AVAILABLE \n\n MADE AVAILABLE \n\n")
//        for i in 0...categoryMasks.count {
//            if categoryMasks[i].0 == maskNum {
//                categoryMasks[i].1 = false
//                break
//            }
//        }
//    }
//    
    
    
    
    
    let coordinates: [String: CLLocation] = [
        "strandbookstore": CLLocation(latitude: 40.7332583, longitude: -73.9907914),
        "eatalyflatiron": CLLocation(latitude: 40.742164, longitude: -73.992088),
        "UnionSquareNY": CLLocation(latitude: 40.7362512, longitude: -73.9946859),
        "MadSqParkNYC": CLLocation(latitude: 40.7420411, longitude: -73.9897575),
        "TimesSquareNYC": CLLocation(latitude: 40.758899, longitude: -73.987325),
        "sunshine_cinema": CLLocation(latitude: 40.7231256, longitude: -73.9921055),
        "IrvingPlaza" : CLLocation(latitude: 40.734933, longitude: -73.990642),
        "unionfarenyc": CLLocation(latitude: 40.737899, longitude: -73.993489),
        "highlinenyc" : CLLocation(latitude: 40.7479965, longitude: -74.0069589),
        "WSPConservancy": CLLocation(latitude: 40.7308228,longitude: -73.997332),
        "RubinMuseum": CLLocation(latitude: 40.732294, longitude: -73.9998917),
        "flightclub": CLLocation(latitude: 40.7324626, longitude: -73.999618),
        "WebsterHall" : CLLocation(latitude: 40.7324626, longitude: -73.999618),
        "vanguardjazz": CLLocation(latitude: 40.7324626, longitude: -73.999618),
        "MorganLibrary": CLLocation(latitude: 40.7489914, longitude: -73.9949119),
        "TheGarden": CLLocation(latitude: 40.7505085, longitude: -73.9956327),
        "GothamComedy": CLLocation(latitude: 40.7443792, longitude: -73.9964206),
        "burger_lobster": CLLocation(latitude: 40.7399067, longitude: -73.9942959),
        "OttoPizzeria": CLLocation(latitude: 40.7321577, longitude: -73.9987826),
        "lprnyc": CLLocation(latitude: 40.7254847, longitude: -74.0078584),
        "MightyQuinnsBBQ": CLLocation(latitude: 40.7270126, longitude: -73.9851812),
        "BaohausNYC": CLLocation(latitude: 40.734478, longitude: -73.9880487),
        "thespottedpig": CLLocation(latitude: 40.7316653, longitude: -74.0085412),
        "thebeannyc": CLLocation(latitude: 40.7246695, longitude: -73.9901214),
        "UnleashedPetco": CLLocation(latitude: 40.716145, longitude: -74.012408),
        "MercuryLoungeNY": CLLocation(latitude: 40.7451645,longitude: -73.9803567),
        "FriedmansNYC": CLLocation(latitude: 40.7451998, longitude: -73.995726),
        "Tekserve": CLLocation(latitude: 40.7434809, longitude: -73.995594),
        "Almond_NYC": CLLocation(latitude: 40.740085, longitude: -73.9909449),
        "BarnJoo": CLLocation(latitude: 40.7388458, longitude: -73.9922692),
        "milkbarstore": CLLocation(latitude: 40.7319039, longitude: -73.9879422),
        "BNUnionSquareNY": CLLocation(latitude: 40.7369432, longitude: -73.9918239)
    ]
    
    

    
    
    let fakeLocations: [String] = [
        "strandbookstore",
        "eatalyflatiron",
        "UnionSquareNY",
        "MadSqParkNYC",
        "TimesSquareNYC",
        "sunshine_cinema",
        "IrvingPlaza",
        "unionfarenyc",
        "highlinenyc",
        "WSPConservancy",
        "RubinMuseum",
        "flightclub",
        "WebsterHall",
        "vanguardjazz",
        "MorganLibrary",
        "TheGarden",
        "GothamComedy",
        "burger_lobster",
        "OttoPizzeria",
        "lprnyc",
        "MightyQuinnsBBQ",
        "BaohausNYC",
        "thespottedpig",
        "thebeannyc",
        "UnleashedPetco",
        "MercuryLoungeNY",
        "FriedmansNYC",
        "Tekserve",
        "Almond_NYC",
        "BarnJoo",
        "milkbarstore",
        "BNUnionSquareNY"
    ]
    
}


