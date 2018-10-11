//
//  ViewController.m
//  HFAuthorizationToolDemo
//
//  Created by 张文旗 on 2018/10/10.
//  Copyright © 2018 张文旗. All rights reserved.
//

#import "ViewController.h"
#import "HFAuthorizationTool.h"

@interface ViewController ()
@property HFAuthorizationTool *tool;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 200, 200)];
    [btn setBackgroundColor:[UIColor yellowColor]];
    [btn addTarget:self action:@selector(action) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

-(void)action{
    if (!self.tool) {
        self.tool = [[HFAuthorizationTool alloc] init];
    }
//    [self.tool requestWhenInUseAuthorization:^(BOOL result) {
//        NSLog(@"requestWhenInUseAuthorization授权成功");
//
//    }];
//    [self.tool requestAlwaysAuthorization:^(BOOL result) {
//        NSLog(@"requestAlwaysAuthorization授权成功");
//    }];
    
    [self.tool requestPhotoLibraryAuthorization:^(BOOL result) {
        NSLog(@"requestPhotoLibraryAuthorization授权成功");

    }];
    
//    [self.tool requestCameraAuthorization:^(BOOL result) {
//        NSLog(@"requestCameraAuthorization授权成功");
//
//    }];
    
//    [self.tool requestMicrophoneAuthorization:^(BOOL result) {
//        NSLog(@"requestMicrophoneAuthorization授权成功");
//
//    }];
    
//    [self.tool requestBluetoothAuthorization:^(BOOL result) {
//        NSLog(@"requestBluetoothAuthorization授权成功");
//
//    }];
    
//        [self.tool requestRemindersAuthorization:^(BOOL result) {
//            NSLog(@"requestRemindersAuthorization授权成功");
//
//        }];
//    [self.tool requestCalendarsAuthorization:^(BOOL result) {
//        NSLog(@"requestCalendarsAuthorization授权成功");
//
//    }];
    
//    [self.tool requestContactsAuthorization:^(BOOL result) {
//        NSLog(@"requestContactsAuthorization授权成功");
//
//    }];
//    [self.tool requestSiriAuthorization:^(BOOL result) {
//        NSLog(@"requestSiriAuthorization授权成功");
//
//    }];
    
//    [self.tool requestSpeechRecognitionAuthorization:^(BOOL result) {
//        NSLog(@"requestSpeechRecognitionAuthorization授权成功");
//
//    }];
    
}
@end
