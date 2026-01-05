//
//  YDVPNManager.h
//  VPNExtension
//
//  Created by X on 2023/1/15.
//  Copyright © 2023 VP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^YDProviderManagerCompletion)(NETunnelProviderManager *_Nullable manager);

typedef enum : NSUInteger {
    YDVPNStatusIDLE = 0,
    YDVPNStatusConnecting,
    YDVPNStatusConnected,
    YDVPNStatusDisconnecting,
    YDVPNStatusDisconnected
} YDVPNStatus;


@interface WSParserManager : NSObject

+(instancetype)sharedManager;

-(void)setupVPNManager;

@property (nonatomic, readonly)YDVPNStatus status;

@property (nonatomic, strong, readonly)NSString *connectedYaml;

@property (nonatomic, strong, readonly)NSDate *connectedDate;

@property (nonatomic, strong, readonly)NSURL *workingURL;

-(void)connect:(NSString *)yaml;

-(void)disconnect;

-(void)echo;

@end

// Call in network extension
@interface WSParserManager (Extension)

-(void)setupExtenstionApplication;
@end


NS_ASSUME_NONNULL_END
