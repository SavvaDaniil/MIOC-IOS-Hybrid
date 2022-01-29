//
//  OnlineAudition.swift
//  MIOC
//
//  Created by Daniil Savva on 11/09/2019.
//  Copyright © 2019 Daniil Savva. All rights reserved.
//

import UIKit
import WebKit

import SQLite3

class OnlineAudition: UIViewController {
    @IBOutlet weak var safeAreaContainerView: UIView!
    private var webView: WKWebView!
    private struct Constants {
        static let schemeKey = "nativeScheme"
    }
    
    var db: OpaquePointer?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        //настраиваем браузер
        setupView()
        loadURL()
    }
    
    
    func setupView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true // default YES.
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        self.webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.safeAreaContainerView.addSubview(self.webView)
    }
    
    func loadURL() {
        let path_of_html_page = "online_audition"
        
        webView.scrollView.bounces = false //запрет на проматывание контента в браузере
        
        
        if let url = Bundle.main.url(forResource: path_of_html_page, withExtension: "html") {
            let url2 = URL(string: "?a=\(GlobalVariables.id_of_user)&b=\(GlobalVariables.key_access)&c=1", relativeTo: url)
            webView.loadFileURL(url2!, allowingReadAccessTo: url2!.deletingLastPathComponent())
            let request = URLRequest(url: url2!)
            webView.load(request)
        } else {
            print("Файл не найден")
        }
        
    }
    
    

}


// MARK: - WKUIDelegate
extension OnlineAudition : WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("\(#function)")
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("\(#function)")
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("\(#function)")
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: UIAlertController.Style.alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
            
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            
            completionHandler(nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate
extension OnlineAudition : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        print("\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    //MARK:- HERE!!!
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("\(#function)")
        
        // Check whether WebView Native is linked
        if let url = navigationAction.request.url,
            let urlScheme = url.scheme,
            let urlHost = url.host,
            urlScheme.uppercased() == Constants.schemeKey.uppercased() {
            print("url:\(url)")
            print("urlScheme:\(urlScheme)")
            print("urlHost:\(urlHost)")
            
            
            if(urlHost == "exit_from_online_audition"){
                dismiss(animated: true)
            }
            
            
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("\(#function)")
        decisionHandler(.allow)
    }
    
}
