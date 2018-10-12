//
//  HFAuthorizationTool.m
//  MyLvLiang
//
//  Created by 张文旗 on 2018/10/9.
//  Copyright © 2018 张文旗. All rights reserved.
//

#import "HFAuthorizationTool.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <HealthKit/HealthKit.h>
#import <HomeKit/HomeKit.h>
#import <EventKit/EventKit.h>
#import <Contacts/Contacts.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Intents/Intents.h>
#import <Speech/Speech.h>
#import <CoreMotion/CoreMotion.h>


#pragma mark - plist文件描述Key
NSString *const NSLocationWhenInUseUsageDescription         = @"NSLocationWhenInUseUsageDescription";                
NSString *const NSLocationAlwaysAndWhenInUseUsageDescription   = @"NSLocationAlwaysAndWhenInUseUsageDescription";
NSString *const NSPhotoLibraryUsageDescription              = @"NSPhotoLibraryUsageDescription";
NSString *const NSCameraUsageDescription                    = @"NSCameraUsageDescription";
NSString *const NSMicrophoneUsageDescription                = @"NSMicrophoneUsageDescription";
NSString *const NSBluetoothPeripheralUsageDescription       = @"NSBluetoothPeripheralUsageDescription";
NSString *const NSHealthShareUsageDescription               = @"NSHealthShareUsageDescription";
NSString *const NSHealthUpdateUsageDescription              = @"NSHealthUpdateUsageDescription";
NSString *const NSHomeKitUsageDescription                   = @"NSHomeKitUsageDescription";
NSString *const NSMotionUsageDescription                    = @"NSMotionUsageDescription";
NSString *const NSRemindersUsageDescription                 = @"NSRemindersUsageDescription";
NSString *const NSCalendarsUsageDescription                 = @"NSCalendarsUsageDescription";
NSString *const NSContactsUsageDescription                  = @"NSContactsUsageDescription";
NSString *const NSSiriUsageDescription                      = @"NSSiriUsageDescription";
NSString *const NSSpeechRecognitionUsageDescription         = @"NSSpeechRecognitionUsageDescription";
NSString *const NSVideoSubscriberAccountUsageDescription    = @"NSVideoSubscriberAccountUsageDescription";


@interface HFAuthorizationTool ()<CLLocationManagerDelegate,CBCentralManagerDelegate>

@property(nonatomic,strong)CLLocationManager *locationManager;
@property(nonatomic,copy)AuthorizationResultBlock locationAlwaysResultBlock;
@property(nonatomic,copy)AuthorizationResultBlock locationInuseResultBlock;

@property(nonatomic,copy)AuthorizationResultBlock photoLibraryResultBlock;
@property(nonatomic,copy)AuthorizationResultBlock cameraResultBlock;

@property(nonatomic,strong)AVAudioSession *audioSession;
@property(nonatomic,copy)AuthorizationResultBlock microphoneResultBlock;

@property(nonatomic,strong)CBCentralManager *centralManager;
@property(nonatomic,copy)AuthorizationResultBlock bluetoothResultBlock;

@property(nonatomic,strong)HKHealthStore *healthStore;
@property(nonatomic,copy)AuthorizationResultBlock healthResultBlock;

@property(nonatomic,strong)EKEventStore *remindersEventStore;
@property(nonatomic,copy)AuthorizationResultBlock remindersResultBlock;

@property(nonatomic,strong)EKEventStore *calendarsEventStore;
@property(nonatomic,copy)AuthorizationResultBlock calendarsResultBlock;

@property(nonatomic,strong)CNContactStore *contactStore;
@property(nonatomic,copy)AuthorizationResultBlock contactStoreResultBlock;

@property(nonatomic,copy)AuthorizationResultBlock siriStoreResultBlock;

@property(nonatomic,copy)AuthorizationResultBlock speechRecognizerResultBlock;


@end

@implementation HFAuthorizationTool


#pragma mark - 定位
/**
* 请求一直使用
* 1.授权状态为NotDetermined时调用，弹框获取用户授权；如果用户之前是WhenInUse状态，可以调用一次该方法。其他状态调用无效
* 2.任何状态更改通知回调方法didChangeAuthorizationStatus
* 3.一直使用，即使被杀死也会重启，谨慎使用
* 4.无法调用区域检测等接口，后台状态无法调用startUpdatingLocation方法
* 5.NSLocationWhenInUseUsageDescription和NSLocationAlwaysAndWhenInUseUsageDescription必须存在否则调用无效
*/
-(void)requestAlwaysAuthorization:(AuthorizationResultBlock)result{
 
    if (result) {
        self.locationAlwaysResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSLocationWhenInUseUsageDescription];
    [self isHaveUsageDescriptionInPlistByKey:NSLocationAlwaysAndWhenInUseUsageDescription];
    //2.获取状态
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    //3.根据状态进行逻辑选择
    [self reportLocationServicesAuthorizationStatus:status];
}


