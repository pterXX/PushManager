//
//  YSFPushManager.m
//  YunShiFinance
//
//  Created by Apple on 2018/9/14.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import "YSFPushManager.h"
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#define YSFPushSettingPlistKeys  @"YSFPushSettingPlistKeys"
#define YSFPushManagerIsOpenPush @"YSFPushManagerIsOpenPush"  //  是否开启推送
#define YSFPushManagerIsOpenSound @"YSFPushManagerIsOpenSound" //  是否开启提示音

@implementation YSFPushModel
- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.openType = [dict[@"openType"] integerValue];
        self.pushTime = dict[@"pushTime"];
        self.messageType = [dict[@"messageType"] integerValue];
        self.webUrl = dict[@"webUrl"];
        self.detailId = [NSString stringWithFormat:@"%@",dict[@"detailId"]];
    }
    return self;
}
@end

@interface YSFPushManager()<JPUSHRegisterDelegate>
@property (nonatomic ,strong) NSDictionary *launchingOption;  //  启动的参数
@property (nonatomic ,strong) NSString *appKey;   //  appKey
@property (nonatomic ,strong) NSString *channel;  //  渠道
@property (nonatomic ,assign) BOOL isProduction;  //  是否是开发环境
@property (nonatomic ,strong) NSString *advertisingId;  //  广告标识
@end
@implementation YSFPushManager

+ (YSFPushManager *)shareJPushManager{
    static YSFPushManager * JPushTool = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JPushTool = [[YSFPushManager alloc] init];
    });
    
    return JPushTool;
}

- (void)setUniqueIdentifier:(NSString *)uniqueIdentifier{
    if (_uniqueIdentifier) {
        //  如果本身已经唯一标识，可以先赋值，在通知改变推送的设备别名
        _uniqueIdentifier =  uniqueIdentifier;
        [[NSNotificationCenter defaultCenter] postNotificationName:kJPFNetworkDidLoginNotification object:nil userInfo:nil];
    }else{
        _uniqueIdentifier = uniqueIdentifier;
    }
}

//  判断是否开启的推送
- (BOOL)isOpenPush{
    return [self isOpenPushOfKey:YSFPushManagerIsOpenPush];
}
- (void)setIsOpenPush:(BOOL)isOpenPush{
    [self setIsOpenPush:isOpenPush forKey:YSFPushManagerIsOpenPush];
}

//  判断是否开启的推送
- (BOOL)isOpenSound{
    return [self isOpenPushOfKey:YSFPushManagerIsOpenSound];
}

- (void)setIsOpenSound:(BOOL)isOpenSound{
    [self setIsOpenPush:isOpenSound forKey:YSFPushManagerIsOpenSound];
}

- (BOOL)isOpenPushOfKey:(NSString *)key{
    NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] objectForKey:YSFPushSettingPlistKeys] mutableCopy];
    NSString *str = dict[key];
    if (str == nil) {
        [self setIsOpenPush:YES forKey:key];
        str = @"1";
    }
    return [str boolValue];
}

- (void)setIsOpenPush:(BOOL)isOpenPush forKey:(NSString *)key{
    NSMutableDictionary *dict = [[[NSUserDefaults standardUserDefaults] objectForKey:YSFPushSettingPlistKeys] mutableCopy];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    [dict setObject:isOpenPush?@"1":@"0" forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:YSFPushSettingPlistKeys];
    [self ysf_setupWithOption:self.launchingOption appKey:self.appKey channel:self.channel apsForProduction:self.isProduction advertisingIdentifier:self.advertisingId];
}


