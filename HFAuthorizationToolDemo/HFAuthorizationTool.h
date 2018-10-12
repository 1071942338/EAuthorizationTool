//
//  HFAuthorizationTool.h
//  MyLvLiang
//
//  Created by 张文旗 on 2018/10/9.
//  Copyright © 2018 张文旗. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - plist文件描述Key
//定位
extern NSString *const NSLocationWhenInUseUsageDescription;
extern NSString *const NSLocationAlwaysAndWhenInUseUsageDescription;
//相册
extern NSString *const NSPhotoLibraryUsageDescription;
//相机
extern NSString *const NSCameraUsageDescription;
//话筒
extern NSString *const NSMicrophoneUsageDescription;
//蓝牙
extern NSString *const NSBluetoothPeripheralUsageDescription;
//健康
extern NSString *const NSHealthShareUsageDescription;
extern NSString *const NSHealthUpdateUsageDescription;
//家居
extern NSString *const NSHomeKitUsageDescription;
//运动
extern NSString *const NSMotionUsageDescription;
//提醒
extern NSString *const NSRemindersUsageDescription;
//日历
extern NSString *const NSCalendarsUsageDescription;
//联系人
extern NSString *const NSContactsUsageDescription;
//Siri
extern NSString *const NSSiriUsageDescription;
//语音识别
extern NSString *const NSSpeechRecognitionUsageDescription;




typedef void(^AuthorizationResultBlock)(BOOL result);

/**
 授权工具类
 */
@interface HFAuthorizationTool : NSObject
//1、定位服务
-(void)requestWhenInUseAuthorization:(AuthorizationResultBlock)result;
-(void)requestAlwaysAuthorization:(AuthorizationResultBlock)result;
//2、相册
-(void)requestPhotoLibraryAuthorization:(AuthorizationResultBlock)result;

//3、相机
-(void)requestCameraAuthorization:(AuthorizationResultBlock)result;

//4、麦克风
-(void)requestMicrophoneAuthorization:(AuthorizationResultBlock)result;

//5、蓝牙
//-(void)requestBluetoothAuthorization:(AuthorizationResultBlock)result;

//6、健康
-(void)requestHealthAuthorization:(AuthorizationResultBlock)result;

//7、HomeKit

//8、运动与健身

//9、提醒事项
-(void)requestRemindersAuthorization:(AuthorizationResultBlock)result;

//10、日历
-(void)requestCalendarsAuthorization:(AuthorizationResultBlock)result;

//11、通讯录 iOS9
-(void)requestContactsAuthorization:(AuthorizationResultBlock)result;

//12、Siri（需要使用付费的开发者账号才能开启功能 iOS10）
-(void)requestSiriAuthorization:(AuthorizationResultBlock)result;

//13、语音识别 iOS10
-(void)requestSpeechRecognitionAuthorization:(AuthorizationResultBlock)result;

@end

NS_ASSUME_NONNULL_END
