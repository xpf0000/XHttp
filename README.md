# XHttp
swift版 轻量级 NSURLSession 网络请求库 

一 说明:
  
  基于NSURLSession的轻量级网络请求库 
  
  实现同步,异步接口数据请求,表单上传操作,支持json,html,nsdata格式
  
  实现联网自动请求,可在有网络连接时自动请求接口
  
  集成了 SwiftyJSON 和 Reflect 这两个库使用起来还是比较方便的 字典 JSON Model之间的转换很方便
  
    SwiftyJSON事例:
  
      let json = JSON.init(NSData())
        
      json.arrayValue
        
      json.dictionaryValue
        
      json["a"].arrayValue
        
      json[0]["b"].intValue
    
    SwiftyJSON一个好处就是不需要做很多非空判断  当然也可以使用普通的解包 然后自己去判断是否为空
    
    Reflect 事例:
    
      class Model: Reflect {
    
        var a = 0
    
        var b = ""
      }
    
      let model = Model.parse(dict: ["a":1,"b":"abc"])
        
      let model1 = Model.parse(json: json, replace: nil)
        
      let model2 = Model.parse(json: json, replace: ["c":"a"])  把json字符串里面的a字段 解析到model中的c属性  主要应对json字符串的key为系统关键词等情况 很少发生 平常传nil就好
  
  想详细了解这两个库的请移步:
  
  SwiftyJSON: https://github.com/SwiftyJSON/SwiftyJSON
  
  Reflect: https://github.com/CharlinFeng/Reflect
  
  项目中用到的有些修改 如果想使用新版的估计要先好好理一下
  
  二 项目引用:
  
    直接把HTTP文件夹添加到项目中
    
  三 使用说明:
  
    以下为请求方法  有返回值的为同步方法  带auto的为自动诊断网络状况 无网的时候请求,会在网络连接上后自动请求数据
    
    暂不考虑后台请求问题 因为做这个的目标是轻量化的接口解析 一般的接口数据都比较小 很少会用到后台执行 后续可能会慢慢更新
    
    body 可传字符串 字典 Reflect类的model 会自动转换成http的body
    
    1 两个同步请求:
      
      XHttpPool.synchRequestDict(url:String,body:AnyObject?,method:HttpMethod)->[String:AnyObject] 
        
      XHttpPool.synchRequestJson(url:String,body:AnyObject?,method:HttpMethod)->JSON?
      
    2 两个异步请求:
    
      XHttpPool.requestDict(url:String,body:AnyObject?,method:HttpMethod,block:httpBlock)->Void
      
      XHttpPool.requestJson(url:String,body:AnyObject?,method:HttpMethod,block:JsonBlock)->Void
      
    3. 两个自动连接请求:
    
      XHttpPool.requestDictAutoConnect(url:String,body:AnyObject?,method:HttpMethod,block:httpBlock)->Void
      
      XHttpPool.requestJsonAutoConnect(url:String,body:AnyObject?,method:HttpMethod,block:JsonBlock)->Void
      
    4.  两个上传方法:
    
      XHttpPool.upLoad(url:String,parameters:[String:AnyObject],file:[NSData],name:String,progress:ProgressBlock?,result:JsonBlock)
      
      XHttpPool.upLoadWithMutableName(url:String,parameters:[String:AnyObject],file:[NSData]?,name:String,progress:ProgressBlock?,result:JsonBlock)
      
      第一个适用于 多个文件一个接收name的情况  第二个适用于 一个文件一个接收name的情况  
      
  四. 示例:
  
    let dict = XHttpPool.synchRequestDict("", body: "a=1&b=2", method: .GET)
        
    let json = XHttpPool.synchRequestJson("", body: ["a":1,"b":"2"], method: .POST)
    
    XHttpPool.requestJson("", body: Model(), method: .POST) { (json) -> Void in
            
    }
    
    XHttpPool.requestJsonAutoConnect("", body: nil, method: .GET) { (json) in
            
            
    }
    
    XHttpPool.upLoad("", parameters: ["c":"5"], file: [NSData()], name: "file", progress: { (p) in
          
    }) { (json) in
                
    }
    
    
    let url = ""
        
    let http = XHttpPool.getRequestWithUrl(url, hasBody: true)
        
    http.resultType = .Html
        
    http.requestDict(url, body: "a=0", method: .GET) { (dict) in
            
      let html = dict["HTML"]
            
    }
      
      
      
  
  
