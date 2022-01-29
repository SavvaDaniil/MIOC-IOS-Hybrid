//
//  ViewController.swift
//  MIOC
//
//  Created by Daniil Savva on 11/09/2019.
//  Copyright © 2019 Daniil Savva. All rights reserved.
//

import UIKit
import WebKit

import SQLite3

//для шифрования md5
import Foundation
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

import GoogleMobileAds

class ViewController: UIViewController, GADInterstitialDelegate {
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
    
    var interstitial: GADInterstitial!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //ПРОВЕРЯЕМ АВТОРИЗАЦИЮ
        //работаем с базой данных
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("mioc.sqlite")
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        } else {
            print("База данных открыта")
        }
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS user_info (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, value TEXT)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        } else {
            print("Код добавления таблицы выполнен")
        }
        print("Путь до базы данных \(fileURL.path)")
        
        
        //запрашиваем id_of_user
        let id_of_user_from_db = select_db(a: "id_of_user")
        if(id_of_user_from_db.isEmpty){
            print("В базе строка id_of_user не найдена")
            insert_string_tutorial_in_db(first_parametr:"id_of_user",b:"0")
        } else {
            print("id_of_user в базе найден ВСТАВКА НЕ ТРЕБУЕТСЯ")
            GlobalVariables.id_of_user = id_of_user_from_db
        }
        print("Полученный id_of_user = \(GlobalVariables.id_of_user)")
        //запрашиваем key_access
        let key_access_from_db = select_db(a: "key_access")
        if(key_access_from_db.isEmpty){
            print("В базе строка key_access не найдена")
            insert_string_tutorial_in_db(first_parametr:"key_access",b:"0")
        } else {
            print("key_access в базе найден ВСТАВКА НЕ ТРЕБУЕТСЯ")
            GlobalVariables.key_access = key_access_from_db
        }
        print("Полученный key_access = \(GlobalVariables.key_access)")
        
        
        
        
        //настраиваем браузер
        setupView()
        loadURL()
        
        
        //interstitial = load_admob_request()
    }
    
    func load_admob_request()  -> GADInterstitial {
        //верхнее ДЕМО
        //убрал 23.07.2020
        //interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/1712485313")
        //interstitial = GADInterstitial(adUnitID: "ca-app-pub-7611797076279656/2841516109")
        interstitial.delegate = self
        let request = GADRequest()
        interstitial.load(request)
        return interstitial
    }
    func show_admob(){
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
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
        let path_of_html_page = "index"
        
        webView.scrollView.bounces = false //запрет на проматывание контента в браузере
        
        if(GlobalVariables.id_of_user == "" || GlobalVariables.key_access == "" || GlobalVariables.id_of_user == "0" || GlobalVariables.key_access == "0"){
            //Запускаем регистрацию
            print("ПЕРЕХОД НА РЕГИСТРАЦИЮ")
            
            
            if let url = Bundle.main.url(forResource: path_of_html_page, withExtension: "html") {
                let url2 = URL(string: "?", relativeTo: url)
                webView.loadFileURL(url2!, allowingReadAccessTo: url2!.deletingLastPathComponent())
                let request = URLRequest(url: url2!)
                webView.load(request)
            } else {
                print("Файл не найден")
            }
        } else {
            
            if let url = Bundle.main.url(forResource: path_of_html_page, withExtension: "html") {
                let url2 = URL(string: "?a=\(GlobalVariables.id_of_user)&b=\(GlobalVariables.key_access)", relativeTo: url)
                webView.loadFileURL(url2!, allowingReadAccessTo: url2!.deletingLastPathComponent())
                let request = URLRequest(url: url2!)
                webView.load(request)
            } else {
                print("Файл не найден")
            }
        }
        
    }
    
    
    
    
    func select_db(a: String) -> String{
        //this is our select query
        let queryString = "SELECT * FROM user_info WHERE name = '\(a)' "
        
        //statement pointer
        var stmt:OpaquePointer?
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing select: \(errmsg)")
            return "0"
        }
        
        var answer = ""
        //traversing through all the records
        
        while(sqlite3_step(stmt) == SQLITE_ROW){
            //let id = sqlite3_column_int(stmt, 0)
            //let name = String(cString: sqlite3_column_text(stmt, 1))
            let value = String(cString: sqlite3_column_text(stmt, 2))
            
            //adding values to list
            //heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
            answer = value
        }
        
        //let sEventTitle = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, 1)))
        return answer
    }
    func insert_in_db(first_parametr: String, b: String){
        if(first_parametr.isEmpty || b.isEmpty){
            return
        }
        print("a для вставки = \(first_parametr)")
        //creating a statement
        var stmt: OpaquePointer?
        
        //the insert query
        let queryString = "INSERT INTO user_info (name, value) VALUES (?,?)"
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        //binding the parameters
        if sqlite3_bind_text(stmt, 1, first_parametr, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        if sqlite3_bind_text(stmt, 2, b, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        //executing the query to insert values
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting string: \(errmsg)")
            return
        }
    }
    
    func insert_string_tutorial_in_db(first_parametr: String, b: String){
        if(first_parametr.isEmpty || b.isEmpty){
            return
        }
        print("a для вставки = \(first_parametr)")
        //creating a statement
        var stmt: OpaquePointer?
        
        //let queryString = "INSERT INTO user_info (name, value) VALUES (?,?)"
        var queryString = ""
        //the insert query
        if(first_parametr == "id_of_user"){
            queryString = "INSERT INTO user_info (name, value) VALUES ('id_of_user',?)"
        }
        if(first_parametr == "key_access"){
            queryString = "INSERT INTO user_info (name, value) VALUES ('key_access',?)"
        }
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error preparing insert: \(errmsg)")
            return
        }
        
        //binding the parameters
        if sqlite3_bind_text(stmt, 1, b, -1, nil) != SQLITE_OK{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure binding name: \(errmsg)")
            return
        }
        
        
        //executing the query to insert values
        if sqlite3_step(stmt) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("failure inserting string: \(errmsg)")
            return
        }
    }
    
    func update_database(first_parametr: String, b: String) {
        var updateStatement: OpaquePointer? = nil
        var queryString = ""
        if(first_parametr == "id_of_user"){
            queryString = "UPDATE user_info SET value = '\(b)' WHERE name = 'id_of_user' "
        }
        if(first_parametr == "key_access"){
            queryString = "UPDATE user_info SET value = '\(b)' WHERE name = 'key_access' "
        }
        
        if sqlite3_prepare_v2(db, queryString, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
        sqlite3_finalize(updateStatement)
    }
    
    
    //Для шифрования md5 НАЧАЛО
    func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }


}


