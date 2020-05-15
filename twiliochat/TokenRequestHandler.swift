import UIKit

class TokenRequestHandler {
    
    class func postDataFrom(params:[String:String]) -> String {
        var data = ""
        
        for (key, value) in params {
            if let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                if !data.isEmpty {
                    data = data + "&"
                }
                data += encodedKey + "=" + encodedValue;
            }
        }
        
        return data
    }
    
   /* class func fetchToken(params:[String:String], completion:@escaping (NSDictionary, NSError?) -> Void) {
        if let filePath = Bundle.main.path(forResource: "Keys", ofType:"plist"),
            let dictionary = NSDictionary(contentsOfFile:filePath) as? [String: AnyObject],
            let tokenRequestUrl = dictionary["TokenRequestUrl"] as? String {
            
            var request = URLRequest(url: URL(string: tokenRequestUrl)!)
            request.httpMethod = "POST"
            let postString = self.postDataFrom(params: params)
            request.httpBody = postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("error=\(String(describing: error))")
                    completion(NSDictionary(), error as NSError?)
                    return
                }
                
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    completion(NSDictionary(), NSError(domain: "TWILIO", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Incorrect return code for token request."]))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                    print("json = \(json)")
                    completion(json as NSDictionary, error as NSError?)
                } catch let error as NSError {
                    completion(NSDictionary(), error)
                }
            }
            task.resume()
        }
        else {
            let userInfo = [NSLocalizedDescriptionKey : "TokenRequestUrl Key is missing"]
            let error = NSError(domain: "app", code: 404, userInfo: userInfo)
            
            completion(NSDictionary(), error)
        }
    }
}*/

    class func fetchToken(params:[String:String], completion:@escaping (NSDictionary, NSError?) -> Void) {
        if let filePath = Bundle.main.path(forResource: "Keys", ofType:"plist"),
            let dictionary = NSDictionary(contentsOfFile:filePath) as? [String: AnyObject],
            let tokenRequestUrl = dictionary["TokenRequestUrl"] as? String {
            
            print("tokenrequesturl is",tokenRequestUrl)
            
            var request = URLRequest(url: URL(string: tokenRequestUrl)!)
           request.httpMethod = "POST"
          // request.httpMethod = "GET"
            let postString = self.postDataFrom(params: params)
            print("poststring is",postString)
         //   request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
          //  print("poststring is",postString)
            request.httpBody = postString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
              if error != nil {
                     print(error)
                } else {
                     if let usableData = data {
                        //  print("usableData",usableData) //JSONSerialization
                      do {
                        let json = try JSONSerialization.jsonObject(with: usableData, options: []) as! [String:Any]
                            print("json = \(json)")
                            completion(json as NSDictionary, error as NSError?)
                        } catch let error as NSError {
                            completion(NSDictionary(), error)
                          }
                     }
                }
                
                /*
             
             guard let data = data, error == nil else {
                               print("error=\(String(describing: error))")
                               completion(NSDictionary(), error as NSError?)
                               return
             
             
             
             if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                    completion(NSDictionary(), NSError(domain: "TWILIO", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Incorrect return code for token request."]))
                    return
                }
                
                print("response data is",data)
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                    print("json = \(json)")
                    completion(json as NSDictionary, error as NSError?)
                } catch let error as NSError {
                    completion(NSDictionary(), error)
                } */
            }
            task.resume()
        }
        else {
            let userInfo = [NSLocalizedDescriptionKey : "TokenRequestUrl Key is missing"]
            let error = NSError(domain: "app", code: 404, userInfo: userInfo)
            
            completion(NSDictionary(), error)
        }
    }
}