/**
 *请求应用打开期间使用
 * 1.授权状态为NotDetermined时调用，弹框获取用户授权，其他状态调用无效
 * 2.任何状态更改通知回调方法didChangeAuthorizationStatus
 * 3.如果进入后台时在更新位置，状态显示小箭头的使用标志，直到正常停止或者应用被杀死
 * 4.无法调用区域检测等接口，后台状态无法调用startUpdatingLocation方法
 * 5.NSLocationWhenInUseUsageDescription必须存在否则调用无效
 */
-(void)requestWhenInUseAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.locationInuseResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSLocationWhenInUseUsageDescription];
    //2.获取状态
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    //3.根据状态进行逻辑选择
    [self reportLocationServicesAuthorizationStatus:status];
    
}

- (void)reportLocationServicesAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.locationInuseResultBlock) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        
        if (self.locationAlwaysResultBlock) {
            [self.locationManager requestAlwaysAuthorization];
        }
        
    }
    else if (status == kCLAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
        
    }
    else if (status == kCLAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == kCLAuthorizationStatusAuthorizedAlways){
        //授权随时使用:打开设置页面请求用户更改授权

        
        if (self.locationAlwaysResultBlock) {
            self.locationAlwaysResultBlock(YES);
            self.locationAlwaysResultBlock = nil;
        }
        else{
            [self openSettingApp];
        }
        
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse){
        //授权APP运行时使用:返回成功进入下面的业务逻辑
        
        if (self.locationInuseResultBlock) {
            self.locationInuseResultBlock(YES);
            self.locationInuseResultBlock = nil;
        }
        else
        {
            [self openSettingApp];
        }

    }else{
        //
    }
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //状态更改后，重新进入检测授权逻辑
    [self reportLocationServicesAuthorizationStatus:status];
}

#pragma mark - 相册

-(void)requestPhotoLibraryAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.photoLibraryResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSPhotoLibraryUsageDescription];
    //2.获取状态
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    //3.根据状态进行逻辑选择
    [self reportPhotoLibraryServicesAuthorizationStatus:status];
    
}

- (void)reportPhotoLibraryServicesAuthorizationStatus:(PHAuthorizationStatus)status{
    if (status == PHAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.photoLibraryResultBlock) {

            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [self reportPhotoLibraryServicesAuthorizationStatus:status];
            }];
        }
    }
    else if (status == PHAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
        
    }
    else if (status == PHAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == PHAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.photoLibraryResultBlock) {
            self.photoLibraryResultBlock(YES);
            self.photoLibraryResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - 相机

-(void)requestCameraAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.cameraResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSCameraUsageDescription];
    //2.获取状态
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    //3.根据状态进行逻辑选择
    [self reportCameraServicesAuthorizationStatus:status];
    
}

- (void)reportCameraServicesAuthorizationStatus:(AVAuthorizationStatus)status{
    if (status == AVAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.cameraResultBlock) {
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                [self reportCameraServicesAuthorizationStatus:status];
            }];

        }
    }
    else if (status == AVAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
        
    }
    else if (status == AVAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == AVAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.cameraResultBlock) {
            self.cameraResultBlock(YES);
            self.cameraResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - 麦克风

-(void)requestMicrophoneAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.microphoneResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSMicrophoneUsageDescription];
    //2.获取状态
    AVAudioSessionRecordPermission permission = [self.audioSession recordPermission];
    //3.根据状态进行逻辑选择
    [self reportMicrophoneServicesAuthorizationStatus:permission];
    
}

- (void)reportMicrophoneServicesAuthorizationStatus:(AVAudioSessionRecordPermission)status{
    if (status == AVAudioSessionRecordPermissionUndetermined) {
        //未作出选择:请求用户授权
        if (self.microphoneResultBlock) {
            
            [self.audioSession requestRecordPermission:^(BOOL granted) {
                AVAudioSessionRecordPermission permission = [self.audioSession recordPermission];
                [self reportMicrophoneServicesAuthorizationStatus:permission];
            }];
            
        }
    }
    else if (status == AVAudioSessionRecordPermissionDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == AVAudioSessionRecordPermissionGranted){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.microphoneResultBlock) {
            self.microphoneResultBlock(YES);
            self.microphoneResultBlock = nil;
        }
    }
    else{
        //
    }
}


