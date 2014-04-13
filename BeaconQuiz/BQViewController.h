//
//  BQViewController.h
//  BeaconQuiz
//
//  Created by Ken Tominaga on 2014/04/12.
//  Copyright (c) 2014年 Tommy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SRWebSocket.h"
@import CoreLocation;
@import AudioToolbox;

@interface BQViewController : UIViewController <CLLocationManagerDelegate, SRWebSocketDelegate, UITextFieldDelegate>
{
        //---ソケット通信関連---
        SRWebSocket *socket;
        BOOL isConnect;
        int rec_data;
        BOOL isReceived;
        BOOL isName_Idented;
    
    BOOL isATouched;
        //-------------
        __weak IBOutlet UILabel *receive_message;   //一番上の受信用ラベル
        int isType; //1: beacon, 2:string
    
        //
        __weak IBOutlet UITextField *input_outlet;  //str問題用の入力フォーム
        int Q_num;  //問題の番号はいくつなのか。ビーコンから受け取る。
        __weak IBOutlet UIImageView *Q_img; //問題が画像だった場合はこれを表示する。
    
    IBOutlet UILabel *timeLabel;
    
    IBOutlet UIImageView *hintView;
}

@property (strong, nonatomic) NSUUID *proximityUUID;
@property (strong, nonatomic) CLLocationManager *manager;
@property (strong, nonatomic) CLBeaconRegion *region;

@property (nonatomic) NSNumber *currentMinor;

@property (weak, nonatomic) IBOutlet UILabel *beaconLabel;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityLabel;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;

#pragma mark - Network

- (IBAction)socket_open:(id)sender;
- (IBAction)socket_close:(id)sender;
- (IBAction)send_token:(UIButton *)sender;
//
- (IBAction)send_string:(id)sender; //string送信ボタン
- (IBAction)ss_tap:(id)sender;  //キーボード閉じる用
- (IBAction)set_num:(UIButton *)sender;

@end