// MARK: - WKUIDelegate
extension ViewController : WKUIDelegate {
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
    
    
    //ниже команды для Admob
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
        webView.evaluateJavaScript("error_while_loading_ads();", completionHandler: nil)
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
        webView.evaluateJavaScript("watch_ads_to_end();", completionHandler: nil)
    }
    
    /// Tells the delegate the interstitial had been animated off the screen.
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("interstitialDidDismissScreen")
        webView.evaluateJavaScript("check_video_ads_about_finished();", completionHandler: nil)
        interstitial = load_admob_request()
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
}

// MARK: - WKNavigationDelegate
extension ViewController : WKNavigationDelegate {
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
            
            if(urlHost.contains("registration")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "registration", with: "", options: .literal, range: nil)
                print("Полученный от сервера :\(newString)")
                let newStringArr = newString.components(separatedBy: "_")
                print("Полученный от сервера id_of_user: \(newStringArr[0])")
                print("Полученный от сервера key_access: \(newStringArr[1])")
                
                
                update_database(first_parametr: "id_of_user", b: newStringArr[0])
                update_database(first_parametr: "key_access", b: newStringArr[1])
                //перезагружаем приложение
                UIApplication.shared.keyWindow?.rootViewController = storyboard!.instantiateViewController(withIdentifier: "CentralWindow")
            }
            
            if(urlHost == "enteronlineaudition"){
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let OnlineAudition = storyBoard.instantiateViewController(withIdentifier: "OnlineAudition") as! OnlineAudition
                self.present(OnlineAudition, animated: true, completion: nil)
            }
            
            if(urlHost == "logout"){
                update_database(first_parametr: "id_of_user", b:"0")
                update_database(first_parametr: "key_access", b:"0")
                //перезагружаем приложение
                UIApplication.shared.keyWindow?.rootViewController = storyboard!.instantiateViewController(withIdentifier: "CentralWindow")
            }
            
            
            if(urlHost.contains("update_id_of_discipline")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "update_id_of_discipline", with: "", options: .literal, range: nil)
                print("Полученный от сервера id_of_discipline:\(newString)")
                
                
                GlobalVariables.id_of_discipline = newString
            }
            
            if(urlHost == "js_call_show_ads"){
                show_admob()
            }
            if(urlHost.contains("open_new_activity_for_youtube_video")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "open_new_activity_for_youtube_video", with: "", options: .literal, range: nil)
                print("Полученный от сервера :\(newString)")
                let newStringArr = newString.components(separatedBy: "_")
                print("Полученный от сервера id_of_discipline: \(newStringArr[0])")
                print("Полученный от сервера lesson: \(newStringArr[1])")
                print("Полученный от сервера kind_of_content: \(newStringArr[2])")
                
                
                GlobalVariables.id_of_discipline = newStringArr[0]
                GlobalVariables.lesson = newStringArr[1]
                GlobalVariables.content_for_second_activity = newStringArr[2]
                
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let Main2Activity = storyBoard.instantiateViewController(withIdentifier: "Main2Activity") as! Main2Activity
                self.present(Main2Activity, animated: true, completion: nil)
            }
            
            
            
            
            if(urlHost == "open_vkontakte"){
                //NSURL *url = [[NSURL alloc] initWithString:@"vk://vk.com/fameagency"];
                //[[UIApplication sharedApplication] openURL:url];
                var vkHooks = "vk://vk.com/fameagency"
                var vkUrl = NSURL(string: vkHooks)
                if UIApplication.shared.canOpenURL(vkUrl! as URL) {
                    UIApplication.shared.open(vkUrl! as URL)
                } else {
                    UIApplication.shared.open(NSURL(string: "http://vk.com/fameagency")! as URL, options: [:], completionHandler: nil)
                }
            }
            
            
            
            if(urlHost == "open_scanner"){
                /*
                print("Вызов функции open_scanner")
                
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let ScannerViewController = storyBoard.instantiateViewController(withIdentifier: "ScannerViewController") as! ScannerViewController
                self.present(ScannerViewController, animated: true, completion: nil)
                */
            }
            
            
            
            
            
            if(urlHost == "startgame"){
                /*
                 let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                 let Game = storyBoard.instantiateViewController(withIdentifier: "Game") as! Game
                 self.navigationController?.pushViewController(Game, animated: false)
                 */
            }
            
            if(urlHost == "check_audio_for_admob"){
                let schetchik_of_playing_content = select_db(a: "schetchik_of_playing_content")
                let schetchik_of_playing_content_int = Int(schetchik_of_playing_content)
                print("Прочитанное количество запусков медиа \(String(describing: schetchik_of_playing_content_int))")
                if(schetchik_of_playing_content_int! > 3){
                    print("Запускаем JAVASCRIPT запуска со страницы ADMOB")
                    //здесь функция запуска JAVASCRIPT admob
                    webView.evaluateJavaScript("work_with_admob()", completionHandler: nil)
                    
                } else {
                    print("Увеличиваем в базе значение просмотров на 1 больше")
                    let new_schetchik_of_playing_content_int = String(schetchik_of_playing_content_int! + 1)
                    update_database(first_parametr: "schetchik_of_playing_content", b: new_schetchik_of_playing_content_int)
                }
            }
            
            
            if(urlHost == "work_with_admob"){
                print("Произошел запуск функции вызова ADMOB")
                let schetchik_of_playing_content = select_db(a: "schetchik_of_playing_content")
                let schetchik_of_playing_content_int = Int(schetchik_of_playing_content)
                print("Прочитанное количество запусков медиа \(String(describing: schetchik_of_playing_content_int))")
                if(schetchik_of_playing_content_int! > 3){
                    print("Запускаем ADMOB")
                    //здесь функция запуска admob
                    //show_admob()
                } else {
                    print("Увеличиваем в базе значение просмотров на 1 больше")
                    let new_schetchik_of_playing_content_int = String(schetchik_of_playing_content_int! + 1)
                    update_database(first_parametr: "schetchik_of_playing_content", b: new_schetchik_of_playing_content_int)
                }
            }
            
            
            
            func open_link_youtube(a: String){
                let YoutubeQuery =  a
                let escapedYoutubeQuery = YoutubeQuery.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                //let appURL = NSURL(string: "youtube://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
                let appURL = NSURL(string: "youtube://www.youtube.com/watch?v=\(escapedYoutubeQuery!)")!
                //let webURL = NSURL(string: "https://www.youtube.com/results?search_query=\(escapedYoutubeQuery!)")!
                let webURL = NSURL(string: "https://www.youtube.com/watch?v=\(escapedYoutubeQuery!)")!
                let application = UIApplication.shared
                
                if application.canOpenURL(appURL as URL) {
                    application.open(appURL as URL)
                } else {
                    // if Youtube app is not installed, open URL inside Safari
                    application.open(webURL as URL)
                }
            }
            
            //if(urlHost == "4ikEpbbyQlk"){
            if(urlHost.contains("openyoutube")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "openyoutube", with: "", options: .literal, range: nil)
                open_link_youtube(a: newString)
                
            }
            
            
            
            
            /* Работа с баннерами НАЧАЛО*/
            func open_banner_vkontakte(a: String){
                let vkHooks = "vk://vk.com/"+a
                let vkUrl = NSURL(string: vkHooks)
                if UIApplication.shared.canOpenURL(vkUrl! as URL) {
                    UIApplication.shared.open(vkUrl! as URL)
                } else {
                    UIApplication.shared.open(NSURL(string: "http://vk.com/"+a)! as URL, options: [:], completionHandler: nil)
                }
            }
            if(urlHost.contains("open_banner_vkontakte")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "open_banner_vkontakte", with: "", options: .literal, range: nil)
                open_banner_vkontakte(a: newString)
            }
            
            func open_banner_instagram(a: String){
                let instagramHooks = "instagram://user?username="+a
                let instagramUrl = NSURL(string: instagramHooks)
                if UIApplication.shared.canOpenURL(instagramUrl! as URL) {
                    UIApplication.shared.open(instagramUrl! as URL)
                } else {
                    UIApplication.shared.open(NSURL(string: "http://instagram.com/"+a)! as URL, options: [:], completionHandler: nil)
                }
            }
            if(urlHost.contains("open_banner_instagram")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "open_banner_instagram", with: "", options: .literal, range: nil)
                open_banner_instagram(a: newString)
            }
            
            if(urlHost.contains("open_banner_browser")){
                let aString = urlHost
                let newString = aString.replacingOccurrences(of: "open_banner_browser", with: "", options: .literal, range: nil)
                UIApplication.shared.open(NSURL(string: newString)! as URL, options: [:], completionHandler: nil)
            }
            /* Работа с баннерами КОНЕЦ*/
            
            
            
            
            if(urlHost == "change_language_en"){
                update_database(first_parametr: "language", b: "en")
                let url = Bundle.main.url(forResource: "language", withExtension: "html")
                let url2 = URL(string: "?lang=en", relativeTo: url)
                webView.loadFileURL(url2!, allowingReadAccessTo: url2!.deletingLastPathComponent())
                let request = URLRequest(url: url2!)
                webView.load(request)
            }
            if(urlHost == "change_language_ru"){
                update_database(first_parametr: "language", b: "ru")
                let url = Bundle.main.url(forResource: "language", withExtension: "html")
                let url2 = URL(string: "?lang=ru", relativeTo: url)
                webView.loadFileURL(url2!, allowingReadAccessTo: url2!.deletingLastPathComponent())
                let request = URLRequest(url: url2!)
                webView.load(request)
            }
            
            /*
             
             ["19","5YXUzqn6DmQ"],
             ["21","FFHC-E1gDRk"],
             ["22","r6xSojRv5CI"],
             ["24","siZXLk4UTVU"],
             ["25","KlwFnYKGZPQ"],
             ["26","iixv-r315Y0"],
             ["27","XjG-QIhh884"],
             ["28","Nt5K7bqSik8"],
             ["29","2N7LUhkWiik"],
             ["30","W8O5klV6sMU"],
             ["31","9VDJc-2rtGE"],
             ["33","FI4ixURAEfc"],
             ["34","ljblNN2Hkgs"],
             ["35","xJhUHxEif50"],
             ["37","V6ykjJaeEfo"],
             ["39","lGvaL5mMM8s"],
             ["42","XBqFudUt8ts"],
             ["43","-mO7bEE7yBU"],
             ["44","eqkOriupFdA"],
             ["46","QfR93R1HIwc"],
             ["47","zb6tQfOHwYg"],
             ["50","STHULm9uW94"],
             ["51","4ikEpbbyQlk"]
             
             
             */
            
            
            decisionHandler(.cancel)
            
            
            
            // call back!
            //self.webView.stringByEvaluatingJavaScript(script: "javascript:testCallBack('\(urlHost)');")
            
            // popup!
            //            self.webView.stringByEvaluatingJavaScript(script: "javascript:test02();")
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("\(#function)")
        decisionHandler(.allow)
    }
    
}