#pragma mark - 蓝牙

-(void)requestBluetoothAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.bluetoothResultBlock = result;
    }
    
//    CBManagerStateUnknown = 0,
//    CBManagerStateResetting,
//    CBManagerStateUnsupported,
//    CBManagerStateUnauthorized,
//    CBManagerStatePoweredOff,
//    CBManagerStatePoweredOn,
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSBluetoothPeripheralUsageDescription];
    //2.获取状态
    CBManagerState status =  [self.centralManager state];
    //3.根据状态进行逻辑选择
//    [self reportBluetoothServicesAuthorizationStatus:status];
    
}

- (void)reportBluetoothServicesAuthorizationStatus:(CBManagerState)status{
    if (status == CBManagerStateUnknown) {
        //状态未知，过一会变化:请求用户授权
//        if (self.bluetoothResultBlock) {
//            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
//        }
//        [self openSettingApp];
        CBManagerState status =  [self.centralManager state];
        [self reportBluetoothServicesAuthorizationStatus:status];

    }
    else if (status == CBManagerStateResetting){
        //重置:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == CBManagerStateUnsupported){
        //不支持:打开设置页面请求用户授权
//        [self openSettingApp];
        NSLog(@"不支持蓝牙功能");
    }
    else if (status == CBManagerStateUnauthorized){
        //未授权:打开设置页面请求用户授权
//        [self openSettingApp];
        if (self.bluetoothResultBlock) {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
    else if (status == CBManagerStatePoweredOff){
        //未打开:打开设置页面请求打开
        [self openSettingApp];
    }
    else if (status == CBManagerStatePoweredOn){
        //已打开:打开设置页面请求用户授权
//        [self openSettingApp];
        if (self.bluetoothResultBlock) {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
    else if (status == CBPeripheralManagerAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.bluetoothResultBlock) {
            self.bluetoothResultBlock(YES);
            self.bluetoothResultBlock = nil;
        }
    }
    else{
        //
    }
}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    CBManagerState status = [central state];

    NSLog(@"centralManagerDidUpdateState:%ld",status);
    
    if (status == CBManagerStateUnknown) {
        //状态未知，过一会变化:请求用户授权
        //        if (self.bluetoothResultBlock) {
        //            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        //        }
        //        [self openSettingApp];
        CBManagerState status =  [self.centralManager state];
        [self reportBluetoothServicesAuthorizationStatus:status];
        
    }
    else if (status == CBManagerStateResetting){
        //重置:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == CBManagerStateUnsupported){
        //不支持:打开设置页面请求用户授权
        //        [self openSettingApp];
        NSLog(@"不支持蓝牙功能");
    }
    else if (status == CBManagerStateUnauthorized){
        //未授权:打开设置页面请求用户授权
        //        [self openSettingApp];
        if (self.bluetoothResultBlock) {
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
    else if (status == CBManagerStatePoweredOff){
        //未打开:打开设置页面请求打开
//        [self openSettingApp];
    }
    else if (status == CBManagerStatePoweredOn){
        //已打开:打开设置页面请求用户授权
        //        [self openSettingApp];
        if (self.bluetoothResultBlock) {
            NSLog(@"%@",@"求蓝牙权限");
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
//        [self openSettingApp];
        [[[CBPeripheralManager alloc] init] startAdvertising:nil];

    }
    else if (status == CBPeripheralManagerAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.bluetoothResultBlock) {
            self.bluetoothResultBlock(YES);
            self.bluetoothResultBlock = nil;
        }
    }
    else{
        //
    }
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"didDiscoverPeripheral:%@",advertisementData);
}
#pragma mark - 健康
+ (BOOL)isHealthDataAvailable
{
    return [HKHealthStore isHealthDataAvailable];
}

-(void)requestHealthAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.healthResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSHealthShareUsageDescription];
    //2.获取状态
    HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:type];
    //3.根据状态进行逻辑选择
    [self reportHealthServicesAuthorizationStatus:status];
    
}

