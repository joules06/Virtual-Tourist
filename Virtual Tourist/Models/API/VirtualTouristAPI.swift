//
//  VirtualTouristAPI.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/29/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//

import Foundation
import SVProgressHUD

class VirtualTouristAPI {
    static let apiKey = "1b737ae1c787b9a6ab4688ab981b862f"
    
    static let baseURLForSearch = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
    
    enum EndPoint {
        case searchImagesForLocation(Double, Double, Int)
        case imageURL(Int, String, String, String)
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
        
        var stringValue: String {
            switch self {
            case .searchImagesForLocation(let lat, let lon, let page):
                return "\(baseURLForSearch)&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&format=json&nojsoncallback=1&per_page=20&page=\(page)"
                
            case .imageURL(let farmId, let serverId, let id, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
        
    }
    
    
    static func requestImagesFromLocation(lat: Double, lon: Double, page: Int, completionHandler: @escaping (FlickrSearchResponse?, Error?) -> Void) {
        let searchEndPoint = VirtualTouristAPI.EndPoint.searchImagesForLocation(lat, lon, page).url
        print("url for seach: \(searchEndPoint)")
        SVProgressHUD.show()
        
        let task = URLSession.shared.dataTask(with: searchEndPoint) { (data, response, error) in
            SVProgressHUD.dismiss()
            guard let data = data else {
                completionHandler(nil, error)
                
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let imagesFromLocation = try decoder.decode(FlickrSearchResponse.self, from: data)
                completionHandler(imagesFromLocation, nil)
            }catch {
                completionHandler(nil, error)
                print("catch converting \(error)")
            }
        }
        task.resume()
    }
    
    static func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
}
