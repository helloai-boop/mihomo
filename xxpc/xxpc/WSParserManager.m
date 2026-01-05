//
//  YDVPNManager.m
//  VPNExtension
//
//  Created by X on 2023/1/15.
//  Copyright © 2023 VP. All rights reserved.
//

#import "WSParserManager.h"
#import <CommonCrypto/CommonCrypto.h>
#import <resolv.h>
#import <sys/sysctl.h>
#import <sys/time.h>
#import <sys/utsname.h>
#import <arpa/inet.h>

static NSString *__apple_vpn_server_address__ = @"com.ai.x.vpn";
static NSString *__apple_vpn_localized_description__ = @"Z Proxy";
static NSString *__apple_ground_container_identifier__ = @"group.com.ai.x.vpn";

typedef void(^YHSetupCompletion)(NETunnelProviderManager *manager);


@interface WSParserManager ()
@property (nonatomic, strong)NSUserDefaults *userDefaults;
@property (nonatomic)BOOL isExtension;
@property (nonatomic)NSInteger notifier;
@property (nonatomic, strong)NSMutableDictionary *info;
@end


@implementation WSParserManager
{
    NETunnelProviderManager *_providerManager;
    NSTimer *_durationTimer;
    NSMutableArray *_dns;
    dispatch_queue_t _worker;
    
}
+(instancetype)sharedManager{
    static WSParserManager *__manager__;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __manager__ = [[self alloc] init];
        [__manager__ configure];
    });
    return __manager__;
}

-(void)configure {
    _dns = [@[@"8.8.4.4", @"8.8.8.8"] mutableCopy];
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:__apple_ground_container_identifier__];
    NSArray *dns = [_userDefaults objectForKey:@"dns"];
    if (dns) {
        _dns = [dns mutableCopy];
        [_userDefaults setObject:dns forKey:@"dns"];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusDidChangeNotification:) name:NEVPNStatusDidChangeNotification object:nil];
    [_userDefaults addObserver:self forKeyPath:@"notifier" options:(NSKeyValueObservingOptionNew) context:nil];
    _worker = dispatch_queue_create("com.jfdream.pinger.queue", DISPATCH_QUEUE_SERIAL);
    
    
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:__apple_ground_container_identifier__];
    
    containerURL = [containerURL URLByAppendingPathComponent:@"Library" isDirectory:true];
    _workingURL = [containerURL URLByAppendingPathComponent:@"Working" isDirectory:true];
    [[NSFileManager defaultManager] createDirectoryAtURL:_workingURL withIntermediateDirectories:YES attributes:nil error:nil];
    
}


-(void)write:(NSString *)log {
    [_userDefaults setObject:log forKey:@"notifier"];
}

-(void)setupVPNManager:(YHSetupCompletion)completion {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (managers.count == 0) {
            [self createVPNConfiguration:completion];
            if (error) {
                NSLog(@"loadAllFromPreferencesWithCompletionHandler: %@", error);
            }
            return;
        }
        [self handlePreferences:managers completion:completion];
    }];
    
}

-(void)setupVPNManager {
    [self setupVPNManager:^(NETunnelProviderManager *manager) { [self setupConnection:manager]; }];
}

-(void)setupConnection:(NETunnelProviderManager *)manager {
    _providerManager = manager;
    NEVPNConnection *connection = manager.connection;
    if (connection.status == NEVPNStatusConnected) {
        _status = YDVPNStatusConnected;
        NETunnelProviderProtocol *protocolConfiguration = (NETunnelProviderProtocol *)_providerManager.protocolConfiguration;
        NSDictionary *copy = protocolConfiguration.providerConfiguration;
        NSDictionary *configuration = copy[@"configuration"];
        _connectedYaml = configuration[@"yaml"];
        _connectedDate = [_userDefaults objectForKey:@"connectedDate"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kApplicationVPNStatusDidChangeNotification" object:nil];
    }
}

-(void)setupExtenstionApplication {
    _isExtension = YES;
    _info = [NSMutableDictionary new];
    _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:__apple_ground_container_identifier__];
    [_userDefaults setObject:NSDate.date forKey:@"connectedDate"];
}

-(void)reenableManager:(YHSetupCompletion)complection {
    if (_providerManager) {
        if(_providerManager.enabled == NO) {
            NSLog(@"providerManager is disabled, so reenable");
            _providerManager.enabled = YES;
            [_providerManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"saveToPreferencesWithCompletionHandler:%@", error);
                }
            }];
        }
        complection(_providerManager);
    }
    else {
        [self setupVPNManager:^(NETunnelProviderManager *manager) {
            [self setupConnection:manager];
            complection(manager);
        }];
    }
}