// 在应用启动的时候调用
- (void)ysf_setupWithOption:(NSDictionary *)launchingOption
                     appKey:(NSString *)appKey
                    channel:(NSString *)channel
           apsForProduction:(BOOL)isProduction
      advertisingIdentifier:(NSString *)advertisingId
{
    self.launchingOption = launchingOption;
    self.appKey = appKey;
    self.channel = channel;
    self.isProduction = isProduction;
    self.advertisingId = advertisingId;
    if ([self isOpenPush]) {
        //  开启推送
        JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
        NSInteger types = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge|UNAuthorizationOptionSound;
        if ([self isOpenSound] == NO) {
            // 关闭提示音
            types = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge;
        }
        entity.types = types;
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
            // 可以添加自定义categories
            // NSSet<UNNotificationCategory *> *categories for iOS10 or later
            // NSSet<UIUserNotificationCategory *> *categories for iOS8 and iOS9
        }
        
        [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
        [JPUSHService setupWithOption:launchingOption appKey:appKey channel:channel apsForProduction:isProduction advertisingIdentifier:advertisingId];
        [[UIApplication sharedApplication] registerForRemoteNotifications]; //  注册代码
        //  极光推送登录成功后的操作
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkDidLoginNotification:) name:kJPFNetworkDidLoginNotification object:nil];
    }else{
        //  关闭推送
        [[UIApplication sharedApplication] unregisterForRemoteNotifications]; //  反注册代码
    }
    
    return;
}

// 在appdelegate注册设备处调用
- (void)ysf_registerDeviceToken:(NSData *)deviceToken
{
    [JPUSHService registerDeviceToken:deviceToken];
    return;
    
}

//设置角标
- (void)ysf_setBadge:(int)badge
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    [JPUSHService setBadge:badge];
}

//获取注册ID
- (void)ysf_getRegisterIDCallBack:(void(^)(NSString *registerID))completionHandler
{
    [JPUSHService registrationIDCompletionHandler:^(int resCode, NSString *registrationID) {
        if (resCode == 0) {
            NSLog(@"registrationID获取成功：%@",registrationID);
            completionHandler?completionHandler(registrationID):nil;
        }
    }];
    
}

//处理推送信息
- (void)ysf_handleRemoteNotification:(NSDictionary *)remoteInfo {
    [self ysf_handleRemoteNotification:remoteInfo completionHandler:self.otherHandleRemoteNotificationCompletionHandler];
}

- (void)ysf_handleRemoteNotification:(NSDictionary *)remoteInfo completionHandler:(void(^)(NSDictionary *remoteInfo))completionHandler
{
    if ([self isOpenPush]) { //  是否接受推送
        NSMutableDictionary *dict =  remoteInfo.mutableCopy;
        if ([self isOpenSound] == NO) { //  关闭提示音
            [dict setObject:@"" forKey:@"sound"];
        }
        if (completionHandler) {
            completionHandler(dict);
        }
        
        BOOL isOpenPush = YES;
        if (self.isOpenPushHandler) {
            isOpenPush = self.isOpenPushHandler(dict);
        }
        if (isOpenPush) {
            [JPUSHService handleRemoteNotification:dict];
        }
    }
    [self ysf_setBadge:0];
}



#pragma mark JPUSHRegisterDelegate
// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger options))completionHandler
{
    if ([self isOpenPush]) {
        // Required
        NSDictionary * userInfo = notification.request.content.userInfo;
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [self ysf_handleRemoteNotification:userInfo];
        }
        completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
    }
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    if ([self isOpenPush]) {
        // Required
        NSDictionary * userInfo = response.notification.request.content.userInfo;
        if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [self ysf_handleRemoteNotification:userInfo];
        }
        completionHandler();  // 系统要求执行这个方法
    }
}

// JPush 监听登陆成功后设置别名和标签
- (void)networkDidLoginNotification:(NSNotification *)notification {
#ifdef DEBUG
    NSSet *tagsSet = [NSSet setWithObjects:@"10086", nil];
    [JPUSHService setTags:tagsSet completion:^(NSInteger iResCode, NSSet *iTags, NSInteger seq) {
        YSFLog(@"iResCode  %ld, iTags %@, iAlias  %ld",(long)iResCode,iTags ,(long)seq);
    } seq:0];
#else
#endif
    if (self.uniqueIdentifier) {
        [JPUSHService setAlias:self.uniqueIdentifier completion:^(NSInteger iResCode, NSString *iAlias, NSInteger seq) {
            NSString *callbackString =
            [NSString stringWithFormat:@"%ld, \nalias: %@\n", (long)iResCode,iAlias];
            YSFLog(@"TagsAlias回调:%@", callbackString);
        } seq:1];
    }
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kJPFNetworkDidLoginNotification
                                                  object:nil];
}

@end
