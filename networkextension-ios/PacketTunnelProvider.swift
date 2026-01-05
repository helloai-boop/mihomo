//
//  PacketTunnelProvider.swift
//  networkextension-ios
//
//  Created by x on 2026/1/3.
//

import NetworkExtension
import Mihomo
import xxpc
import OSLog

class PacketTunnelProvider: NEPacketTunnelProvider, MihomoPlatformInterfaceProtocol {
    
    var _completionHandler:((Error?)->Void)?;
    
    private let logger = OSLog(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "packet-tunnel"
    )
    
    func simpleIncrementIP(_ ip: String) -> String {
        var components = ip.split(separator: ".").map { String($0) }
        guard components.count == 4, let lastOctet = Int(components[3]), lastOctet >= 0 && lastOctet <= 255 else {
            return ip
        }
        if lastOctet < 255 {
            components[3] = String(lastOctet + 1)
        }
        return components.joined(separator: ".")
    }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Add code here to start the process of connecting the tunnel.
        
        WSParserManager.shared().setupExtenstionApplication();
        var op:[String:Any]? = options;
        if (options == nil) {
            if let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol {
                op = protocolConfiguration.providerConfiguration;
            }
        }
        guard let config = op?["yaml"] as? String else {
            completionHandler(NSError(domain: "Invalid Configuration", code: -1002));
            return;
        }
        _completionHandler = completionHandler;
        DispatchQueue.global().async { MihomoStartVPN(self, WSParserManager.shared().workingURL.path, config); }
    }
    
    @objc func print(_ log:String?) {
        guard let msg = log else { return ; }
        os_log("UTUN: %{public}@", log: logger, type: .info, msg)
    }
    
    public func openTun(_ options: MihomoTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
        guard let options else {
            throw NSError(domain: "nil options", code: 0)
        }
        guard let ret0_ else {
            throw NSError(domain: "nil return pointer", code: 0)
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        if options.getAutoRoute() {
            settings.mtu = NSNumber(value: options.getMTU())
            let ip = options.getIPv4Address();
            let dns = simpleIncrementIP(ip)
            let dnsSettings = NEDNSSettings(servers: [dns])
            dnsSettings.matchDomains = [""]
            dnsSettings.matchDomainsNoSearch = true
            settings.dnsSettings = dnsSettings

            let ipv4Address: [String] = [options.getIPv4Address()]
            let ipv4Mask: [String] = [options.getIPv4Mask()]

            let ipv4Settings = NEIPv4Settings(addresses: ipv4Address, subnetMasks: ipv4Mask)
            var ipv4Routes: [NEIPv4Route] = []
            let ipv4ExcludeRoutes: [NEIPv4Route] = []

            ipv4Routes.append(NEIPv4Route.default())

            ipv4Settings.includedRoutes = ipv4Routes
            ipv4Settings.excludedRoutes = ipv4ExcludeRoutes
            settings.ipv4Settings = ipv4Settings

            let ipv6Address: [String] = [options.getIPv6Address()]
            let ipv6Prefixes: [NSNumber] = [NSNumber(value: options.getIPv6Prefix())]
       
            let ipv6Settings = NEIPv6Settings(addresses: ipv6Address, networkPrefixLengths: ipv6Prefixes)
            var ipv6Routes: [NEIPv6Route] = []
            let ipv6ExcludeRoutes: [NEIPv6Route] = []

            ipv6Routes.append(NEIPv6Route.default())

            ipv6Settings.includedRoutes = ipv6Routes
            ipv6Settings.excludedRoutes = ipv6ExcludeRoutes
            settings.ipv6Settings = ipv6Settings
        }

        let semaphore = DispatchSemaphore(value: 0)
        var settingsError: Error?

        self.setTunnelNetworkSettings(settings) { error in
            settingsError = error
            if let error = error {
                os_log("UTUN: Failed to set tunnel network settings: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            } else {
                os_log("UTUN: Successfully set tunnel network settings", log: self.logger, type: .info)
            }
            semaphore.signal()
            self._completionHandler?(error)
        }

        _ = semaphore.wait(timeout: .now() + 10)

        if let error = settingsError {
            throw error
        }

        if let tunFd = self.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32 {
            os_log("UTUN: Got FD from packetFlow: %d", log: self.logger, type: .info, tunFd)
            ret0_.pointee = tunFd
            return
        }

        let tunFdFromLoop = MihomoGetTunnelFileDescriptor()
        if tunFdFromLoop != -1 {
            os_log("UTUN: Got FD from loop: %d", log: self.logger, type: .info, tunFdFromLoop)
            ret0_.pointee = tunFdFromLoop
        } else {
            os_log("UTUN: Failed to get file descriptor", log: self.logger, type: .error)
            throw NSError(domain: "missing file descriptor", code: 0)
        }
    }

    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
}
