//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/28/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//
import MapKit
import UIKit

class MapHomeViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    var selectedPin:MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(action))
        longGesture.minimumPressDuration = 0.5
        longGesture.delaysTouchesBegan = true
        
        mapView.addGestureRecognizer(longGesture)
        
    }
    
    @objc func action() {
        mapView.addAnnotation(<#MKAnnotation#>)
        
        print("long press")
    }
    
    @objc func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
       
        
    }

}

extension MapHomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let id = GlobalVariables.reusableIDForMap
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .purple
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
    }
}

