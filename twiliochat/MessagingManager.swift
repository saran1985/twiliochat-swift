import UIKit

class MessagingManager: NSObject {
    
    static let _sharedManager = MessagingManager()
    
    var client:TwilioChatClient?
    var delegate:ChannelManager?
    var connected = false
    var generalChannel: TCHChannel? = nil
    
    var userIdentity:String {
        return SessionManager.getUsername()
    }
    
    var hasIdentity: Bool {
        return SessionManager.isLoggedIn()
    }
    
    override init() {
        super.init()
        delegate = ChannelManager.sharedManager
    }
    
    class func sharedManager() -> MessagingManager {
        return _sharedManager
    }
    
    func presentRootViewController() {
        
//         print(hasIdentity)
//
//        if (!hasIdentity) {
//            presentViewControllerByName(viewController: "LoginViewController")
//            return
//        }
//
         print(connected)
        
        if (!connected) {
            connectClientWithCompletion { success, error in
                print("Delegate method will load views when sync is complete")
                if (!success || error != nil) {
                    DispatchQueue.main.async {
                        print("present loginviewcontroller")
                        self.presentViewControllerByName(viewController: "LoginViewController")
                    }
                }
            }
            return
        }
        
        presentViewControllerByName(viewController: "RevealViewController")
    }
    
    func presentViewControllerByName(viewController: String) {
        presentViewController(controller: storyBoardWithName(name: "Main").instantiateViewController(withIdentifier: viewController))
    }
    
    func presentLaunchScreen() {
        presentViewController(controller: storyBoardWithName(name: "LaunchScreen").instantiateInitialViewController()!)
    }
    
    func presentViewController(controller: UIViewController) {
        let window = UIApplication.shared.delegate!.window!!
        window.rootViewController = controller
    }
    
    func storyBoardWithName(name:String) -> UIStoryboard {
        return UIStoryboard(name:name, bundle: Bundle.main)
    }
    
    // MARK: User and session management
    
    func loginWithUsername(username: String,
                           completion: @escaping (Bool, NSError?) -> Void) {
       // SessionManager.loginWithUsername(username: username)
        connectClientWithCompletion(completion: completion)
    }
    
    func logout() {
        SessionManager.logout()
        DispatchQueue.global(qos: .userInitiated).async {
            self.client?.shutdown()
            self.client = nil
        }
        self.connected = false
    }
    
    // MARK: Twilio Client
    
    func loadGeneralChatRoomWithCompletion(completion:@escaping (Bool, NSError?) -> Void) {
        ChannelManager.sharedManager.joinGeneralChatRoomWithCompletion { succeeded in
            if succeeded {
                print("joinGeneralChatRoomWithCompletion")
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not join General channel", code: 300)
                completion(succeeded, error)
            }
        }
    }
    
    func connectClientWithCompletion(completion: @escaping (Bool, NSError?) -> Void) {
        if (client != nil) {
            logout()
        }
        
        requestTokenWithCompletion { succeeded, token in
            if let token = token, succeeded {
                self.initializeClientWithToken(token: token)
                completion(succeeded, nil)
            }
            else {
                let error = self.errorWithDescription(description: "Could not get access token", code:301)
                completion(succeeded, error)
            }
        }
    }
    
    func initializeClientWithToken(token: String) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        TwilioChatClient.chatClient(withToken: token, properties: nil, delegate: self) { [weak self] result, chatClient in
             print("result is",result)
            guard (result.isSuccessful()) else { return }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self?.connected = true
            self?.client = chatClient
        }
    }
    
    func requestTokenWithCompletion(completion:@escaping (Bool, String?) -> Void) {
        if let device = UIDevice.current.identifierForVendor?.uuidString {
           TokenRequestHandler.fetchToken(params: ["device": device, "identity":"abd"]) {response,error in
          //  TokenRequestHandler.fetchToken(params: ["property_id":"46","identity":"sa"]) {response,error in
                var token: String?
                token = response["token"] as? String
                completion(token != nil, token)
            }
        }
    }
    
    func errorWithDescription(description: String, code: Int) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : description]
        return NSError(domain: "app", code: code, userInfo: userInfo)
    }
}



// MARK: - TwilioChatClientDelegate

/*extension MessagingManager: TwilioChatClientDelegate {
        
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == .completed {
            // Join (or create) the general channel
            let defaultChannel = "general"
            if let channelsList = client.channelsList() {
                channelsList.channel(withSidOrUniqueName: defaultChannel, completion: { (result, channel) in
                    if let channel = channel {
                        self.generalChannel = channel
                        channel.join(completion: { result in
                            print("Channel joined with result \(result)")
                            
                        })
                    } else {
                        // Create the general channel (for public use) if it hasn't been created yet
                        channelsList.createChannel(options: [TCHChannelOptionFriendlyName: "General Chat Channel", TCHChannelOptionType: TCHChannelType.public.rawValue], completion: { (result, channel) -> Void in
                                if result.isSuccessful() {
                                    self.generalChannel = channel
                                    self.generalChannel?.join(completion: { result in
                                        self.generalChannel?.setUniqueName(defaultChannel, completion: { result in
                                            print("channel unique name set")
                                        })
                                    })
                                }
                        })
                    }
                })
            }
        }
    }
}*/
extension MessagingManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        self.delegate?.chatClient(client, channelAdded: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        self.delegate?.chatClient(client, channelDeleted: channel)
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        if status == TCHClientSynchronizationStatus.completed {
            print("synchronizationStatusUpdated")
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            ChannelManager.sharedManager.channelsList = client.channelsList()
          //  print(client.channelsList())
            ChannelManager.sharedManager.populateChannels()
            loadGeneralChatRoomWithCompletion { success, error in
                if success {
                    print("loadGeneralChatRoomWithCompletion success")
                    self.presentRootViewController()
                }
            }
        }
        self.delegate?.chatClient(client, synchronizationStatusUpdated: status)
    }
}

// MARK: - TwilioAccessManagerDelegate
extension MessagingManager : TwilioAccessManagerDelegate {
    func accessManagerTokenWillExpire(_ accessManager: TwilioAccessManager) {
        requestTokenWithCompletion { succeeded, token in
            if (succeeded) {
                accessManager.updateToken(token!)
            }
            else {
                print("Error while trying to get new access token")
            }
        }
    }
    
    func accessManager(_ accessManager: TwilioAccessManager!, error: Error!) {
        print("Access manager error: \(error.localizedDescription)")
    }
}
