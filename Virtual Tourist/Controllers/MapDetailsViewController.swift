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
    var pinLocation: Pin! {
        didSet {
            print("did set locaiton: \(self.pinLocation.latitude) - \(self.pinLocation.longitude)")
        }
        
    }
    var annotation:  MKAnnotation?
    
    var selectedImages: [IndexPath]!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        
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
                deleteImage(at: elemnt)
            }
            
            
            selectedImages.removeAll()
            buttonForAction.setTitle("New Collection", for: .normal)
        }
    }
    
    func handleImagesFromLocation(response: FlickrSearchResponse?, error: Error?) {
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
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
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pinLocation))-notes")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
           
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func deleteImage(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        
        DispatchQueue.main.async {
            self.setupFetchedResultsController()
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

