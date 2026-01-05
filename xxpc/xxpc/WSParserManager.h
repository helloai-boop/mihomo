//
//  YDVPNManager.h
//  VPNExtension
//
//  Created by X on 2023/1/15.
//  Copyright © 2023 RongVP. All rights reserved.
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

/// Manager
+(instancetype)sharedManager;

// 主进程调用，扩展进程不要调
-(void)setupVPNManager;

/// 当前连接状态
@property (nonatomic, readonly)YDVPNStatus status;

/// 当前连接节点
@property (nonatomic, strong, readonly)NSString *connectedYaml;

/// 连接 VPN 的时间
@property (nonatomic, strong, readonly)NSDate *connectedDate;


@property (nonatomic, strong, readonly)NSURL *workingURL;

/// 开始连接
/// - Parameter url: 节点 URL
-(void)connect:(NSString *)yaml;

/// 断开连接
-(void)disconnect;

/// 向扩展进程发送活跃检查，DEBU 时使用
-(void)echo;

@end

// 下面节点是在扩展进程中调用的接口
@interface WSParserManager (Extension)

/// 扩展进程调用，主进程不要调
/// - Parameter ips: url 列表
/// - Parameter type: 0 ICMP, 1 TCP
-(void)ping:(NSArray *)ips type:(int)type;

/// 扩展进程调用，主进程不要调
-(void)setupExtenstionApplication;


-(void)write:(NSString *)log;
@end


NS_ASSUME_NONNULL_END