-(void)connect:(NSString *)yaml {
    NSAssert(yaml.length > 0, @"url can not empty");
    _connectedYaml = yaml;
    [self reenableManager:^(NETunnelProviderManager *manager) {
        if (!manager){
            return;
        }
        [self connectInternal:0 open:YES];
    }];

}

-(void)connectInternal:(NSInteger)action open:(BOOL)open{
    NSString *yaml = _connectedYaml;
    NETunnelProviderSession *connection = (NETunnelProviderSession *)_providerManager.connection;
    NSMutableDictionary *providerConfiguration = @{@"yaml":yaml}.mutableCopy;
    NETunnelProviderProtocol *protocolConfiguration = (NETunnelProviderProtocol *)_providerManager.protocolConfiguration;
    NSMutableDictionary *copy = protocolConfiguration.providerConfiguration.mutableCopy;
    copy[@"configuration"] = providerConfiguration;
    NSLog(@"using: %@", providerConfiguration);
    protocolConfiguration.providerConfiguration = copy;
    [_providerManager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"saveToPreferencesWithCompletionHandler:%@", error);
        }
    }];
    NSError *error = nil;
    if (open) {
        [connection startVPNTunnelWithOptions:providerConfiguration andReturnError:&error];
    }
    else {
        [connection sendProviderMessage:[NSJSONSerialization dataWithJSONObject:providerConfiguration options:(NSJSONWritingPrettyPrinted) error:nil] returnError:&error responseHandler:^(NSData * _Nullable responseData) {
            NSString *x = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSLog(@"sendProviderMessage=>%@", x);
        }];
    }
    if (error) {
        NSLog(@"VPN extension return error:%@, open:%d", error, open);
    }
}

-(void)disconnect {
    _status = YDVPNStatusDisconnecting;
    NETunnelProviderSession *session = (NETunnelProviderSession *)_providerManager.connection;
    [session stopVPNTunnel];
    NSLog(@"disconnect");
}

-(void)connectionStatusDidChangeNotification:(NSNotification *)notification {
    NEVPNConnection *connection = _providerManager.connection;
    switch (connection.status) {
        case NEVPNStatusInvalid:
            _status = YDVPNStatusDisconnected;
            break;
            
        case NEVPNStatusConnected:{
            _status = YDVPNStatusConnected;
            _connectedDate = NSDate.date;
        }
            break;
            
        case NEVPNStatusConnecting: {
            _status = YDVPNStatusConnecting;
        }
            break;
            
        case NEVPNStatusDisconnected:{
            _status = YDVPNStatusDisconnected;
        }
            break;
            
        case NEVPNStatusReasserting:{
            _status = YDVPNStatusDisconnected;
        }
            break;
        case NEVPNStatusDisconnecting: {
            _status = YDVPNStatusDisconnecting;
        }
            break;
            
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kApplicationVPNStatusDidChangeNotification" object:nil];
}

- (void)handlePreferences:(NSArray<NETunnelProviderManager *> * _Nullable)managers completion:(YDProviderManagerCompletion)completion{
    NETunnelProviderManager *manager;
    for (NETunnelProviderManager *item in managers) {
        if ([item.localizedDescription isEqualToString:__apple_vpn_localized_description__]) {
            manager = item;
            break;
        }
    }
    if (manager.enabled == NO) {
        manager.enabled = YES;
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            completion(manager);
        }];
    }
    else {
        completion(manager);
    }
}

- (void)createVPNConfiguration:(YDProviderManagerCompletion)completion {
        
    NETunnelProviderManager *manager = [NETunnelProviderManager new];
    NETunnelProviderProtocol *protocolConfiguration = [NETunnelProviderProtocol new];
    
    protocolConfiguration.serverAddress = __apple_vpn_server_address__;
    protocolConfiguration.providerConfiguration = @{};
    manager.protocolConfiguration = protocolConfiguration;

    manager.localizedDescription = __apple_vpn_localized_description__;
    manager.enabled = YES;
    [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"saveToPreferencesWithCompletionHandler:%@", error);
            completion(nil);
            return;
        }
        [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            
            if (error) {
                NSLog(@"loadFromPreferencesWithCompletionHandler:%@", error);
                completion(nil);
            }
            else {
                completion(manager);
            }
        }];
    }];
}

-(void)echo {
    NETunnelProviderSession *connection = (NETunnelProviderSession *)_providerManager.connection;
    if (!connection) return;
    NSDictionary *echo = @{@"type":@1};
    NSError *error;
    [connection sendProviderMessage:[NSJSONSerialization dataWithJSONObject:echo options:(NSJSONWritingPrettyPrinted) error:nil] returnError:&error responseHandler:^(NSData * _Nullable responseData) {
        NSString *x = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", x);
    }];
    if (error) {
        NSLog(@"echo sendProviderMessage: %@", error);
    }
}
@end
