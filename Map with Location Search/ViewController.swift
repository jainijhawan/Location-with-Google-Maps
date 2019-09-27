//
//  ViewController.swift
//  Map with Location Search
//
//  Created by Jai Nijhawan on 24/09/19.
//  Copyright © 2019 Jai Nijhawan. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet weak var resultsTableView: UITableView!
  @IBOutlet weak var placeholderView: UIView!
  @IBOutlet weak var fixdenPinName: UILabel!
  @IBOutlet weak var customTextField: UITextField!
  @IBOutlet weak var myMapView: GMSMapView!
  @IBOutlet weak var clearBtn: UIButton!
  
  // MARK: - Variables
  var dataArray = [InternalResults]()
  var locationNames = [String]()
  var currentLocationName: String?
  var searchURL = ""
  var detailsURL = ""
  var placeID = [String]()
  var lat: Double?
  var lng: Double?
  var drag = false
  
  // MARK: - LifeCycle Functions
  override func viewDidLoad() {
    super.viewDidLoad()
    resultsTableView.delegate = self
    resultsTableView.dataSource = self
    customTextField.delegate = self
    customTextField.addTarget(self,
                              action: #selector(textFieldDidChange(textField:)),
                              for: .editingChanged)
    myMapView.delegate = self
    setupUI()
  }
  
  // MARK: - IBActions
  @IBAction func clearBtnPressed(_ sender: Any) {
    customTextField.text = ""
  }
  
  // MARK: - Custom Methods
  func setupUI() {
    customTextField.layer.cornerRadius = 10
    customTextField.layer.borderWidth = 1
    customTextField.layer.borderColor = #colorLiteral(red: 0.3960784314, green: 0.368627451, blue: 0.4784313725, alpha: 1)
    clearBtn.isHidden = true
    
    let camera = GMSCameraPosition(latitude: -33.86, longitude: 151.20, zoom: 12.0)
    myMapView.camera = camera
    myMapView.mapStyle(withFilename: "dark", andType: "json")
    myMapView.isMyLocationEnabled = true
    clearBtn.isHidden = true
  }
  
  func changeCameraPosition(lat: Double, lng: Double) {
    let camera = GMSCameraPosition(latitude: lat, longitude: lng, zoom: 12.0)
    let update = GMSCameraUpdate.setCamera(camera)
    myMapView.animate(with: update)
  }
  
  func callDetailsAPI(id: String) {
    detailsURL = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(id)&fields=geometry&key=API-KEY"
    print(detailsURL)
    
    if let url = URL(string: self.detailsURL) {
      if let data = try? Data(contentsOf: url) {
        print(data)
        if let x = try? JSONSerialization.jsonObject(with: data, options: []) {
          print(x)
        }
        let decoder = JSONDecoder()
        if let jsonData = try? decoder.decode(FirstDetailsResults.self, from: data) {
          self.lat = jsonData.result.geometry.location.lat
          self.lng = jsonData.result.geometry.location.lng
          self.changeCameraPosition(lat: self.lat!, lng: self.lng!)
        }
      }
    }
  }
  
  @objc func dataHandeling() {
    DispatchQueue.global(qos: .background).async {
      if let url = URL(string: self.searchURL) {
        if let data = try? Data(contentsOf: url) {
          print(data)
          if let x = try? JSONSerialization.jsonObject(with: data, options: []) {
            print(x)
          }
          self.parseSearchData(json: data)
        }
      }
    }
  }
  
  func parseSearchData(json: Data) {
    let decoder = JSONDecoder()
    locationNames.removeAll()
    placeID.removeAll()
    if let jsonData = try? decoder.decode(FirstResults.self, from: json) {
      dataArray = jsonData.predictions
      print(dataArray.count)
      for i in 0..<dataArray.count {
        locationNames.append(dataArray[i].description)
        placeID.append(dataArray[i].place_id)
        print(locationNames[i])
      }
      DispatchQueue.main.async {
        self.resultsTableView.reloadData()
      }
    }
  }
  
  @objc func textFieldDidChange(textField: UITextField) {
    let x = textField.text?.trimmingCharacters(in: .whitespaces)
    searchURL = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(x!)&types=(cities)&key=API-KEY"
    
    NSObject.cancelPreviousPerformRequests(
      withTarget: self)
    
    self.perform(
      #selector(ViewController.dataHandeling),
      with: nil,
      afterDelay: 1.5)
    print(searchURL)
  }
}

// MARK: - TableView Delegate Extention
extension ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return locationNames.count
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "myCell") as! ResultsCell
    cell.ResultsText.text = locationNames[indexPath.row]
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    customTextField.resignFirstResponder()
    resultsTableView.alpha = 0
    placeholderView.isHidden = false
    customTextField.text = ""
    clearBtn.isHidden = true
    
    callDetailsAPI(id: placeID[indexPath.row])
    print(locationNames)
  }
}

// MARK: - TextField Delegate Extention
extension ViewController: UITextFieldDelegate {
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    locationNames.removeAll()
    resultsTableView.reloadData()
    placeholderView.isHidden = true
    resultsTableView.alpha = 1
    textField.text = ""
    clearBtn.isHidden = false
  }
}

// MARK: - MapView Delegate Extention
extension ViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
    drag = true
  }
  
  func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
    if drag {
      let lat = position.target.latitude
      let lon = position.target.longitude
      print(lat , lon)
      let geoCoder = GMSGeocoder()
      geoCoder.reverseGeocodeCoordinate(CLLocationCoordinate2D(latitude: lat,
                                                               longitude: lon)) { (response, error) in
        if response?.firstResult()?.locality == nil {
            self.fixdenPinName.text = response?.firstResult()?.administrativeArea
          } else {
        self.fixdenPinName.text = response?.firstResult()?.locality
                                                                }
      }
    }
  }
}

// MARK: - MapView Extention
extension GMSMapView {
  func mapStyle(withFilename name: String, andType type: String) {
    do {
      if let styleURL = Bundle.main.url(forResource: name, withExtension: type) {
        self.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
      } else {
        NSLog("Unable to find style.json")
      }
    } catch {
      NSLog("One or more of the map styles failed to load. \(error)")
    }
  }
}
