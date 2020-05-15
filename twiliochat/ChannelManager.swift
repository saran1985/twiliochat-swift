import UIKit

class ChannelManager: NSObject {
    static let sharedManager = ChannelManager()
    
    static let defaultChannelUniqueName = "CH020d28ad5b0c41f9b0ccfa4b9b8fc09b"
   // static let defaultChannelUniqueName = "test1"
    static let defaultChannelName = ""
    
    weak var delegate:MenuViewController?
    
    var channelsList:TCHChannels?
    var channels:NSMutableOrderedSet?
    var generalChannel:TCHChannel!
    
    override init() {
        super.init()
        channels = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    
    func joinGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        
        let uniqueName = ChannelManager.defaultChannelUniqueName
        
      //  let uniqueName = "test1"
        if let channelsList = self.channelsList {
            print("1")
            channelsList.channel(withSidOrUniqueName: uniqueName) { result, channel in
                    print("2",result)
                self.generalChannel = channel
                
                print("self.generalchannel",self.generalChannel)
                
                if self.generalChannel != nil {
                    print("3")
                    self.joinGeneralChatRoomWithUniqueName(name: nil, completion: completion)
                } else {
                    print("4")
                    self.createGeneralChatRoomWithCompletion { succeeded in
                        if (succeeded) {
                            self.joinGeneralChatRoomWithUniqueName(name: uniqueName, completion: completion)
                            return
                        }
                        
                        completion(false)
                    }
                }
            }
        }
    }
    
    func joinGeneralChatRoomWithUniqueName(name: String?, completion: @escaping (Bool) -> Void) {
        generalChannel.join { result in
            print("5",result.resultText)
            if ((result.isSuccessful()) && name != nil) {
                print("6")
                self.setGeneralChatRoomUniqueNameWithCompletion(completion: completion)
                return
            }
            completion((result.isSuccessful()))
        }
    }
    
    func createGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        
        let channelName = ChannelManager.defaultChannelName
        let options = [
            TCHChannelOptionFriendlyName: channelName,
            TCHChannelOptionType: TCHChannelType.public.rawValue
            ] as [String : Any]
        channelsList!.createChannel(options: options) { result, channel in
            if (result.isSuccessful()) {
                self.generalChannel = channel
            }
            completion((result.isSuccessful()))
        }
    }
    
    func setGeneralChatRoomUniqueNameWithCompletion(completion:@escaping (Bool) -> Void) {
        generalChannel.setUniqueName(ChannelManager.defaultChannelUniqueName) { result in
            print("7")
            completion((result.isSuccessful()))
        }
    }
    
    // MARK: - Populate channels
    
    func populateChannels() {
        channels = NSMutableOrderedSet()
        
        channelsList?.userChannelDescriptors { result, paginator in
            print("userChannelDescriptors result is",result)
            self.channels?.addObjects(from: paginator!.items())
            self.sortChannels()
        }
        
        channelsList?.publicChannelDescriptors { result, paginator in
             print("publicChannelDescriptors result is",result)
            self.channels?.addObjects(from: paginator!.items())
            self.sortChannels()
        }
        
        if self.delegate != nil {
            self.delegate!.reloadChannelList()
        }
    }
    
    func sortChannels() {
        let sortSelector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
        let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true, selector: sortSelector)
        channels!.sort(using: [descriptor])
    }
    
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        if (name == ChannelManager.defaultChannelName) {
            completion(false, nil)
            return
        }
        
        let channelOptions = [
            TCHChannelOptionFriendlyName: name,
            TCHChannelOptionType: TCHChannelType.public.rawValue
        ] as [String : Any]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        self.channelsList?.createChannel(options: channelOptions) { result, channel in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completion((result.isSuccessful()), channel)
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient, channelAdded channel: TCHChannel) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels!.add(channel)
                self.sortChannels()
            }
            self.delegate?.chatClient(client, channelAdded: channel)
        }
    }
    
    func chatClient(_ client: TwilioChatClient, channel: TCHChannel, updated: TCHChannelUpdate) {
        self.delegate?.chatClient(client, channel: channel, updated: updated)
    }
    
    func chatClient(_ client: TwilioChatClient, channelDeleted channel: TCHChannel) {
        DispatchQueue.main.async {
            if self.channels != nil {
                self.channels?.remove(channel)
            }
            self.delegate?.chatClient(client, channelDeleted: channel)
        }
        
    }
    
    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
    }
}
