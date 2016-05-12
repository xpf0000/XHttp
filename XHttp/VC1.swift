//
//  VC1.swift
//  XHttp
//
//  Created by X on 16/3/4.
//  Copyright © 2016年 XHttp. All rights reserved.
//

import UIKit


class LoginModel: Reflect {
    
    var mob = "18637973617"
    var pass = "000000"
    
}

class Model: Reflect {
    
    var a = 0
    
    var b = ""
}


class VC1: UIViewController {

    var table:UITableView = UITableView()
    
    var arr:[Reflect] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url = ""
        
        let json = JSON.init(NSData())
        
        json.arrayValue
        
        json.dictionaryValue
        
        json["a"].arrayValue
        
        json[0]["b"].intValue
        
        
        let model = Model.parse(dict: ["a":1,"b":"abc"])
        
        let model1 = Model.parse(json: json, replace: nil)
        
        let model2 = Model.parse(json: json, replace: ["c":"a"])
        
        
        let dict = XHttpPool.synchRequestDict("", body: "a=1&b=2", method: .GET)
        
        let json1 = XHttpPool.synchRequestJson("", body: ["a":1,"b":"2"], method: .POST)
        

        XHttpPool.requestJson("", body: Model(), method: .POST) { (json) -> Void in
            
    
        }
        
        XHttpPool.requestJsonAutoConnect("", body: nil, method: .GET) { (json) in
            
            
        }
        
        
        XHttpPool.upLoad("", parameters: ["c":"5"], file: [NSData()], name: "file", progress: { (p) in
            
        }) { (json) in
                
                
        }
        
        //let url = ""
        
        let http = XHttpPool.getRequestWithUrl(url, hasBody: true)
        
        http.resultType = .Html
        
        http.requestDict(url, body: "a=0", method: .GET) { (dict) in
            
            let html = dict["HTML"]
            
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    deinit
    {
        print("VC1 deinit !!!!!!!!")
    }


}
