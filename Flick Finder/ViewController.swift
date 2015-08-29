//
//  ViewController.swift
//  Flick Finder
//
//  Created by Sarah Howe on 8/11/15.
//  Copyright (c) 2015 SarahHowe. All rights reserved.
//

import UIKit
import Foundation

/* Define constants */
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "220d9db60b6326d5a7b7e947a01cbe64"
let SAFE_SEARCH = "1"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

let MAX_TOTAL_PAGES = 40

let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0

extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var resultsImageView: UIImageView!
    @IBOutlet weak var resultsTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var lattitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var backgroundLabel: UILabel!
    
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latLonSearchButton: UIButton!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    let latLonDelegate = LatLonTextDelegate()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //initialize tap recognizer
        tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleSingleTap:"))
        tapRecognizer!.numberOfTapsRequired = 1
        
        //set text field delegates
        lattitudeTextField.delegate = latLonDelegate
        longitudeTextField.delegate = latLonDelegate
        phraseTextField.delegate = self
        
        //set initial search state
        phraseTextField.hidden = false
        phraseSearchButton.hidden = false
        lattitudeTextField.hidden = true
        longitudeTextField.hidden = true
        latLonSearchButton.hidden = true
        latitudeLabel.hidden = true
        longitudeLabel.hidden = true
    }

    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //add the tap recognizer and subscribe to keyboard notifications
        addKeyboardDismissRecognizer()
        subscribeToKeyboardNotifications()
        
        phraseTextField.text = ""
        phraseSearchButton.enabled = false
        lattitudeTextField.text = ""
        longitudeTextField.text = ""
        latLonSearchButton.enabled = false
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        //remove the tap recognizer and unsubscribe to keyboard notifications
        removeKeyboardDismissRecognizer()
        unsubscribeFromKeyboardNotifications()
    }
    
    @IBAction func searchTypeSwitch(sender: UISegmentedControl)
    {
        if(sender.selectedSegmentIndex == 0)
        {
            //show phrase stuff
            phraseTextField.hidden = false
            phraseSearchButton.hidden = false
            
            //hide lat/long stuff
            lattitudeTextField.hidden = true
            longitudeTextField.hidden = true
            latLonSearchButton.hidden = true
            latitudeLabel.hidden = true
            longitudeLabel.hidden = true
        }
        else
        {
            //show lat/lon stuff
            lattitudeTextField.hidden = false
            longitudeTextField.hidden = false
            latLonSearchButton.hidden = false
            latitudeLabel.hidden = false
            longitudeLabel.hidden = false
            
            //hide phrase stuff
            phraseTextField.hidden = true
            phraseSearchButton.hidden = true
            
        }
    }
    
    @IBAction func textFieldChanged(sender: UITextField)
    {
        if (sender.placeholder == "Enter Longitude" || sender.placeholder == "Enter Latitude")
        {
            if (lattitudeTextField.text.isEmpty || longitudeTextField.text.isEmpty)
            {
                latLonSearchButton.enabled = false
            }
            else
            {
                latLonSearchButton.enabled = true
            }
        }
        else
        {
            if (sender.text.isEmpty)
            {
                phraseSearchButton.enabled = false
            }
            else
            {
                phraseSearchButton.enabled = true
            }
        }
    }
    
    @IBAction func searchByPhrase(sender: AnyObject)
    {
        //hide keyboard after searching
        dismissAnyVisibleKeyboards()
        
        resultsTitleLabel.text = "Searching..."
        
        //set method arguments
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": phraseTextField.text,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        getImageFromFlickrBySearch(methodArguments)
    }
    
    @IBAction func searchByLatLon(sender: AnyObject)
    {
        //hide keyboard after searching
        dismissAnyVisibleKeyboards()
        
        
        let validLat = validLatitude()
        let validLon = validLongitude()
        
        if (validLat && validLon)
        {
            resultsTitleLabel.text = "Searching..."
            
            //set method arguments
            let methodArguments = [
                "method": METHOD_NAME,
                "api_key": API_KEY,
                "bbox": createBoundingBoxString(),
                "extras": EXTRAS,
                "format": DATA_FORMAT,
                "nojsoncallback": NO_JSON_CALLBACK
            ]
            
            getImageFromFlickrBySearch(methodArguments)
        }
        else
        {
            if (!validLat && !validLon)
            {
                resultsTitleLabel.text = "Lat/Lon Invalid.\nLat should be [-90, 90].\nLon should be [-180, 180]."
            }
            else if (!validLat)
            {
                resultsTitleLabel.text = "Lat Invalid.\nLat should be [-90, 90]."
            }
            else
            {
                resultsTitleLabel.text = "Lon Invalid.\nLon should be [-180, 180]."
            }
        }
    }
    
    /* Check to make sure the latitude falls within [-90, 90] */
    func validLatitude() -> Bool
    {
        if let lat : Double? = lattitudeTextField.text.toDouble()
        {
            if (lat < LAT_MIN || lat > LAT_MAX)
            {
                return false
            }
        }
        else
        {
            return false
        }
        
        return true
    }
    
    func validLongitude() -> Bool
    {
        if let lon : Double? = longitudeTextField.text.toDouble()
        {
            if (lon < LON_MIN || lon > LON_MAX)
            {
                return false
            }
        }
        else
        {
            return false
        }
        
        return true
    }
    
    
    /* ====================================================================
     * Functional methods for handling UI problems
     * ==================================================================== */
    
    //Dismiss the Keyboard
    func addKeyboardDismissRecognizer()
    {
        view.addGestureRecognizer(tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer()
    {
        view.removeGestureRecognizer(tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer)
    {
        view.endEditing(true)
    }
    
    //Shifting the keyboard so it does not hide controls
    func subscribeToKeyboardNotifications()
    {
        //subscribe to keyboardWillShow & keyboardWillHide notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications()
    {
        //unsubscribe from keyboardWillShow & keyboardWillHide notifications
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification)
    {
        //shift the view's frame up so that controls are shown
        if resultsImageView.image != nil
        {
            backgroundLabel.alpha = 0.0
        }
        
        view.frame.origin.y = -getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        //shift the view's frame back down so that the view is back to its original placement
        if resultsImageView.image == nil
        {
            backgroundLabel.alpha = 1.0
        }
        
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat
    {
        //get and return the keyboard's height from the notification
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue //of CGRect
        
        return keyboardSize.CGRectValue().height
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        view.endEditing(true)
        
        return true
    }
        
    /* ====================================================================
     * Flickr api methods
     * ==================================================================== */
    
    func createBoundingBoxString() -> String!
    {
        let latitude = (lattitudeTextField.text as NSString).doubleValue
        let longitude = (longitudeTextField.text as NSString).doubleValue
        
        //ensure box is bounded by minimum and maximum allowed values
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_WIDTH, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func getLatLonString() -> String
    {
        let latitude = (lattitudeTextField.text as NSString).doubleValue
        let longitude = (longitudeTextField.text as NSString).doubleValue
        
        return "(\(latitude), \(longitude))"
    }
    
    func getImageFromFlickrBySearch(parameters: [String : String!])
    {
        /* 3 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 4 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError
            {
                println("Could not complete the request \(error)")
            }
            else
            {
                /* 5 - Success! Parse the data */
                var parsingError: NSError? = nil
                let parsedResult: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary
                {
                    if let totalPages = photosDictionary.valueForKey("pages") as? Int
                    {
                        //flickr will only return up to 4000 images (100 per page & 40 page max)
                        let pageLimit = min(totalPages, MAX_TOTAL_PAGES)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(parameters, pageNumber: randomPage)
                    }
                    else
                    {
                        println("nothing matches the pages key")
                    }
                }
                else
                {
                    println("nothing matches the photos key")
                }
            }
        }
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(parameters: [String: String!], pageNumber: Int)
    {
        //add the page to the method's arguments
        var pageNumberString = String(pageNumber)
        var withPageDictionary = parameters
        withPageDictionary["page"] = pageNumberString
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError
            {
                println("Could not complete the request \(error)")
            }
            else
            {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary
                {
                    /* Get the total number of photos returned by the search */
                    var totalPhotosVal = 0
                    
                    if let totalPhotos = photosDictionary.valueForKey("total") as? String
                    {
                        totalPhotosVal = totalPhotos.toInt()!
                    }
                    else
                    {
                        println("nothing matches the total key \(photosDictionary)")
                    }
                    
                    if(totalPhotosVal > 0)
                    {
                        if let photoArray = photosDictionary.valueForKey("photo") as? [[String : AnyObject]]
                        {
                            /* Grab a single, random image */
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
                            
                            /* Get the image url and title */
                            let photoTitle = photoDictionary["title"] as? String
                            let imageURLString = photoDictionary["url_m"] as? String
                            let imageURL = NSURL(string: imageURLString!)
                            
                            /* Update the UI on the main thread */
                            if let imageData = NSData(contentsOfURL: imageURL!)
                            {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.resultsImageView.image = UIImage(data: imageData)
                                    self.backgroundLabel.alpha = 0.0
                                    
                                    if (parameters["bbox"] != nil)
                                    {
                                        self.resultsTitleLabel.text = "\(self.getLatLonString()) \(photoTitle!)"
                                    }
                                    else
                                    {
                                        self.resultsTitleLabel.text = photoTitle
                                    }
                                })
                            }
                            else
                            {
                                println("Image does not exist at \(imageURLString)")
                            }
                        }
                        else
                        {
                            println("nothing matches the photo key")
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.resultsTitleLabel.text = "We can't find any images to match your search!"
                            self.resultsImageView.image = nil
                            self.backgroundLabel.alpha = 1.0
                        })
                    }
                }
                else
                {
                    println("nothing matches the photos key w/page")
                }
            }
        }
        
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : String!]) -> String
    {
        var queryItems = map(parameters) { NSURLQueryItem(name: $0, value: $1) }
        var components = NSURLComponents()
        
        components.queryItems = queryItems
        return ("?" + components.percentEncodedQuery!) ?? ""
    }
    
}

extension ViewController {
    func dismissAnyVisibleKeyboards()
    {
        if (phraseTextField.isFirstResponder() || lattitudeTextField.isFirstResponder() || longitudeTextField.isFirstResponder())
        {
            view.endEditing(true)
        }
    }
}

