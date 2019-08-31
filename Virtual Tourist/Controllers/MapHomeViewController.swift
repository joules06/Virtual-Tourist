//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/28/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//
import CoreData
import MapKit
import UIKit

class MapHomeViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var labelForIndication: UILabel!
    @IBOutlet weak var buttonForEditAndDone: UIBarButtonItem!
    
    var selectedPin:MKPlacemark? = nil
    var dataController: DataController!
    var editEnable = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        populateMap()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Create a basic point annotation and add it to the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        let uuid = UUID()
        annotation.title = uuid.uuidString
        
        
        mapView.addAnnotation(annotation)
        
        addPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, uuid: uuid.uuidString)
        
        print("punto: \(point)")
    }
    
    //MARK: - Core Data functions
    
    fileprivate func fetchPines() throws -> [Pin] {
        let users = try self.dataController.viewContext.fetch(Pin.fetchRequest() as NSFetchRequest<Pin>)
        return users
    }
    
    fileprivate func delete(pin: Pin) throws {
        self.dataController.viewContext.delete(pin)
        try self.dataController.viewContext.save()
    }
    
    fileprivate func fetchPines(with uuid: String) throws -> [Pin] {
        let request = NSFetchRequest<Pin>(entityName: "Pin")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        
        return  try self.dataController.viewContext.fetch(request)
    }
    
    fileprivate func populateMap() {
        if let pines = try? fetchPines() {
            for element in pines {
                let coordinate = CLLocationCoordinate2D(latitude: element.latitude, longitude: element.longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = element.uuid
                
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    fileprivate func addPin(latitude: Double, longitude: Double, uuid: String) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()
        pin.uuid = uuid
        try? dataController.viewContext.save()
        print("location saved")
        
        
    }
    
    //MARK: - Buttons and actions

    @IBAction func editTapped(_ sender: UIBarButtonItem) {
        editEnable.toggle()
        
        UIView.animate(withDuration: 1) {
            self.labelForIndication.isHidden = !self.editEnable
            
        }
        
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editEnable {
            if let annotation = view.annotation {
                guard let title = annotation.title else {
                    return
                }
                guard let pines = try? fetchPines(with: title ?? "") else {
                    return
                }
                guard let firstPin = pines.first else {
                    return
                }
                do {
                    try delete(pin: firstPin)
                    print("pin deleted")
                    mapView.removeAnnotation(annotation)
                }catch {
                    print("cant delete \(error.localizedDescription)")
                }
            }
        } else {
            print("nothing to do")
        }
        
    }
}

extension MapHomeViewController: NSFetchedResultsControllerDelegate {
}
