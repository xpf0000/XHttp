//
//  HttpPool.swift
//  swiftTest
//
//  Created by 徐鹏飞 on 15/3/14.
//  Copyright (c) 2015年 swiftTest. All rights reserved.
//  新版网络请求库 全部使用URLSession
//  实现目标:
//  1.无内存泄漏
//  2.节约资源。同一个url。get请求应该同一时间只有一个任务在跑，通过多个block或者代理分发。post等无法通过url区分的待定。
//  3.方便好用，尽量轻量化。智能化。简洁明了。
//  4.扩展性好，低耦合，即插即用。
//
//

import Foundation
import UIKit


enum HttpMethod: String  {
    
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case HEAD = "HEAD"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case OPTIONS = "OPTIONS"
    
}

//返回类型
enum HttpResultType : NSInteger{
    case Dict
    case Json
    case Html
    case Data
}

//请求类型
enum HttpRequestType:String
{
    case Json="application/json"
    case Default="application/x-www-form-urlencoded"
}


func CheckNet()->Bool
{
    let status = Reach().connectionStatus()
    switch status {
    case .Unknown, .Offline:
        
        //ShowMessage("网络无法连接")
        return false
        ""
        
    case .Online(.WWAN):
        
        ""
    case .Online(.WiFi):
        
        ""
    }
    
    return true
    
}

typealias ProgressBlock = (CGFloat)->Void


class XHttpPool:NSObject
{
    static let Share = XHttpPool.init()
    
    let config = NSURLSessionConfiguration.defaultSessionConfiguration()
    var session:NSURLSession!
    var serverTimeInterval:NSTimeInterval = 0.0
    lazy var httpArr:Dictionary<String,XHttpRequest> = [:]
    lazy var httpWaitIngArr:Array<XHttpRequest> = []
    weak var delegate:NSURLSessionDelegate!
    
    private override init()
    {
        super.init()
        
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        
        config.HTTPAdditionalHeaders = ["User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36","Content-Type":"text/plain; charset=utf-8","Accept":"*/*","Accept-Encoding":"gzip, deflate, sdch"]
        
        delegate  = XHttpPoolHandle.Share
        
        session = NSURLSession(configuration: config, delegate: XHttpPoolHandle.Share, delegateQueue: NSOperationQueue())
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(XHttpPool.networkStatusChanged(_:)), name: ReachabilityStatusChangedNotification, object: nil)
        Reach().monitorReachabilityChanges()
        
    }
    
    static func removeAllCookies()
    {
        if let arr=NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies
        {
            for cookie in arr
            {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            }
        }
        
    }
    
    func networkStatusChanged(notification: NSNotification) {
        let userInfo = notification.userInfo
        
        if((userInfo!["Status"] as! String).rangeOfString("Online") != nil)
        {
            
            for item in self.httpWaitIngArr
            {
                if(!item.runing)
                {
                    item.startTask()
                }
            }
            
        }
        
    }
    
    func getRequestWithTask(task:NSURLSessionTask)->XHttpRequest?
    {
        for (_,value) in self.httpArr
        {
            if value.task == task
            {
                return value
            }
        }
        
        return nil
    }
    
    //针对无法根据url分辨的post方法 每次都重新生成一个新的
    class func getRequestWithUrl(url:String,hasBody:Bool)->XHttpRequest
    {
        var http:XHttpRequest!
        
        if !hasBody
        {
            if(XHttpPool.Share.httpArr[url] == nil)
            {
                http = XHttpRequest()
                XHttpPool.Share.httpArr[url]=http
            }
            else
            {
                http = XHttpPool.Share.httpArr[url]
            }
        }
        else
        {
            http = XHttpRequest()
            XHttpPool.Share.httpArr[url+"\(NSDate().timeIntervalSince1970)"]=http
        }
        
        return http
    }
    
    
    func remove(http:XHttpRequest)
    {
        for (key,value) in httpArr
        {
            if value == http && !httpWaitIngArr.contains(value)
            {
                http.free()
                httpArr.removeValueForKey(key)
            }
        }
        
    }
    
    //以下为请求方法  有返回值的为同步方法  带auto的为自动诊断网络状况 无网的时候请求,会在网络连接上后自动请求数据 暂不考虑后台请求问题
    //body 可传字符串 字典 Reflect类的model 会自动转换成http的body
    
    class func synchRequestDict(url:String,body:AnyObject?,method:HttpMethod)->[String:AnyObject]
    {
        CheckNet()
        let http = XHttpRequest()
        return http.synchForDict(url, body: body, method: method)
    }
    
    class func synchRequestJson(url:String,body:AnyObject?,method:HttpMethod)->JSON?
    {
        CheckNet()
        let http = XHttpRequest()
        return http.synchForJson(url, body: body, method: method)
    }
    
    class func requestHTML(url:String,body:AnyObject?,method:HttpMethod,block:XHTMLBlock)->Void
    {
        CheckNet()
        
        let http = getRequestWithUrl(url, hasBody: body != nil)
        http.resultType = .Html
        http.requestHTML(url, body: body, method: method, block: block)
    }
    
    class func requestDict(url:String,body:AnyObject?,method:HttpMethod,block:httpBlock)->Void
    {
        CheckNet()
        
        let http = getRequestWithUrl(url, hasBody: body != nil)
        
        http.requestDict(url, body: body, method: method, block: block)
    }
    
    class func requestJson(url:String,body:AnyObject?,method:HttpMethod,block:JsonBlock)->Void
    {
        CheckNet()
        
        let http = getRequestWithUrl(url, hasBody: body != nil)
        
        http.requestJson(url, body: body, method: method, block: block)
    }
    
    class func requestDictAutoConnect(url:String,body:AnyObject?,method:HttpMethod,block:httpBlock)->Void
    {
        let http = getRequestWithUrl(url, hasBody: body != nil)
        
        if(!CheckNet())
        {
            if(!XHttpPool.Share.httpWaitIngArr.contains(http))
            {
                XHttpPool.Share.httpWaitIngArr.append(http)
            }
        }
        
        http.requestDict(url, body: body, method: method, block: block)
    }
    
    class func requestJsonAutoConnect(url:String,body:AnyObject?,method:HttpMethod,block:JsonBlock)->Void
    {
        let http = getRequestWithUrl(url, hasBody: body != nil)
        
        if(!CheckNet())
        {
            if(!XHttpPool.Share.httpWaitIngArr.contains(http))
            {
                XHttpPool.Share.httpWaitIngArr.append(http)
            }
        }
        
        http.requestJson(url, body: body, method: method, block: block)
    }
    
    
    // 上传 没有文件 file传nil
    class func upLoad(url:String,parameters:[String:AnyObject],file:[NSData]?,name:String,progress:ProgressBlock?,result:JsonBlock)
    {
        let http = getRequestWithUrl(url, hasBody: true)
        
        http.uploadFile(parameters, fileArr: file, URL: url, name: name, progress: progress, result: result)
        
    }
    
    class func upLoadWithMutableName(url:String,parameters:[String:AnyObject],file:[NSData]?,name:String,progress:ProgressBlock?,result:JsonBlock)
    {
        let http = XHttpRequest()
        http.mutableFileName = true
        XHttpPool.Share.httpArr[url+"\(NSDate().timeIntervalSince1970)"]=http
        
        http.uploadFile(parameters, fileArr: file, URL: url, name: name, progress: progress, result: result)
        
    }
    
    
    
    
    
}
