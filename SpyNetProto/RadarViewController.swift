//
//  RadarViewController.swift
//  SpyNetProto
//
//  Created by Edward Han on 3/22/17.
//  Copyright © 2017 Edward Han. All rights reserved.
//

import UIKit
import Mapbox
import INTULocationManager
import SpriteKit
class CustomAnnotationView: MGLAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = true
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.red.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Animate the border width in/out, creating an iris effect.
        let animation = CABasicAnimation(keyPath: "borderWidth")
        animation.duration = 0.1
        layer.borderWidth = selected ? frame.width / 4 : 2
        layer.add(animation, forKey: "borderWidth")
    }
}

//
//protocol AddBlips: class {
//    func addTargetBlips(target: UserTarget)
//}


protocol GoToDetail: class {
    func goToDetail(target: TargetSpriteNew)
}

class RadarViewController: UIViewController, MGLMapViewDelegate, GoToDetail {

    
    var myLocation: CLLocationCoordinate2D!

    var annotations: [MGLAnnotation] = []

    var centerAnnotation = MGLPointAnnotation()
    
    var targets: [UserTarget] = []
    
    var genTargets: [UserTarget] = []
    
    var selectedTarget: TargetSpriteNew?
    
    var cameraMap = MGLMapCamera()

    @IBOutlet weak var sceneView: SKView!
    
    var fieldScene: FieldScene!
    
    @IBOutlet weak var radarMap: MGLMapView!


    func goToDetail(target: TargetSpriteNew) {
        selectedTarget = target
        
        self.performSegue(withIdentifier: "toTweetDetail", sender: self)
        
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTweetDetail" {
            let vc = segue.destination as! TweetDetailViewController
            vc.target = selectedTarget
        }

//        if segue.identifier == "toMain" {
//            let vc = segue.destination as! MainViewController
//            vc.mapView = radarMap
//        }

//        if segue.identifier == "toPlay" {
//            let vc = segue.destination as! PlayViewController
//
//            // zoom in/out to get to right annotation view? or zoom in the play view controller. 
//            // or zoom in/out first then show the annotations....
//            vc.mapView = radarMap
//            vc.targets = targets
//
//        }

    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    


    func zoomMap() {

        var closestAnnotations: [MGLAnnotation] = []

     
        for target in Model.shared.tweetTargets {
            radarMap.addAnnotation(target.annotation)

        }

        for i in 0...3 {
            closestAnnotations.append(Model.shared.tweetTargetsByDistance[i].annotation)
            print(Model.shared.tweetTargets[i].distance)
        }
        
        radarMap.showAnnotations(closestAnnotations, animated: true)
//       radarMap.removeAnnotations(annotations)
//       addOverlayBlips()

    }

    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        Model.shared.myDraggedLocation =  CLLocationCoordinate2D(latitude: (Model.shared.myLocation?.coordinate.latitude)!, longitude: (Model.shared.myLocation?.coordinate.longitude)!)
        
       
        myLocation = CLLocationCoordinate2D(latitude: (Model.shared.myLocation?.coordinate.latitude)!, longitude: (Model.shared.myLocation?.coordinate.longitude)!)

        
        radarMap.delegate = self
        radarMap.isZoomEnabled = true
        radarMap.isPitchEnabled = true
//        radarMap.latitude = myLocation.latitude
//        radarMap.longitude = myLocation.longitude
        radarMap.centerCoordinate = myLocation
        centerAnnotation.coordinate = myLocation
        radarMap.addAnnotation(centerAnnotation)
        
        cameraMap = MGLMapCamera(lookingAtCenter: radarMap.centerCoordinate, fromDistance: 50, pitch: 86, heading:180)
        radarMap.camera = cameraMap
//        radarMap.setZoomLevel(16, animated: true)
        radarMap.isUserInteractionEnabled = true
        view.addSubview(radarMap)

        view.backgroundColor = UIColor.black

        
        fieldScene = FieldScene(size: sceneView.bounds.size)
        //        scene.addMapScene(map: mapView)
        //            fieldScene.delegateMainVC = self
        Modelv2.shared.addTargetDelegate = fieldScene
        fieldScene.delegateMainVC = self
        
        fieldScene.scaleMode = .aspectFill
        sceneView.presentScene(fieldScene)
        
        view.bringSubview(toFront: sceneView)
        sceneView.isHidden = false
        sceneView.allowsTransparency = true
        sceneView.isUserInteractionEnabled = false
        
        let cp = convertMapPtToScenePt(point: myLocation)
//        fieldScene.centerNode.position = cp
        
        print(cp)
//        view.bringSubview(toFront: overlay)
    
        
        
//        Modelv2.shared.getTweets(myLocation: Model.shared.myLocation!) {
//             print("done in closure TWEETS /n /n/ n TWEETS")
////            self.zoomMap()
//         
//            self.addTweets()
//        }

        
        Model.shared.getTargetsNewVerComp2(myLocation: Model.shared.myLocation!) {
            
            self.addUsers()

        }



    }

    
    func addUsers() {
        
        for target in Model.shared.userTargets {
            
            print(target.annotation.coordinate)
            let pt4 = self.convertMapPtToScenePt(point: target.annotation.coordinate)
            self.fieldScene.addTargetSpritesNew(target: target, pos: pt4)
        }
        
    }
    
    
    func addTweets() {
        for target in Model.shared.tweetTargets {
//            let pt = self.radarMap.convert(target.annotation.coordinate, toPointTo: self.sceneView)
//            self.radarMap.addAnnotation(target.annotation)
//            let mapPt = self.radarMap.convert(target.annotation.coordinate, toPointTo: self.overlay)
            print(target.annotation.coordinate)
            let pt4 = self.convertMapPtToScenePt(point: target.annotation.coordinate)
            self.fieldScene.addTargetSpritesNew(target: target, pos: pt4)
            
        }
        
    }
    
    func convertMapPtToScenePt(point: CLLocationCoordinate2D) -> CGPoint {
// branch extendSpriteSceneII
//        let mapPt = self.radarMap.convert(point, toPointTo: self.overlay)


//        let pt3 = self.overlay.convert(mapPt, to: self.sceneView)
//        let pt4 = self.sceneView.convert(pt3, to: self.sceneView.scene!)
//        return pt4
        
        print(point)
        let mapPt2 = self.radarMap.convert(point, toPointTo: self.sceneView)
        print(mapPt2)
        let pt = self.sceneView.convert(mapPt2, to: self.sceneView.scene!)
        return pt
    }
    
    
    
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?  {
        guard annotation is MGLPointAnnotation else {
            return nil
        }

        let reuseIdentifier = "\(annotation.coordinate.longitude)"

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            let hue = CGFloat(100)
            annotationView!.backgroundColor = UIColor(hue: hue, saturation: 0.5, brightness: 1, alpha: 1)
        }

        return annotationView

    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }


    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        let coordinate = mapView.centerCoordinate
        print(coordinate)
        let newSceneCenter = convertMapPtToScenePt(point: coordinate)
        guard let scene = sceneView.scene as? FieldScene else { return }
        Model.shared.myScreenOrigin = newSceneCenter
        scene.updateTargetSpriteNewVersion()
        scene.centerNode.position = newSceneCenter
        }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

