//
//  YSFPushManager.h
//  YunShiFinance
//
//  Created by Apple on 2018/9/14.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSFPushModel:NSObject
@property (nonatomic, assign) NSInteger openType;
@property (nonatomic, strong) NSString *pushTime;
@property (nonatomic, assign) NSInteger messageType;
@property (nonatomic, strong) NSString *webUrl;
@property (nonatomic, strong) NSString *detailId;

/*
 'openType' => '1', //0 app内  1打开浏览器
 'pushTime' => $time,
 'messsageType' => '20', //10.系统消息；20.新闻详情；30.快讯；40.项目详情；50.视频详情；60.标签详情
 'webUrl' => 'http://web.yunshi24.com/news/detail/1159.html',
 'detailId' => '1159',
 */
- (instancetype)initWithDict:(NSDictionary *)dict;
@end

@interface YSFPushManager : NSObject

@property (nonatomic ,strong) NSString *uniqueIdentifier;  //唯一标识,可以用于做别名推送
@property (nonatomic ,copy) void(^otherHandleRemoteNotificationCompletionHandler)(NSDictionary *remoteInfo); //  获取得到消息后的其他操作
@property (nonatomic ,copy) BOOL(^isOpenPushHandler)(NSDictionary *remoteInfo); //  判断消息类型，判断是否需要响应推送内容

+(YSFPushManager *)shareJPushManager;
//  是否开启推送
- (BOOL)isOpenPush;
- (void)setIsOpenPush:(BOOL)isOpenPush;

//  是否开启提示音
- (BOOL)isOpenSound;
- (void)setIsOpenSound:(BOOL)isOpenSound;

//  是否开启某个推送
- (BOOL)isOpenPushOfKey:(NSString *)key;
- (void)setIsOpenPush:(BOOL)isOpenPush forKey:(NSString *)key;


// 在应用启动的时候调用
- (void)ysf_setupWithOption:(NSDictionary *)launchingOption
                     appKey:(NSString *)appKey
                    channel:(NSString *)channel
           apsForProduction:(BOOL)isProduction
      advertisingIdentifier:(NSString *)advertisingId;

// 在appdelegate注册设备处调用
- (void)ysf_registerDeviceToken:(NSData *)deviceToken;

//设置角标
- (void)ysf_setBadge:(int)badge;

//获取注册ID
- (void)ysf_getRegisterIDCallBack:(void(^)(NSString *registerID))completionHandler;


//处理推送信息
- (void)ysf_handleRemoteNotification:(NSDictionary *)remoteInfo;
- (void)ysf_handleRemoteNotification:(NSDictionary *)remoteInfo completionHandler:(void(^)(NSDictionary *remoteInfo))completionHandler;

@end
