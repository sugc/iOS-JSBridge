//
//  MGWebView.swift
//  TheMilkWayProject
//
//  Created by sgc on 2021/9/30.
//

import Foundation
import WebKit

public class MGWebController: UIViewController {
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = MGWebView.init(frame: self.view.bounds)
        view.addSubview(webView)
        
        MGJSBridge.registerJSBridge(instance: self, selector: #selector(test(data:callBack:)), name: "pickImage")
        let bundlePath = Bundle.main.path(forResource: "MGJSBridgeResources", ofType: "bundle")
        let bundle = Bundle.init(path: bundlePath!)
        let filePath = bundle?.path(forResource: "JSBridgeTestxx", ofType: "html")
        
        let request = URLRequest.init(url:URL.init(fileURLWithPath: filePath!))
        
        webView.load(request)
    
    }
    
    //必须有一个字典参数，callBack可缺少
    @objc func test(data:Dictionary<AnyHashable,AnyHashable>, callBack:JSCallBack ) -> Void {
        
        
        
        callBack(["test":"test"])
    }
}

class MGWebView : WKWebView, WKNavigationDelegate, WKUIDelegate {
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        self.navigationDelegate = self
        self.uiDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if navigationAction.request.url?.scheme == "jsbridge" {
            MGJSBridge.runBridge(url: navigationAction.request.url!, webView: self)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {

        
        print(message)
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        //注册js,使用JSBridgeTest.html时不需要这句
        MGJSBridge.injectJS(webView: webView)
    }
    

    deinit {
        
        print("deinit webView")
    }
}


