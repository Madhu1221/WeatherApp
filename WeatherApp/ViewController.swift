//
//  ViewController.swift
//  WeatherApp
//
//  Created by Madhu on 1/2/18.
//  Copyright © 2018 Madhu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UISearchBarDelegate {
    
    let API_KEY = "83a5ec7b2c84e1c7126140e54ca76c60"
    let config = URLSessionConfiguration.default
    let session = URLSession.shared

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherTitle: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var weatherQuantity: UILabel!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var dateAndTime: UILabel!
    @IBOutlet weak var windLbl: UILabel!
    @IBOutlet weak var windValue: UILabel!
    @IBOutlet weak var cloudinessValue: UILabel!
    @IBOutlet weak var pressureValue: UILabel!
    @IBOutlet weak var humidityValue: UILabel!
    @IBOutlet weak var sunriseValue: UILabel!
    @IBOutlet weak var sunsetValue: UILabel!
    @IBOutlet weak var geolocaitonValue: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.hideUIElements()
        
        //Load previously loaded city weather details if applicable
        if let city = UserDefaults.standard.value(forKey: "PREV_LOCATION") as? String{
            self.searchBar.text = city
            self.searchBarSearchButtonClicked(self.searchBar)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Openweather API call to get data
    func getWeatherData(urlRequest:URL){
        
        //Show spinner
        self.spinner.startAnimating()
        
        let task = session.dataTask(with:urlRequest) {
            (data, response, error) in
            // check for any errors
            if let error = error {
                print("error calling GET on api.openweathermap.org")
                print(error)
                return
            }
            // make sure we got data
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            // parse the result as JSON, since that's what the API provides
            do {
                guard let weatherInfo = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                    print("error trying to convert data to JSON")
                    return
                }
                
                //Update UI
                DispatchQueue.main.async {
                    self.refreshUI(withDataDictionary: weatherInfo)
                }
                
            } catch  {
                print("error trying to convert data to JSON")
                return
            }
        }
        task.resume()
    }

    //Update UI with weather data recieved
    func refreshUI(withDataDictionary dict:[String:Any]){
        //Set weather location details
        if let name = dict["name"]{
            self.weatherTitle.text = "Weather in \(name), US"
            UserDefaults.standard.set(name, forKey: "PREV_LOCATION")
            UserDefaults.standard.synchronize()
        }
        
        //Set icon and weather quantity
        if let weatherArray = dict["weather"] as? [[String:Any]], let weather = weatherArray.first{
            
            
            //Main description
            if let main = weather["main"] as? String{
                self.desc.text = main
            }

            //Cloudiness description
            if let desc = weather["description"] as? String{
                self.cloudinessValue.text = desc
            }
            
            //icon image
            if let icon = weather["icon"] as? String{
                self.imageFromServerURL(urlString: "http://openweathermap.org/img/w/\(icon).png")
            }
        }
        
        if let mainDict = dict["main"] as? [String:Any]{
            if let temp = mainDict["temp"] as? Double{
                self.weatherQuantity.text = String(format: "%.0f", temp - 273.15) + "°C"
            }

            //pressure
            if let pressure = mainDict["pressure"] as? Double{
                self.pressureValue.text = "\(pressure)"
            }

            //humidity
            if let humidity = mainDict["humidity"] as? Double{
                self.humidityValue.text = "\(humidity)"
            }

            //humidity
            if let humidity = mainDict["humidity"] as? Double{
                self.humidityValue.text = "\(humidity)"
            }
        }
        
        //Date & Time
        let df = DateFormatter()
        if let timeIntvl = dict["dt"] as? TimeInterval{
            df.dateFormat = "HH:mm MMM dd"
            self.dateAndTime.text = df.string(from: Date(timeIntervalSince1970: timeIntvl))
        }
        
        //Wind
        if let windDict = dict["wind"] as? [String:Any]{
            if let speed = windDict["speed"] as? Double, let degrees = windDict["deg"] as? Double{
                self.windValue.text = "Speed: \(speed) m/s; (\(degrees))"
            }
        }
        
        //sunrise, sunset
        if let sysDict = dict["sys"] as? [String:Any]{
            if let sunrise = sysDict["sunrise"] as? TimeInterval, let sunset = sysDict["sunset"] as? TimeInterval{
                df.dateFormat = "HH:mm"
                let sunriseStr = df.string(from: Date(timeIntervalSince1970: sunrise))
                self.sunriseValue.text = sunriseStr
                let sunsetStr = df.string(from: Date(timeIntervalSince1970: sunset))
                    self.sunsetValue.text = sunsetStr

            }
        }
        
        //Geo coords
        if let coordDict = dict["coord"] as? [String:Any]{
            if let lat = coordDict["lat"] as? Double, let lon = coordDict["lon"] as? Double{
                self.geolocaitonValue.text = "[\(lat), \(lon)]"
            }
            
        }
        
        //show UI elements if hidden
        if self.weatherTitle.isHidden{
            self.showUIElements()
        }
        
        //Show spinner
        self.spinner.stopAnimating()

    }
    
    //Searchbar delegate methods
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        
        if let cityNameStr = searchBar.text{
            if cityNameStr != "" {
                var urlRequestStr = "http://api.openweathermap.org/data/2.5/weather?q=\(cityNameStr)&appid=\(API_KEY)"
                //Make call only if URL is valid
                urlRequestStr =  urlRequestStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                if let urlRequest = URL(string: urlRequestStr){
                    self.getWeatherData(urlRequest:urlRequest)
                }
            }
        }

    }
    
    //Download image asynchrounously
    func imageFromServerURL(urlString: String) {
        
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            if let data = data {
                DispatchQueue.main.async(execute: { [weak self]() -> Void in
                    let image = UIImage(data: data)
                    self?.iconImageView.image = image
                })
            }
        }).resume()
    }
    
    func hideUIElements(){
        self.weatherTitle.isHidden = true
        self.iconImageView.isHidden = true
        self.weatherQuantity.isHidden = true
        self.desc.isHidden = true
        self.dateAndTime.isHidden = true
        self.windLbl.isHidden = true
        self.windValue.isHidden = true
        self.cloudinessValue.isHidden = true
        self.pressureValue.isHidden = true
        self.humidityValue.isHidden = true
        self.sunriseValue.isHidden = true
        self.sunsetValue.isHidden = true
        self.geolocaitonValue.isHidden = true
        self.containerView.isHidden = true
    }

    func showUIElements(){
        self.weatherTitle.isHidden = false
        self.iconImageView.isHidden = false
        self.weatherQuantity.isHidden = false
        self.desc.isHidden = false
        self.dateAndTime.isHidden = false
        self.windLbl.isHidden = false
        self.windValue.isHidden = false
        self.cloudinessValue.isHidden = false
        self.pressureValue.isHidden = false
        self.humidityValue.isHidden = false
        self.sunriseValue.isHidden = false
        self.sunsetValue.isHidden = false
        self.geolocaitonValue.isHidden = false
        self.containerView.isHidden = false
    }

}

