//
//  XHttpPoolHandle.swift
//  XHttp
//
//  Created by X on 16/3/2.
//  Copyright © 2016年 XHttp. All rights reserved.
//
//  请求结果处理
//


import UIKit
import Foundation

class XHttpPoolHandle: NSObject,NSURLSessionDelegate
{
    static let Share = XHttpPoolHandle.init()
    
    private override init() {
        super.init()
    }

    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        if let request = XHttpPool.Share.getRequestWithTask(dataTask)
        {
            request.reciveData?.appendData(data)
        }
        
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        
        if let request = XHttpPool.Share.getRequestWithTask(dataTask)
        {
            request.reciveData = NSMutableData()
            
            if(XHttpPool.Share.httpWaitIngArr.contains(request))
            {
                XHttpPool.Share.httpWaitIngArr.removeAtIndex(XHttpPool.Share.httpWaitIngArr.indexOf(request)!)
            }
            
            if let httpResponse = response as? NSHTTPURLResponse
            {
                if(httpResponse.respondsToSelector(Selector("allHeaderFields")))
                {
                    let httpResponseHeaderFields:Dictionary = httpResponse.allHeaderFields
                    let dateStr:String!=httpResponseHeaderFields["Date"] as! String
                    let dateFormatter:NSDateFormatter=NSDateFormatter()
                    dateFormatter.locale=NSLocale(localeIdentifier: "en_US")
                    dateFormatter.dateFormat="eee, dd MMM yyyy HH:mm:ss ZZZ"
                    
                    let zone:NSTimeZone=NSTimeZone.systemTimeZone()
                    
                    var serverDate:NSDate=dateFormatter.dateFromString(dateStr)!
                    
                    var interval:NSTimeInterval=NSTimeInterval(zone.secondsFromGMTForDate(serverDate))
                    serverDate = serverDate.dateByAddingTimeInterval(interval)
                    
                    let server:NSTimeInterval=serverDate.timeIntervalSince1970
                    
                    var date:NSDate=NSDate()
                    interval=NSTimeInterval(zone.secondsFromGMTForDate(date))
                    date = date.dateByAddingTimeInterval(interval)
                    
                    let now:NSTimeInterval=date.timeIntervalSince1970
                    XHttpPool.Share.serverTimeInterval=server-now
                    
                }
            }
            
        }
        
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {

        let response = proposedResponse.response
        
        let HTTPResponse = response as? NSHTTPURLResponse
        
        let headers = HTTPResponse!.allHeaderFields
        
        var cachedResponse:NSCachedURLResponse!
        
        if headers["Cache-Control"] != nil
        {
            var modifiedHeaders = headers as! [String:String]
            modifiedHeaders["Cache-Control"] = "max-age=60"
            
            let modifiedResponse = NSHTTPURLResponse(URL: HTTPResponse!.URL!, statusCode: HTTPResponse!.statusCode, HTTPVersion: "HTTP/1.1", headerFields: modifiedHeaders)
            
            cachedResponse = NSCachedURLResponse(response: modifiedResponse!, data: proposedResponse.data , userInfo: proposedResponse.userInfo, storagePolicy: proposedResponse.storagePolicy)
        }
        else
        {
            cachedResponse = proposedResponse
        }
        
        completionHandler(cachedResponse)
        
        
        
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {

    }
    
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

        //认证服务器（这里不使用服务器证书认证，只需地址是我们定义的几个地址即可信任）
        if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodServerTrust
        {
            
            let credential = NSURLCredential(forTrust:
                challenge.protectionSpace.serverTrust!)
            credential.certificates
            completionHandler(.UseCredential, credential)
        }
            
            //认证客户端证书
        else if challenge.protectionSpace.authenticationMethod
            == NSURLAuthenticationMethodClientCertificate
        {
            
        }
            
            // 其它情况（不接受认证）
        else {
            completionHandler(.CancelAuthenticationChallenge, nil);
        }
        
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if let request = XHttpPool.Share.getRequestWithTask(task)
        {
            request.removeTask()
            request.success()
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        if let request = XHttpPool.Share.getRequestWithTask(task)
        {
            if(request.flag<0)
            {
               request.progress(CGFloat(totalBytesSent)/CGFloat(totalBytesExpectedToSend)*CGFloat(100.0))
            }
        }
        
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
    }
    
    
}
