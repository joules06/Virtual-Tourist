//
//  MapDetailsViewController.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/31/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//
import CoreData
import MapKit
import SDWebImage
import UIKit


class MapDetailsViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonForAction: UIButton!
    var fetchedResultsController:NSFetchedResultsController<Photos>!

    var dataController: DataController!
    var pinLocation: Pin!
    var annotation:  MKAnnotation?
    
    var selectedImages: [IndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        
        setUpMap()

        collectionView.delegate = self
        collectionView.dataSource = self
        
        selectedImages = [IndexPath]()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        fetchedResultsController = nil
    }
    
    @IBAction func buttonForActionTapped(_ sender: UIButton) {
        if selectedImages.count > 0 {
            
            for elemnt in selectedImages {
                deletePhoto(at: elemnt)
            }

            selectedImages.removeAll()
            buttonForAction.setTitle("New Collection", for: .normal)
        } else {
            //remove all images and donwload new ones
            if let allPhotos = try? fetchPhotos() {
                for photo in allPhotos {
                    try? delete(photo: photo)
                }
                
                VirtualTouristAPI.requestImagesFromLocation(lat: pinLocation.latitude, lon: pinLocation.longitude, completionHandler: handleImagesFromLocation(response:error:))
                

                selectedImages.removeAll()
                buttonForAction.setTitle("New Collection", for: .normal)
                
            }
        }
    }
    
    fileprivate func setUpMap() {
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isScrollEnabled = false
        
        guard let annotation = annotation else {
            return
        }
        
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    //MARK: - Core data functions
    fileprivate func setupFetchedResultsController() {
        //change get pinLocation by locations
        let fetchRequest:NSFetchRequest<Photos> = Photos.fetchRequest()
        //
        let predicate = NSPredicate(format: "pinLocations == %@", pinLocation)
        
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pinLocation)-pinLocations")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
    }
    
    fileprivate func fetchPhotos() throws -> [Photos] {
        let request = NSFetchRequest<Photos>(entityName: "Photos")
        request.predicate = NSPredicate(format: "pinLocations == %@", pinLocation)
        
        return  try self.dataController.viewContext.fetch(request)
    }
    
    func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        
        try? dataController.viewContext.save()
        
        DispatchQueue.main.async {
            self.setupFetchedResultsController()
            self.collectionView.reloadData()
        }
    }
    
    func delete(photo: Photos) throws {
        self.dataController.viewContext.delete(photo)
        try self.dataController.viewContext.save()
    }
    
    func addImage(url: String) {
        let photo = Photos(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.pinLocations = pinLocation
        photo.url = url
        do {
            try dataController.viewContext.save()
        }catch {
            fatalError("couldn save image")
        }
        
        
        
    }
    
    //MARK: - API
    func handleImagesFromLocation(response: FlickrSearchResponse?, error: Error?) {
        DispatchQueue.main.async {
            guard let response = response else {
                return
            }
            for photo in response.photos.photo {
                if !photo.server.isEmpty && !photo.id.isEmpty && !photo.secret.isEmpty {
                    let url  = VirtualTouristAPI.EndPoint.imageURL(photo.farm, photo.server, photo.id, photo.secret).stringValue
                    self.addImage(url: url)
                }
            }
            //retreive al images
            self.fetchedResultsController = nil
            self.setupFetchedResultsController()
            
            //reload images on collection view
            self.collectionView.reloadData()
        }

    }

}

extension MapDetailsViewController: MKMapViewDelegate {
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
}

extension MapDetailsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //deleteImage(at: indexPath)
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        var alphaValue: CGFloat = 0.5
        
        if !selectedImages.contains(indexPath) {
            //add indexpath and mark cell as marked
            selectedImages.append(indexPath)
            
        } else {
            if let index = selectedImages.firstIndex(of: indexPath) {
                selectedImages.remove(at: index)
            }
            alphaValue = 1.0
        }
        
        if let newCell = cell as? ImagesCollectionViewCell {
            newCell.flickrImage.alpha = alphaValue
        }
        
        if selectedImages.count > 0 {
            buttonForAction.setTitle("Remove selected", for: .normal)
        } else {
            buttonForAction.setTitle("New Collection", for: .normal)
        }
       
    }
   
}

extension MapDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print ("objects \(fetchedResultsController.sections?[0].numberOfObjects ?? 0)")
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aImage = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellForImages", for: indexPath) as! ImagesCollectionViewCell
        if let imageName = aImage.url {
 
            cell.flickrImage.sd_setImage(with: URL(string: imageName), placeholderImage: UIImage(named: "icon_addpin"))
            cell.flickrImage.alpha = 1.0
            
        }

        return cell
        
    }
    
}

extension MapDetailsViewController: NSFetchedResultsControllerDelegate {
    
}

