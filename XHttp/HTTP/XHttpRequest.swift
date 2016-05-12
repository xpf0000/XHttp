//
//  HTTPRequest.swift
//  swiftTest
//HTTP异步请求 和 上传文件
//
//
//  Created by X on 15/3/8.
//  Copyright (c) 2015年 swiftTest. All rights reserved.
//
//

import Foundation
import UIKit
import SystemConfiguration


typealias httpBlock = (Dictionary<String,AnyObject>)->Void
typealias JsonBlock = (JSON?)->Void

class XHttpRequest: NSObject,NSURLConnectionDataDelegate{
    
    var task:NSURLSessionDataTask?
    var flag:Int=0
    var url:String=""
    var reciveData:NSMutableData?
    var runing:Bool=false
    
    var progressBlock:ProgressBlock?
    var resultType:HttpResultType = .Dict
    var requestType:HttpRequestType = .Default
    private var request:NSMutableURLRequest?
    var mutableFileName=false
    var httpMethod:HttpMethod = .GET
    lazy var jsonBlockArr:Array<JsonBlock> = []
    lazy var blockArr:Array<httpBlock> = []
    
    func success()->[String:AnyObject]
    {
        var dict:[String:AnyObject]=[:]
        var json:JSON? = nil
        
        autoreleasepool { 
            
            switch self.resultType
            {
            case .Dict:
                
                if(reciveData != nil)
                {
                    let dic:Dictionary<String,AnyObject>?=((try? NSJSONSerialization.JSONObjectWithData(reciveData!, options: NSJSONReadingOptions.MutableLeaves)) as?
                        Dictionary<String,AnyObject>)
                    if(dic != nil)
                    {
                        dict=dic!
                    }
                }
                
            case .Json:
                
                if(reciveData != nil)
                {
                    json = JSON(data: reciveData!)
                }
                
            case .Html:
                
                if(reciveData != nil)
                {
                    dict["HTML"]=NSString(data: reciveData!, encoding: NSUTF8StringEncoding) as! String
                }
                
                
            case .Data:
                
                if(reciveData != nil)
                {
                    dict["DATA"]=NSData(data: reciveData!)
                }
                
            }
            
            dict["HTTPURL"] = self.url
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                for item in self.jsonBlockArr
                {
                    item(json)
                }
                
                for item in self.blockArr
                {
                    item(dict)
                }
                
                self.runing = false
                XHttpPool.Share.remove(self)
                
            })
            
            
            
        }
        
        return dict
    }
    
    func progress(prog:CGFloat)
    {
        self.progressBlock?(prog)
    }
    
    func free()
    {
        jsonBlockArr.removeAll(keepCapacity: false)
        blockArr.removeAll(keepCapacity: false)
    }
    
    func requestDict(url:String,body:AnyObject?,method:HttpMethod,block:httpBlock)->Void
    {
        self.blockArr.append(block)
        request(url, body: body, method: method, flag: 0)
    }
    
    func requestJson(url:String,body:AnyObject?,method:HttpMethod,block:JsonBlock)->Void
    {
        self.jsonBlockArr.append(block)
        self.resultType = .Json
        request(url, body: body, method: method, flag: 0)
    }
    
    private func getPostStr(body:AnyObject)->NSData
    {
        var postStr = ""
        
        if body is String || body is NSString
        {
            postStr = body as! String
        }
        else if body is [String:AnyObject]
        {
            for (key,value) in body as! [String:AnyObject]
            {
                if postStr == ""
                {
                    postStr = "\(key)=\(value)"
                }
                else
                {
                    postStr = postStr+"&\(key)=\(value)"
                }
            }
        }
        else if body is NSDictionary
        {
            for (key,value) in body as! NSDictionary
            {
                if postStr == ""
                {
                    postStr = "\(key)=\(value)"
                }
                else
                {
                    postStr = postStr+"&\(key)=\(value)"
                }
            }
            
        }
        else if body is Reflect
        {
            let dict = (body as! Reflect).toDict()
            
            for (key,value) in dict
            {
                if postStr == ""
                {
                    postStr = "\(key)=\(value)"
                }
                else
                {
                    postStr = postStr+"&\(key)=\(value)"
                }
            }
            
        }
        else
        {
            postStr = "\(body)"
        }
        
        return postStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        
    }
    
    func synchForJson(url:String,body:AnyObject?,method:HttpMethod)->JSON?
    {
        let data = synchRequest(url, body: body, method: method)
        
        runing = false
        self.free()
        XHttpPool.Share.remove(self)
        
        return data == nil ? nil : JSON(data: data!)
    }
    
    func synchForDict(url:String,body:AnyObject?,method:HttpMethod)->[String:AnyObject]
    {
        if let data = synchRequest(url, body: body, method: method)
        {
            self.reciveData = NSMutableData(data: data)
        }
        
        return success()
    }
    
    func synchRequest(url:String,body:AnyObject?,method:HttpMethod)->NSData?
    {
        self.url = url
        runing = true
        let str = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        if str == nil {runing = false;return nil}

        var data:NSData?
        
        if let requestURL = NSURL(string: str!)
        {
            var request:NSMutableURLRequest?
            
            request=NSMutableURLRequest(URL: requestURL, cachePolicy:NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)
            
            request?.HTTPMethod=method.rawValue
            
            if(body != nil)
            {
                request?.HTTPBody=getPostStr(body!)
            }
            
            let semaphore = dispatch_semaphore_create(0)
            
            
            XHttpPool.Share.session.dataTaskWithRequest(request!, completionHandler: { (d, response, error) -> Void in
                
                data = d
                
                dispatch_semaphore_signal(semaphore)
            }).resume()
            
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            
        }
        
        
        return data
        
    }
    
    func request(url:String,body:AnyObject?,method:HttpMethod,flag:Int)->Void
    {
        if(runing)
        {
            return
        }
        
        if(request != nil)
        {
            self.startTask()
            return
        }
        
        self.httpMethod = method
        self.flag=flag
        self.url=url
        
        let u = self.url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        if u == nil {success(); return}
        
        let requestURL:NSURL=NSURL(string: u!)!

        request = NSMutableURLRequest(URL: requestURL)
        
        request?.addValue(requestType.rawValue, forHTTPHeaderField: "Content-Type")
        request?.timeoutInterval = 30.0
        request?.HTTPMethod=method.rawValue
        
        if(body != nil)
        {
            request?.HTTPBody=getPostStr(body!)
        }
        
        self.startTask()
    }
    
    func startTask()
    {
        if(self.runing){return}
        runing=true
        
        self.task = XHttpPool.Share.session.dataTaskWithRequest(self.request!)
        
        self.task?.resume()
    }
    
    func removeTask()
    {
        self.task?.cancel()
        self.task = nil
    }
    
    
    //上传文件用  dict：键值对字段  fileArr：文件绝对路径 可上传多个 URL：上传链接 name：上传时要求的文件标识名称
    
    func uploadFile(dict:Dictionary<String,AnyObject>,fileArr:Array<NSData>?,URL:String,name:String,progress: ProgressBlock?,result:JsonBlock)->Void
    {
        self.httpMethod = .POST
        self.resultType = .Json
        self.progressBlock = progress
        self.jsonBlockArr.append(result)
        
        self.uploadFile(dict, fileArr: fileArr, URL: URL, name: name)
    }
    
    
    func uploadFile(dict:Dictionary<String,AnyObject>,fileArr:Array<NSData>?,URL:String,name:String)->Void
    {
        if(runing){return}
        
        if(request != nil)
        {
            self.startTask()
            return
        }
        
        self.flag = -1
        request=NSMutableURLRequest()
        request!.URL=NSURL(string:URL)
        request!.HTTPMethod="POST"
        
        let boundary:String="ARCFormBoundaryu17kx742j3sdcxr"
        let contentType:String=("multipart/form-data; boundary="+boundary).stringByRemovingPercentEncoding!
        request!.addValue(contentType, forHTTPHeaderField: "Content-Type")
        
        let body=NSMutableData()
        body.appendData(("\r\n--\(boundary)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
        
        var i = 1
        for (key, value) in dict {
            body.appendData(("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData(("\(value)").dataUsingEncoding(NSUTF8StringEncoding)!)
            
            if fileArr == nil && i==dict.count
            {
                body.appendData(("\r\n--\(boundary)--\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            else
            {
                body.appendData(("\r\n--\(boundary)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            
            i += 1
        }
        
        if fileArr != nil
        {
            if(fileArr!.count>0)
            {
                var i=0
                for data in fileArr!
                {
                    var tempName=name
                    if(mutableFileName)
                    {
                        tempName += "\(i)"
                    }
                    
                    let filename:String="test.jpg"
                    body.appendData(("Content-Disposition: form-data; name=\"\(tempName)\"; filename=\"\(filename)\"\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                    body.appendData(("Content-Type: image/jpeg\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                    body.appendData(data)
                    if(i<fileArr!.count-1)
                    {
                        body.appendData(("\r\n--\(boundary)\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                    }
                    else
                    {
                        body.appendData(("\r\n--\(boundary)--\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                    }
                    i += 1
                }
            }
            else
            {
                body.appendData(("Content-Disposition: form-data; name=\"\(name)\";filename=\"\"\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData(("Content-Type: image/jpeg\r\n\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
                body.appendData(("\r\n--\(boundary)--\r\n").dataUsingEncoding(NSUTF8StringEncoding)!)
            }
        }

        request!.HTTPBody=body
        
        self.startTask()
        
    }
    
    deinit
    {
        jsonBlockArr.removeAll(keepCapacity: false)
        blockArr.removeAll(keepCapacity: false)
        task?.cancel()
        task = nil
        request = nil
        progressBlock = nil
        reciveData=nil
    }
    
}