- (void)reportHealthServicesAuthorizationStatus:(HKAuthorizationStatus)status{
    if (status == HKAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.healthResultBlock) {
            HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
            [self.healthStore requestAuthorizationToShareTypes:[NSSet setWithObject:type] readTypes:[NSSet setWithObject:type] completion:^(BOOL success, NSError * _Nullable error) {
                
                HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:type];
                [self reportHealthServicesAuthorizationStatus:status];
            }];
        }
    }
    else if (status == HKAuthorizationStatusSharingDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == HKAuthorizationStatusSharingAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.healthResultBlock) {
            self.healthResultBlock(YES);
            self.healthResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - HomeKit


-(void)requestHomeKitAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.bluetoothResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSHomeKitUsageDescription];
    //2.获取状态
    HKQuantityType *type = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    HKAuthorizationStatus status = [self.healthStore authorizationStatusForType:type];
    //3.根据状态进行逻辑选择
    [self reportHealthServicesAuthorizationStatus:status];
    
}

- (void)reportHomeKitServicesAuthorizationStatus:(HKAuthorizationStatus)status{
    if (status == HKAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.bluetoothResultBlock) {
            
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
    else if (status == HKAuthorizationStatusSharingDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == HKAuthorizationStatusSharingAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.bluetoothResultBlock) {
            self.bluetoothResultBlock(YES);
            self.bluetoothResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - HomeKit
#pragma mark - 运动与健身
-(void)requestMotionAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.remindersResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSMotionUsageDescription];
    //2.获取状态
    CMAuthorizationStatus status = [CMMotionActivityManager authorizationStatus];
    
    
    //3.根据状态进行逻辑选择
    [self reportRemindersServicesAuthorizationStatus:status];
    
}

- (void)reportMotionServicesAuthorizationStatus:(CMAuthorizationStatus)status{
    if (status == EKAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.remindersResultBlock) {
            
            [self.remindersEventStore requestAccessToEntityType:EKEntityTypeReminder
                                                     completion:^(BOOL granted, NSError * _Nullable error) {
                                                         EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
                                                         [self reportRemindersServicesAuthorizationStatus:status];
                                                     }];
            
        }
    }
    else if (status == EKAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.remindersResultBlock) {
            self.remindersResultBlock(YES);
            self.remindersResultBlock = nil;
        }
    }
    else{
        //
    }
}
#pragma mark - 提醒事项

-(void)requestRemindersAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.remindersResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSRemindersUsageDescription];
    //2.获取状态    
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
    //3.根据状态进行逻辑选择
    [self reportRemindersServicesAuthorizationStatus:status];
    
}

- (void)reportRemindersServicesAuthorizationStatus:(EKAuthorizationStatus)status{
    if (status == EKAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.remindersResultBlock) {
            
            [self.remindersEventStore requestAccessToEntityType:EKEntityTypeReminder
                                                     completion:^(BOOL granted, NSError * _Nullable error) {
                                                         EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
                                                         [self reportRemindersServicesAuthorizationStatus:status];
                                                     }];
            
        }
    }
    else if (status == EKAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.remindersResultBlock) {
            self.remindersResultBlock(YES);
            self.remindersResultBlock = nil;
        }
    }
    else{
        //
    }
}
#pragma mark - 日历
-(void)requestCalendarsAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.calendarsResultBlock = result;
    }
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSCalendarsUsageDescription];
    //2.获取状态
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    //3.根据状态进行逻辑选择
    [self reportCalendarsServicesAuthorizationStatus:status];
    
}

- (void)reportCalendarsServicesAuthorizationStatus:(EKAuthorizationStatus)status{
    if (status == EKAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.calendarsResultBlock) {
            
            [self.remindersEventStore requestAccessToEntityType:EKEntityTypeEvent
                                                     completion:^(BOOL granted, NSError * _Nullable error) {
                                                         EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
                                                         [self reportRemindersServicesAuthorizationStatus:status];
                                                     }];
            
        }
    }
    else if (status == EKAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == EKAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.calendarsResultBlock) {
            self.calendarsResultBlock(YES);
            self.calendarsResultBlock = nil;
        }
    }
    else{
        //
    }
}
#pragma mark - 通讯录
-(void)requestContactsAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.contactStoreResultBlock = result;
    }
    

    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSContactsUsageDescription];
    //2.获取状态
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    //3.根据状态进行逻辑选择
    [self reportContactsServicesAuthorizationStatus:status];



    
}

