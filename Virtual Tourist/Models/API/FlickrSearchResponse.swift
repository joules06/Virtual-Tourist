//
//  FlickrSearchResponse.swift
//  Virtual Tourist
//
//  Created by Julio Rico on 8/30/19.
//  Copyright © 2019 Julio Rico. All rights reserved.
//

import Foundation

struct FlickrSearchResponse: Codable {
    let photos: PhotosFlickr
    let stat: String
}

// MARK: - Photos
struct PhotosFlickr: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [Photo]
}

// MARK: - Photo
struct Photo: Codable {
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
}
