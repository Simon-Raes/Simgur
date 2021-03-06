//
//  AppDelegate.swift
//  Simgur
//
//  Created by Simon Raes on 09/07/15.
//  Copyright (c) 2015 Simon Raes. All rights reserved.
//

import Cocoa
import Foundation
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMetadataQueryDelegate {
    
    var query = NSMetadataQuery()
    var client_id : String
    
    let statusItem: NSStatusItem = NSStatusBar.systemStatusBar().statusItemWithLength(24)
    
    override init() {
        
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            // Use your dict here
            client_id = "CLIENT-ID " + (dict.objectForKey("Imgur") as! String)
        }
        else
        {
            client_id = "Error"
        }
        
        super.init()

        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: "Status")
//            statusButton.alternateImage = NSImage(named: "StatusHighlighted")

        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "screenshotCaptured:",
            name: NSMetadataQueryDidUpdateNotification,
            object: nil)
        
        query.delegate = self
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1", argumentArray: nil)
        query.startQuery()
        
        // Create menu items for menu bar button
        let menu = NSMenu()
        
        //todo implement
        menu.addItem(NSMenuItem(title: "Automatically upload", action: Selector("toggleAutoUpload:"), keyEquivalent: "a"))
        // todo action to toggle auto delete of local image
        // todo action to open window with history of uploads + their imgur link + delete link if possible
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit Simgur", action: Selector("terminate:"), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func autoUpload(sender: AnyObject){
        
    }
    
    func terminate(sender: AnyObject){
        
    }
    
    @objc func screenshotCaptured(notification: NSNotification){
        
        if query.resultCount > 0
        {
            // Get the latest screenshot
            let lastQueryResult = query.resultAtIndex(query.resultCount - 1) as! NSMetadataItem
            let imagePath = lastQueryResult.valueForAttribute("kMDItemPath") as! String
            let imageUrl = NSURL(fileURLWithPath: imagePath)
            let image = NSImage(byReferencingURL: imageUrl!)
            
            // Convert the image to a base64 string
            let imageTiff: NSData = image.TIFFRepresentation!
            let imageBitmap: NSBitmapImageRep = NSBitmapImageRep(data: imageTiff)!
            let imagePng = imageBitmap.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
            let base64String : NSString = imagePng.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
            
            // Send it to Imgur and retrieve url
            let request = NSMutableURLRequest(URL: NSURL(string: "https://api.imgur.com/3/image")!)
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(["image": base64String], options: nil, error: nil)
            request.HTTPMethod = "POST"
            request.allHTTPHeaderFields = [
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": client_id
            ]
            
            Alamofire.request(request)
                .responseJSON { (request, response, JSON, error) in
                    
                    var notificationTitle = "Upload failed"
                    var notificationContent = "An error occurred"
                    if error == nil{
                        notificationTitle = "Upload complete"
                        notificationContent = "URL copied to clipboard"
                        
                        let resultJson = JSON?.valueForKey("data") as! NSDictionary
                        // todo handle crash when wrong api key is set
                        let imageRemoteLink = resultJson.valueForKey("link") as! String
                        
                        // Copy url to clipboard
                        NSPasteboard.generalPasteboard().clearContents()
                        NSPasteboard.generalPasteboard().setString(imageRemoteLink, forType: NSStringPboardType)
                    }
                    
                    // Display notification
                    // todo action to view the image
                    // todo action to copy to clip board instead of automatically doing it
                    let notification = NSUserNotification()
                    notification.title = notificationTitle
                    notification.informativeText = notificationContent
//                    notification.deliveryDate = NSDate(timeIntervalSinceNow: 0)
                    NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification)
                    
            }
        }
    }
}

