//
//  MGJSBridge.swift
//  TheMilkWayProject
//
//  Created by sgc on 2021/9/30.
//

import Foundation
import ObjectiveC
import WebKit

typealias JSCallBack = (Dictionary<AnyHashable,Any>?)->Void

public class MGJSBridge: NSObject {
    
    static var handlerMap : Dictionary<String,MGJSBridgeObj> = Dictionary()
    
    static var modulesMap : Dictionary<String, AnyObject> = Dictionary()
    
    public static func injectJS(webView:WKWebView) {
        //注入js
        webView.evaluateJavaScript(jsString(), completionHandler: nil)
        
    }
    
    static func runBridge(url:URL,  webView: WKWebView!) {
        if url.scheme != "jsbridge" {
            return
        }
    
    
        let com = NSURLComponents.init(string: url.absoluteString)
        
        guard let queryItems = com?.queryItems else {
            return
        }
        
        var jsonString : String? = nil
        var params : Dictionary<String,Any>? = nil
        
        for item in queryItems {
            if item.name == "params" {
                jsonString = item.value
                break
            }
        }
        
        guard let data = jsonString?.data(using: .utf8) else {
            return
        }
        
        do {
            try  params = JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? Dictionary<String, Any>
        }catch {
            return
        }
        
        let invokeParam : Dictionary<AnyHashable,Any> = params?["invokeParam"] as! Dictionary<AnyHashable, Any>
        let callBackId : String? = params?["callbackID"] as? String
        
        let method = url.host!
        
        guard let jsObj = handlerMap[method] else {
            return
        }
        
        
        var amethod : Method? = nil
        var responder : Any? = nil
        typealias Function = (@convention(c)(Any,Selector,Dictionary<AnyHashable,Any>?, @escaping JSCallBack)->Void)

        if jsObj.isClassMethod {
            amethod = NSClassFromString(jsObj.className)?.method(for: jsObj.selector)
            
            responder = NSClassFromString(jsObj.className)
        }else {
            amethod = NSClassFromString(jsObj.className)?.instanceMethod(for: jsObj.selector)
            responder = modulesMap[jsObj.className]
        }
        
        guard amethod != nil else {
            return
        }
        
        weak var weakWebview = webView
        let function = unsafeBitCast(amethod!, to: Function.self)
        function(responder!, jsObj.selector,invokeParam,{ param in
            let strongWebView = weakWebview
            MGJSBridge.handlerCallBack(callBackId: callBackId, param: param,webView: strongWebView)
        })
    }
    
    public static func handlerCallBack(callBackId:String?, param:Dictionary<AnyHashable,Any>?, webView:WKWebView!) {
        
        if callBackId?.count == 0 {
            return
        }
        
        do {
            
            var string = "{}"
            if param != nil {
                let data = try JSONSerialization.data(withJSONObject: param!, options: .fragmentsAllowed)
                string = String.init(data: data, encoding: .utf8)!
            }
          
            let jsString = NSString.init(format: "JSBridge.callbackJS(\"%@\",%@)", callBackId! as NSString, string as NSString) as String
            
            webView.evaluateJavaScript(jsString) { (result, error) in
                
            }
            
        }catch {
            
        }
        
    }
    
    @objc public static  func registerJSBridge(instance:AnyObject, selector:Selector, name:String) {
        
        var isClassMethod = false
        var method = instance.classForCoder?.instanceMethod(for: selector)
        
        if method == nil {
            method = instance.classForCoder?.method(for: selector)
            isClassMethod = true
        }
        
        
        if method == nil {
            return
        }
        
        let className = NSStringFromClass(instance.classForCoder)
        let obj = MGJSBridgeObj(selector: selector, className:className, isClassMethod: isClassMethod)
        
        modulesMap[className] = instance
        handlerMap[name] = obj
        
    }
}

struct MGJSBridgeObj {
    var selector : Selector!
    var className : String!
    var isClassMethod : Bool
}


func jsString()->String! {
    return """
      var messageHandlers = {}
      var responseCallbacks = {}
      var messageID = 0
    function commonInit() {
    if (window.JSBridge) {
        return
    }
    
    window.JSBridge = {
        callHandler: callHandler,
        callbackJS: callbackJS
    }
}


function callHandler(handlerName, data, responseCallback) {
    commonInit()
    
    
    var url = 'JSBridge://'
    url = url + handlerName + '?'
    
    args = {}
    
    if (data) {
        args['invokeParam'] = data
    }
    
    if (responseCallback) {
        var callbackId = 'cb_'+ messageID + handlerName;
        messageID = messageID + 1
        responseCallbacks[callbackId] = responseCallback
        args['callbackID'] = callbackId
    }
    
    
    url = url + 'params=' + JSON.stringify(args)
    messagingIframe = document.createElement('iframe')
    messagingIframe.src = url
    messagingIframe.style.display = 'none'
    document.documentElement.appendChild(messagingIframe)
}

function callbackJS(cbName, data) {
    var callback = responseCallbacks[cbName]
    if (callback) {
        callback(data)
    }
    return 404
}
"""
}
