//
//  MapDetailsViewController.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/31/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//
import MapKit
import SDWebImage
import UIKit


class MapDetailsViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataController: DataController!
    var annotation:  MKAnnotation?
    var images = ["icon_addpin", "icon_back-arrow"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        
        VirtualTouristAPI.requestImagesFromLocatoin(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude, completionHandler: handleImagesFromLocation(response:error:))
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
    }
    
    func handleImagesFromLocation(response: FlickrSearchResponse?, error: Error?) {
        guard let response = response else {
            return
        }
        
        images.removeAll()
        
        for photo in response.photos.photo {
            //imageForPoster.sd_setImage(with: URL(string: safeURLForCover), placeholderImage: UIImage(named: placeHolderHorizontal))
            print("url value \(VirtualTouristAPI.EndPoint.imageURL(photo.farm, photo.server, photo.id, photo.secret).stringValue)")
            images.append(VirtualTouristAPI.EndPoint.imageURL(photo.farm, photo.server, photo.id, photo.secret).stringValue)
        }
        DispatchQueue.main.async {
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
   
}

extension MapDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellForImages", for: indexPath) as! ImagesCollectionViewCell
        let imageName = images[indexPath.row]
        
        cell.flickrImage.image = UIImage(named: imageName)
        cell.flickrImage.sd_setImage(with: URL(string: imageName), placeholderImage: UIImage(named: "icon_addpin"))
        
        return cell
        
    }
    
}

