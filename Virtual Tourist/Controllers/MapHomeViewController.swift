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
    var locationSaved: Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        populateMap()
        
        usersLastMapLocation()


        addButtonForNavigation()
    }
    
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        var canSave = false
        
        // Create a basic point annotation and add it to the map
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        let uuid = UUID()
        
        
        mapView.addAnnotation(annotation)
        
        if let pines = try? fetchPinesWith(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) {
            canSave = pines.count == 0
        }else {
            canSave = true
        }
        
        if canSave {
            addPin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, uuid: uuid.uuidString)
        }
        
    }
    
    fileprivate func addButtonForNavigation() {
        let editBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditSelector))
        navigationItem.rightBarButtonItem = editBarButtonItem
        setEditing(false, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMapDetails" {
            let destinationVC = segue.destination as! MapDetailsViewController
            let annotation = sender as?  MKAnnotation

            if let locations = try? fetchPinesWith(latitude: annotation?.coordinate.latitude ?? 0, longitude: annotation?.coordinate.longitude ?? 0),

                let first = locations.first {
                locationSaved = first
            }

            destinationVC.pinLocation = locationSaved
            print("origin location: \(locationSaved.objectID) - lat: \(locationSaved.latitude) - long: \(locationSaved.longitude)")
            
            destinationVC.annotation = annotation
            destinationVC.dataController = dataController
        }
    }
    
    //MARK: - Core Data functions
    fileprivate func addPin(latitude: Double, longitude: Double, uuid: String) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()
        pin.uuid = uuid
        pin.page = 1
        try? dataController.viewContext.save()
        
        locationSaved = pin
        
        //dowload images and save it
        VirtualTouristAPI.requestImagesFromLocation(lat: pin.latitude, lon: pin.longitude, page: 1, completionHandler: handleImagesFromLocation(response:error:))
        
    }
    
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
    
    fileprivate func fetchPinesWith(latitude: Double, longitude: Double) throws -> [Pin] {
        let request = NSFetchRequest<Pin>(entityName: "Pin")
        request.predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", latitude, longitude)
        
        return  try self.dataController.viewContext.fetch(request)
    }
    
    fileprivate func fetchImages(pin: Pin) throws -> [Photos] {
        let request = NSFetchRequest<Photos>(entityName: "Photos")
        request.predicate = NSPredicate(format: "pinLocations == %@", pin)
        
        return  try self.dataController.viewContext.fetch(request)
    }
    
    //MARK: - Functions to populate map
    
    fileprivate func populateMap() {
        if let pines = try? fetchPines() {
            for element in pines {
                let coordinate = CLLocationCoordinate2D(latitude: element.latitude, longitude: element.longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    fileprivate func usersLastMapLocation() {
        guard let defaults = UserDefaults.standard.dictionary(forKey: "location") as? [String:Double] else {
            return
        }

        if  let lat = defaults["lat"],
            let long = defaults["long"],
            let latDelta = defaults["latDelta"],
            let longDelta = defaults["longDelta"]
            
        {
            let center: CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
            let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            let region: MKCoordinateRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    //MARK: - API
    func handleImagesFromLocation(response: FlickrSearchResponse?, error: Error?) {
        guard let response = response else {
            return
        }
        for photo in response.photos.photo {
            if !photo.server.isEmpty && !photo.id.isEmpty && !photo.secret.isEmpty {
                VirtualTouristAPI.getData(from: VirtualTouristAPI.EndPoint.imageURL(photo.farm, photo.server, photo.id, photo.secret).url, completion: handleImageDownloaded(data:response:error:))
                
            }
        }
        
    }
    
    
    func handleImageDownloaded(data: Data?, response: URLResponse?, error: Error?) {
        DispatchQueue.main.async {
            guard let data = data else {
                return
            }
            let photoToSave = Photos(context: self.dataController.viewContext)
            photoToSave.pinLocations = self.locationSaved
            
            photoToSave.creationDate = Date()
            photoToSave.image = data

            try? self.dataController.viewContext.save()
        }
        
        print("urls saved")
    }
    
    //MARK: - Buttons and actions
   
    @objc func toggleEditSelector(_ sender: UIBarButtonItem) {
        editEnable.toggle()
        
        self.labelForIndication.isHidden = !self.editEnable
        
        guard let systemItem = sender.value(forKey: "systemItem") as? Int else {
            return
        }
        
        switch systemItem {
        case UIBarButtonItem.SystemItem.edit.rawValue:
            let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleEditSelector))
            doneBarButtonItem.style = .plain
            navigationItem.rightBarButtonItem = doneBarButtonItem
            setEditing(true, animated: true)
        case UIBarButtonItem.SystemItem.done.rawValue:
            let editBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleEditSelector))
            navigationItem.rightBarButtonItem = editBarButtonItem
            setEditing(false, animated: true)
        default:
            break
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
        if let annotation = view.annotation {
           
            if editEnable {

                guard let annotation = mapView.annotations.first else {
                    return
                }
                
                guard let pines = try? fetchPinesWith(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude) else {
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
            } else {
                performSegue(withIdentifier: "goToMapDetails", sender: annotation)
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let defaults = UserDefaults.standard
        let locationData = ["lat":mapView.centerCoordinate.latitude
            , "long":mapView.centerCoordinate.longitude
            , "latDelta":mapView.region.span.latitudeDelta
            , "longDelta":mapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "location")
    }

}

extension MapHomeViewController: NSFetchedResultsControllerDelegate {
}
