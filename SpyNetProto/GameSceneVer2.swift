//
//  MapScene.swift
//  SpyNetProto
//
//  Created by Edward Han on 3/9/17.
//  Copyright © 2017 Edward Han. All rights reserved.
//



import UIKit
import QuartzCore
import SceneKit
import MapKit
import Mapbox




class GameSceneVer2: SCNScene, CreateScnTargets, MoveSceneTargets {
    
    //    var geometryNodes = GeometryNodes()
    let cameraNode = SCNNode()
    //    var map = MKMapView()
    //    var map = MGLMapView()
    
    
    var targetNodes: [TargetScnNode] = []
    
    var planeNode = SCNNode()
    
    var sphereNode = SCNNode()
    
    var mapView: MGLMapView?
    
    
    func handlePan(translation: CGPoint){
        print(translation)
        let adjustedX = translation.x / 100
        let adjustedY = translation.y / 100
        for node in targetNodes {
            node.position.x += Float(adjustedX)
            node.position.y += Float(adjustedY)
        }
        
    }
    
    func addPlaneNode() {
        
        planeNode.geometry?.firstMaterial?.diffuse.contents = snapshot(view: mapView!)
    }
    
    func snapshot(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let snapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshot!
    }
    
    
    func takeSnapshot(mapView: MGLMapView, withCallback: @escaping (UIImage?, Error?) -> ()) {
        let options = MKMapSnapshotOptions()
        //        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.main.scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start() { snapshot, error in
            guard snapshot != nil else {
                withCallback(nil, error)
                return
            }
            
            withCallback(snapshot!.image, nil)
        }
    }
    
    
    
    func createScnTargets(target: TargetNew) {
        let scnNode = TargetScnNode(target: target)
        
        Model.shared.fetchImage(stringURL: scnNode.profileImageURL) { (imageReturned) in
            if let image = imageReturned {
                scnNode.geometry?.firstMaterial?.diffuse.contents = image.circle
                let randY = Int(arc4random()%2)
                let randX = Int(arc4random()%2)
                scnNode.position = SCNVector3(randX, randY, 0)
                self.rootNode.addChildNode(scnNode)
                self.targetNodes.append(scnNode)
                
            }
        }
        
        
    }
    
    convenience init(create: Bool, map: MGLMapView) {
        
        
        
        self.init()
        
        //        geometryNodes.addNodesTo(rootNode)
        
        mapView = map
        
        Model.shared.moveScnTargetDelegate = self
        
        let floor = SCNFloor()
    
        let sphere = SCNSphere()
        let plane = SCNPlane()
        //        floor.firstMaterial!.diffuse.contents = UIColor.white
        //        fillMap(mapView: map)
        
        
        //        takeSnapshot(mapView: map) { (imageMap, error) in
        //            floor.firstMaterial?.diffuse.contents = imageMap
        //            floor.firstMaterial?.isDoubleSided = true
        //            sphere.firstMaterial?.diffuse.contents = imageMap
        //        }
        
        
 
        sphere.firstMaterial?.diffuse.contents = snapshot(view: map)
        plane.firstMaterial?.diffuse.contents = snapshot(view: map)

        
        sphere.radius = 2
        sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0,-2,0)
        rootNode.addChildNode(sphereNode)
        
        
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0,-5,0)
        
        plane.height = 6
        plane.width = 3
        planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(0,-1,-3)
        //        planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-60), y: 0, z: 0)
        planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-70), y: 0, z: 0)
        //        planeNode.rotation = SCNVector4(1, 0, 0, Float(-M_PI / 5.0))
        
        //        let sphereNode = SCNNode(geometry: sphere)
        //        rootNode.addChildNode(floorNode)
        //        rootNode.addChildNode(cubeNode)
//        rootNode.addChildNode(planeNode)
        cameraNode.camera = SCNCamera()
        //cameraNode.camera!.usesOrthographicProjection = true
        cameraNode.position = SCNVector3(0, 0, 3)
        //        cameraNode.rotation = SCNVector4(1,0,0, Float(-M_PI / 16.0))
        
        rootNode.addChildNode(cameraNode)
        
        let lightNodeSpot = SCNNode()
        lightNodeSpot.light = SCNLight()
        lightNodeSpot.light!.type = SCNLight.LightType.ambient
        //        lightNodeSpot.light!.attenuationStartDistance = 0
        //        lightNodeSpot.light!.attenuationFalloffExponent = 2
        //        lightNodeSpot.light!.attenuationEndDistance = 30
        lightNodeSpot.position = SCNVector3(0,0,0)
        
        
        let lightNodeSpot2 = SCNNode()
        lightNodeSpot2.light = SCNLight()
        lightNodeSpot2.light!.type = SCNLight.LightType.ambient
        //        lightNodeSpot.light!.attenuationStartDistance = 0
        //        lightNodeSpot.light!.attenuationFalloffExponent = 2
        //        lightNodeSpot.light!.attenuationEndDistance = 30
        lightNodeSpot2.position = SCNVector3(0,10,10)
        
        rootNode.addChildNode(lightNodeSpot2)
        rootNode.addChildNode(lightNodeSpot)
        
        let emptyTarget = SCNNode()
        emptyTarget.position = SCNVector3(0,0,0)
        
        lightNodeSpot.constraints = [SCNLookAtConstraint(target: emptyTarget )]
        
    }
    
    
    
    
    
    
}