- (void)reportContactsServicesAuthorizationStatus:(CNAuthorizationStatus)status{
    if (status == CNAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.contactStoreResultBlock) {
            
            [self.contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
                [self reportContactsServicesAuthorizationStatus:status];
            }];
            
        }
    }
    else if (status == CNAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == CNAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == CNAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.contactStoreResultBlock) {
            self.contactStoreResultBlock(YES);
            self.contactStoreResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - Siri

-(void)requestSiriAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.siriStoreResultBlock = result;
    }
    
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSSiriUsageDescription];
    //2.获取状态
    INSiriAuthorizationStatus status = [INPreferences siriAuthorizationStatus];
    //3.根据状态进行逻辑选择
    [self reportSiriServicesAuthorizationStatus:status];
    
    
}

- (void)reportSiriServicesAuthorizationStatus:(INSiriAuthorizationStatus)status{
    if (status == INSiriAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.siriStoreResultBlock) {
            
            [INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
                [self reportSiriServicesAuthorizationStatus:status];
            }];
            
        }
    }
    else if (status == INSiriAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == INSiriAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == INSiriAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.siriStoreResultBlock) {
            self.siriStoreResultBlock(YES);
            self.siriStoreResultBlock = nil;
        }
    }
    else{
        //
    }
}
#pragma mark - 语音识别
-(void)requestSpeechRecognitionAuthorization:(AuthorizationResultBlock)result
{
    if (result) {
        self.speechRecognizerResultBlock = result;
    }
    
    
    //1.检测Key
    [self isHaveUsageDescriptionInPlistByKey:NSSpeechRecognitionUsageDescription];
    //2.获取状态
    SFSpeechRecognizerAuthorizationStatus status = [SFSpeechRecognizer authorizationStatus];
    //3.根据状态进行逻辑选择
    [self reportSpeechRecognitionServicesAuthorizationStatus:status];
    
    
}

- (void)reportSpeechRecognitionServicesAuthorizationStatus:(SFSpeechRecognizerAuthorizationStatus)status{
    if (status == SFSpeechRecognizerAuthorizationStatusNotDetermined) {
        //未作出选择:请求用户授权
        if (self.speechRecognizerResultBlock) {
        
            [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
                [self reportSpeechRecognitionServicesAuthorizationStatus:status];

            }];
        }
    }
    else if (status == SFSpeechRecognizerAuthorizationStatusRestricted){
        //无权使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == SFSpeechRecognizerAuthorizationStatusDenied){
        //拒绝使用:打开设置页面请求用户授权
        [self openSettingApp];
    }
    else if (status == SFSpeechRecognizerAuthorizationStatusAuthorized){
        //授权随时使用:打开设置页面请求用户更改授权
        if (self.speechRecognizerResultBlock) {
            self.speechRecognizerResultBlock(YES);
            self.speechRecognizerResultBlock = nil;
        }
    }
    else{
        //
    }
}

#pragma mark - 公共方法
-(void)openSettingApp
{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:nil completionHandler:^(BOOL success) {
        
    }];
}
-(BOOL)isHaveUsageDescriptionInPlistByKey:(NSString *)key{
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSArray *keys = [infoDictionary allKeys];
    if ([keys containsObject:key]) {
        
        NSString *desc = [infoDictionary objectForKey:key];
        if (desc) {
            return YES;
        }
        else{
            NSLog(@"⚠️⚠️⚠️  Plist文件缺少%@描述内容",key);

            return NO;
        }
        return YES;

    }
    else
    {
        NSLog(@"⚠️⚠️⚠️  Plist文件缺少描述Key:%@",key);

        return NO;
    }
}

#pragma mark - 懒加载方法
-(CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
    }
    return _locationManager;
}
-(AVAudioSession *)audioSession{
    if (!_audioSession) {
        _audioSession = [AVAudioSession sharedInstance];
    }
    return _audioSession;
}


-(CBCentralManager *)centralManager{
    if (!_centralManager) {
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:YES]};
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
    }
    return _centralManager;
}

-(HKHealthStore*)healthStore
{
    if (!_healthStore) {
        _healthStore = [[HKHealthStore alloc] init];
    }
    return _healthStore;
}
-(EKEventStore*)remindersEventStore
{
    if (!_remindersEventStore) {
        _remindersEventStore = [[EKEventStore alloc] init];
    }
    return _remindersEventStore;
}
-(EKEventStore*)calendarsEventStore
{
    if (!_calendarsEventStore) {
        _calendarsEventStore = [[EKEventStore alloc] init];
    }
    return _calendarsEventStore;
}
-(CNContactStore*)contactStore
{
    if (!_contactStore) {
        _contactStore = [[CNContactStore alloc] init];
    }
    return _contactStore;
}

@end
