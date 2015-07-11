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
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "screenshotCaptured:",
            name: NSMetadataQueryDidUpdateNotification,
            object: nil)
        
        query.delegate = self
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1", argumentArray: nil)
        query.startQuery()
    }
    
    @objc func screenshotCaptured(notification: NSNotification){
        
        if query.resultCount > 0
        {
            // Get the latest screenshot
            var lastQueryResult = query.resultAtIndex(query.resultCount - 1) as! NSMetadataItem
            let imagePath = lastQueryResult.valueForAttribute("kMDItemPath") as! String
            var imageUrl = NSURL(fileURLWithPath: imagePath)
            var image = NSImage(byReferencingURL: imageUrl!)
            
            // Convert the image to a base64 string
            var data: NSData = image.TIFFRepresentation!
            var bitmap: NSBitmapImageRep = NSBitmapImageRep(data: data)!
            data = bitmap.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
            var base64String : NSString = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
            
            // Send it to Imgur and retrieve url
            let request = NSMutableURLRequest(URL: NSURL(string: "https://api.imgur.com/3/image")!)
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(["image": base64String], options: nil, error: nil)
            request.HTTPMethod = "POST"
            request.allHTTPHeaderFields = [
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": "CLIENT-ID SET_API_KEY_HERE"
            ]
            
            Alamofire.request(request)
                .responseJSON { (request, response, JSON, error) in
                    
                    var notificationTitle = "Upload failed"
                    var notificationContent = "An error occurred"
                    if error == nil{
                        notificationTitle = "Upload complete"
                        notificationContent = "URL copied to clipboard"
                        
                        let resultJson = JSON?.valueForKey("data") as! NSDictionary
                        let imageRemoteLink = resultJson.valueForKey("link") as! String
                        
                        // Copy url to clipboard
                        NSPasteboard.generalPasteboard().clearContents()
                        NSPasteboard.generalPasteboard().setString(imageRemoteLink, forType: NSStringPboardType)
                    }
                    
                    // Display notification
                    // todo action to view the image
                    let notification = NSUserNotification()
                    notification.title = notificationTitle
                    notification.informativeText = notificationContent
                    notification.deliveryDate = NSDate(timeIntervalSinceNow: 0)
                    NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification)
                    
            }
        }
    }
}

