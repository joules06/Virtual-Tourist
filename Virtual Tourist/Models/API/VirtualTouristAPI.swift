//
//  VirtualTouristAPI.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/29/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//

import Foundation

class VirtualTouristAPI {
    static let apiKey = "fd0964d603a11dd7c592fa5abf2572e8"
    static let authToken = "72157710594390937-41c61e4d0ed01995"
    static let apiSig = "4d562b73331e7cf59598e52fddfcf69c"
    static let baseURLForSearch = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
    
    enum EndPoint {
        case searchImagesForLocation(Double, Double)
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
        
        var stringValue: String {
            switch self {
            case .searchImagesForLocation(let lat, let lon):
                return "\(baseURLForSearch)&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&format=json&nojsoncallback=1&auth_token=\(authToken)&api_sig=\(apiSig)"
            }
        }
        
    }
    
    
    static func requestImagesFromLocatoin(lat: Double, lon: Double, completionHandler: @escaping (FlickrSearchResponse?, Error?) -> Void) {
        let searchEndPoint = VirtualTouristAPI.EndPoint.searchImagesForLocation(lat, lon).url
        
//        SVProgressHUD.show()
        
        let task = URLSession.shared.dataTask(with: searchEndPoint) { (data, response, error) in
//            SVProgressHUD.dismiss()
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
            }
        }
        task.resume()
    }
    
}
