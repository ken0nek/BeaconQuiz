//
//  BQAppDelegate.h
//  BeaconQuiz
//
//  Created by Ken Tominaga on 2014/04/12.
//  Copyright (c) 2014年 Tommy. All rights reserved.
//

#import <UIKit/UIKit.h>

@import CoreLocation;
@import AVFoundation;

@interface BQAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) CLBeaconRegion *region;

@property (strong, nonatomic) AVAudioPlayer *enter;
@property (strong, nonatomic) AVAudioPlayer *exit;

@end
