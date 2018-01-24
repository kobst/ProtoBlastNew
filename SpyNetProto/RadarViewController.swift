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

    @IBOutlet weak var overlay: UIView!


    var myLocation: CLLocationCoordinate2D!

    var annotations: [MGLAnnotation] = []

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

    func makeSprites() {
        for point in annotations {
            let overlayPoint = radarMap.convert(point.coordinate, toPointTo: self.overlay)
            let imageView = UIView()
            imageView.backgroundColor = UIColor.cyan
            imageView.frame.size.width = 20
            imageView.frame.size.height = 20
            imageView.layer.cornerRadius = 10
            imageView.center = overlayPoint
            overlay.addSubview(imageView)

        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for view in overlay.subviews {
            view.removeFromSuperview()
        }
        
        
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

    
//       override func viewDidAppear(_ animated: Bool)  {
//        for blip in blips {
//            blip.removeFromSuperview()
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Model.shared.myDraggedLocation =  CLLocationCoordinate2D(latitude: (Model.shared.myLocation?.coordinate.latitude)!, longitude: (Model.shared.myLocation?.coordinate.longitude)!)
        
       
        myLocation = CLLocationCoordinate2D(latitude: (Model.shared.myLocation?.coordinate.latitude)!, longitude: (Model.shared.myLocation?.coordinate.longitude)!)

        
        radarMap.delegate = self
        radarMap.isZoomEnabled = true
        radarMap.isPitchEnabled = true
        radarMap.latitude = myLocation.latitude
        radarMap.longitude = myLocation.longitude
     
        
        cameraMap = MGLMapCamera(lookingAtCenter: radarMap.centerCoordinate, fromDistance: 75, pitch: 85, heading: 180)
        radarMap.camera = cameraMap
        radarMap.setZoomLevel(16, animated: true)
        radarMap.isUserInteractionEnabled = true
        view.addSubview(radarMap)
//        sceneView.isHidden = true
//        view.bringSubview(toFront: overlay)

        let centerScreenPoint: CGPoint = radarMap.convert(radarMap.centerCoordinate, toPointTo: self.overlay)
        
//        let myLoc = CLLocationCoordinate2D(latitude: (Model.shared.myLocation?.coordinate.latitude)!, longitude: (Model.shared.myLocation?.coordinate.longitude)!)
//
//        let centerScreenPoint: CGPoint = radarMap.convert(myLoc, toPointTo: self.overlay)

//        print("Screen center: \(centerScreenPoint) = \(radarMap.center)")

//        let imageView = UIView()
 
        overlay.isUserInteractionEnabled = false

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
        view.bringSubview(toFront: overlay)
        
        
        
        let mapCenter = UIView()
        mapCenter.backgroundColor = UIColor.cyan
        mapCenter.frame.size.width = 12
        mapCenter.frame.size.height = 12
        mapCenter.layer.cornerRadius = 6
        mapCenter.center = centerScreenPoint
        overlay.addSubview(mapCenter)
        
        
        
        Modelv2.shared.getTweets(myLocation: Model.shared.myLocation!) {
             print("done in closure TWEETS /n /n/ n TWEETS")
//            self.zoomMap()
            self.addTweets()
            
        
        }




    }

    func addTweets() {
        for target in Model.shared.tweetTargets {
//            let pt = self.radarMap.convert(target.annotation.coordinate, toPointTo: self.sceneView)
            self.radarMap.addAnnotation(target.annotation)
//            let mapPt = self.radarMap.convert(target.annotation.coordinate, toPointTo: self.overlay)
            let pt4 = self.convertMapPtToScenePt(point: target.annotation.coordinate)

            self.fieldScene.addTargetSpritesNew(target: target, pos: pt4)
            
            
//            let node = TargetSpriteNew(target: target, pos: pt4)
//            Model.shared.targetSpriteNew.append(node)
//            self.fieldScene.addChild(node)
//            node.isHidden = false
//            node.animateSize()
//            node.changePhysicsBody()
//            print(node.position)
        }
        
    }
    
    func convertMapPtToScenePt(point: CLLocationCoordinate2D) -> CGPoint {
        
        let mapPt = self.radarMap.convert(point, toPointTo: self.overlay)
        
        let midY = (self.view.frame.height / 2)
        
        let newY = mapPt.y - 2*(mapPt.y  - midY)
     
        let pt2 = CGPoint(x: mapPt.x, y: newY)
        let pt3 = self.overlay.convert(pt2, to: self.sceneView)
        let pt4 = self.sceneView.convert(pt3, to: self.sceneView.scene!)
        return pt4
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

            // Set the annotation view’s background color to a value determined by its longitude.
            let hue = CGFloat(annotation.coordinate.longitude) / 100
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
    
//    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
//
//        addTweets()
//
//    }
//        guard let scene = sceneView.scene as? FieldScene else { return }
//        let pt = self.radarMap.convert(coordinate, toPointTo: self.sceneView)
//        let pt2 = self.sceneView.convert(pt, to: self.sceneView.scene!)
     
        
//        for view in overlay.subviews {
//            view.removeFromSuperview()
//        }
        
//         for target in Model.shared.userTargets {
//            let pt = self.radarMap.convert(target.annotation.coordinate, toPointTo: self.overlay)
//            print(target.annotation.coordinate)
//            print(pt)
//            let imageView = UIView()
//            imageView.backgroundColor = UIColor.cyan
//            imageView.frame.size.width = 6
//            imageView.frame.size.height = 6
//            imageView.layer.cornerRadius = 3
//            imageView.center = pt
//            self.overlay.addSubview(imageView)
//        }
     
        
//        for view in overlay.subviews {
//
//            view.removeFromSuperview()
//        }
   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

