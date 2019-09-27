//
//  DataHandeling.swift
//  Map with Location Search
//
//  Created by Jai Nijhawan on 25/09/19.
//  Copyright © 2019 Jai Nijhawan. All rights reserved.
//

import Foundation

struct FirstResults: Codable {
  var predictions: [InternalResults]
}

struct InternalResults: Codable {
  var description: String
  var place_id: String
}

struct FirstDetailsResults: Codable {
  var result: SecondDetailsResults
}

struct SecondDetailsResults: Codable {
  var geometry: ThirdDetailsResults
}

struct ThirdDetailsResults: Codable {
  var location: FourthDetailsResults
}

struct FourthDetailsResults: Codable {
  var lat: Double
  var lng: Double
}

