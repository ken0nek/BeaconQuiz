//
//  BQViewController.m
//  BeaconQuiz
//
//  Created by Ken Tominaga on 2014/04/12.
//  Copyright (c) 2014年 Tommy. All rights reserved.
//

#import "BQViewController.h"

@interface BQViewController ()
{
    int currentQuestion;
    BOOL isStarted;
    
    BOOL isVideoLoaded;
    
    NSTimer *timer; //クイズ中の経過時間を生成する
    int countTime;  //設定時間
    int ms;
    
    NSTimeInterval startTime;
    
    IBOutlet UITextField *answerField;
    IBOutlet UIButton *answerButton;
    IBOutlet UIWebView *player;
    IBOutlet UILabel *seikaiLabel;
}

@end

@implementation BQViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)showPlayer
{
    
    // スクロールを無効にする
    player.scrollView.scrollEnabled = NO;
    // スクロール時の跳ね返りを抑制する
    player.scrollView.bounces = NO;
    
    // YouTubeのVideo ID
    NSString *videoID = @"21Lef-g0BYY";
    
    // UIWebViewにセットするHTMLのテンプレート
    NSString *htmlString = @" \
    <!DOCTYPE html> \
    <html> \
    <head> \
    <meta name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no, width=%f\"> \
    </head> \
    <body style=\"background:#000000; margin-top:0px; margin-left:0px\"> \
    <iframe width=\"%f\" \
    height=\"%f\" \
    src=\"http://www.youtube.com/embed/%@?showinfo=0\" \
    frameborder=\"0\" \
    allowfullscreen> \
    </iframe> \
    </body> \
    </html> \
    ";
    
    NSString *html = [NSString stringWithFormat:
                      htmlString,
                      player.frame.size.width,
                      player.frame.size.width,
                      player.frame.size.height,
                      videoID];
    
    [player loadHTMLString:html baseURL:nil];
    [self.view addSubview:player];
    [self.view bringSubviewToFront:player];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    timeLabel.hidden = NO;
    
    isVideoLoaded = NO;
    
    isStarted = NO;
    
    seikaiLabel.hidden = YES;
    
    answerField.hidden = YES;
    answerButton.hidden = YES;
    
    answerField.delegate = self;
    
    hintView.hidden = YES;
    
    [self connect];
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        // CLLocationManagerの生成とデリゲートの設定
        self.manager = [CLLocationManager new];
        self.manager.delegate = self;
        
        // 生成したUUIDからNSUUIDを作成
        NSString *uuid = @"1E21BCE0-7655-4647-B492-A3F8DE2F9A02";
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
        
        // CLBeaconRegionを作成
        self.region = [[CLBeaconRegion alloc]
                       initWithProximityUUID:self.proximityUUID
                       identifier:@"jp.classmethod.testregion"];
        self.region.notifyOnEntry = YES;
        self.region.notifyOnExit = YES;
        self.region.notifyEntryStateOnDisplay = NO;
        
        // 領域監視を開始
        [self.manager startMonitoringForRegion:self.region];
        // 距離測定を開始
        [self.manager startRangingBeaconsInRegion:self.region];
    }
}

#pragma mark - locationManager

// Beaconに入ったときに呼ばれる
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self sendNotification:@"didEnterRegion"];
}

// Beaconから出たときに呼ばれる
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self sendNotification:@"didExitRegion"];
}

// Beaconとの状態が確定したときに呼ばれる
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    switch (state) {
        case CLRegionStateInside:
            NSLog(@"CLRegionStateInside");
            [self playSound:@"enter"];
            break;
        case CLRegionStateOutside:
            NSLog(@"CLRegionStateOutside");
            [self playSound:@"exit"];
            break;
        case CLRegionStateUnknown:
            NSLog(@"CLRegionStateUnknown");
            break;
        default:
            break;
    }
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    CLProximity proximity = CLProximityUnknown;
    NSString *proximityString = @"CLProximityUnknown";
    CLLocationAccuracy locationAccuracy = 0.0;
    NSInteger rssi = 0;
    NSNumber* major = @0;
    NSNumber* minor = @0;
    
    // 最初のオブジェクト = 最も近いBeacon
    CLBeacon *beacon = beacons.firstObject;
    
    proximity = beacon.proximity;
    locationAccuracy = beacon.accuracy;
    rssi = beacon.rssi;
    major = beacon.major;
    minor = beacon.minor;
    
    CGFloat alpha = 1.0;
    switch (proximity) {
        case CLProximityUnknown:
            proximityString = @"CLProximityUnknown";
            alpha = 0.3;
            break;
        case CLProximityImmediate:
            proximityString = @"CLProximityImmediate";
            alpha = 1.0;
            [self quizManagerGetQuestion:minor];
            break;
        case CLProximityNear:
            proximityString = @"CLProximityNear";
            alpha = 0.8;
            break;
        case CLProximityFar:
            proximityString = @"CLProximityFar";
            alpha = 0.5;
            break;
        default:
            break;
    }
    
    self.uuidLabel.text = beacon.proximityUUID.UUIDString;
    self.majorLabel.text = [NSString stringWithFormat:@"%@", major];
    self.minorLabel.text = [NSString stringWithFormat:@"%@", minor];
    self.proximityLabel.text = proximityString;
    self.accuracyLabel.text = [NSString stringWithFormat:@"%f", locationAccuracy];
    self.rssiLabel.text = [NSString stringWithFormat:@"%d", (int)rssi];
    
    if ([minor isEqualToNumber:@1]) {
        // Beacon A
        self.beaconLabel.text = @"A";
        self.view.backgroundColor = [UIColor colorWithRed:0 green:0.749 blue:1.0 alpha:alpha];
        [player removeFromSuperview];
    } else if ([minor isEqualToNumber:@2]) {
        // Beacon B
        self.beaconLabel.text = @"B";
        self.view.backgroundColor = [UIColor colorWithRed:0.604 green:0.804 blue:0.196 alpha:alpha];
    } else if ([minor isEqualToNumber:@3]) {
        // Beacon C
        self.beaconLabel.text = @"C";
        self.view.backgroundColor = [UIColor colorWithRed:1.0 green:0.412 blue:0.706 alpha:alpha];
    } else if ([minor isEqualToNumber:@4]) {
        // Beacon D
        self.beaconLabel.text = @"D";
        self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.984 blue:0.936 alpha:alpha];
    } else if ([minor isEqualToNumber:@5]) {
        // Beacon E
        self.beaconLabel.text = @"E";
        self.view.backgroundColor = [UIColor colorWithRed:0.40 green:0.82 blue:0.706 alpha:alpha];
    } else if ([minor isEqualToNumber:@6]) {
        // Beacon F
        self.beaconLabel.text = @"F";
        self.view.backgroundColor = [UIColor colorWithRed:0.604 green:1.0 blue:0.56 alpha:alpha];
    } else {
        self.beaconLabel.text = @"-";
        self.view.backgroundColor = [UIColor colorWithRed:0.3 green:0.13 blue:0.53 alpha:1.0];
    }
    
    if (minor != nil && self.currentMinor != nil && ![minor isEqualToNumber:self.currentMinor]) {
        [self playSound:@"change"];
    }
    self.currentMinor = minor;
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"kCLAuthorizationStatusNotDetermined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"kCLAuthorizationStatusRestricted");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");
            break;
        case kCLAuthorizationStatusAuthorized:
            NSLog(@"kCLAuthorizationStatusAuthorized");
            break;
        default:
            break;
    }
}

- (void)sendNotification:(NSString*)message
{
    // 通知を作成する
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [[NSDate date] init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = message;
    notification.alertAction = @"Open";
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    // 通知を登録する
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

#pragma mark - Sound

- (void)playSound:(NSString*)name
{
    //////////////////////////////////////////////////
    //
    // 音声ファイルは以下のサイトからお借りしています。
    // http://www.skipmore.com/sound/
    //
    //////////////////////////////////////////////////
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:name ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    SystemSoundID sndId;
    OSStatus err = AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(url), &sndId);
    if (!err) {
        AudioServicesPlaySystemSound(sndId);
    }
}


#pragma mark - Quiz

- (void)quizManagerGetQuestion:(NSNumber *)minor
{
    int minorInt = [minor intValue];
    switch (minorInt) {
        case 1:
            NSLog(@"Question%d", minorInt);
            if (isStarted) {
                [self sending_data:@"beacon":@"A"];
            } else {
                [self sending_data:@"Q_num":[NSString stringWithFormat:@"%d", minorInt]];
                NSLog(@"---------START---------");
                
                startTime = [NSDate timeIntervalSinceReferenceDate];
                
                timer = [NSTimer
                         scheduledTimerWithTimeInterval:0.01
                         target: self
                         selector:@selector(TimerAction)
                         userInfo:nil
                         repeats:YES];
                countTime = 3600; //設定時間「60プン」
                
                isStarted = YES;
            }
            break;
        case 2:
            NSLog(@"Question%d", minorInt);
            if (isStarted) {
                if (isType == 1) {
                    [self sending_data:@"beacon":@"B"];
                    answerField.hidden = YES;
                    answerButton.hidden = YES;
                } else {
                    NSLog(@"送信ボタンパターン");
                    answerField.hidden = NO;
                    answerButton.hidden = NO;
                }
                
            }  else {
                [self sending_data:@"Q_num":[NSString stringWithFormat:@"%d", minorInt]];
                isStarted = YES;
            }
            break;
        case 3:
            NSLog(@"Question%d", minorInt);
            if (isStarted) {
                
                if (isType == 1) {
                    [self sending_data:@"beacon":@"C"];
                    answerField.hidden = YES;
                    answerButton.hidden = YES;
                    
                } else {
                    NSLog(@"送信ボタンパターン");
                    answerField.hidden = NO;
                    answerButton.hidden = NO;
                }
            } else {
                [self sending_data:@"Q_num":[NSString stringWithFormat:@"%d", minorInt]];
                isStarted = YES;
            }
            
            break;
        case 4:
            NSLog(@"Question%d", minorInt);
            [self sending_data:@"beacon":@"D"];
            break;
        case 5:
            NSLog(@"Question%d", minorInt);
            [self sending_data:@"beacon":@"E"];
            break;
        case 6:
            NSLog(@"Question%d", minorInt);
            //[self sending_data:@"beacon":@"F"];
            if (!isVideoLoaded) {
                [self showPlayer];
                isVideoLoaded = YES;
            }
            break;
        default:
            NSLog(@"Other");
            break;
    }
}

#pragma mark - Network

//--------------------------------------------------------------
//ソケット通信をセットアップする。
//--------------------------------------------------------------
- (void)connect {
    NSURL *url = [NSURL URLWithString:@"ws://172.20.10.3:5555"];
    socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
    socket.delegate = self;
    [socket open];
}

//---ソケット開いたら行う動作---
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"コネクションが開きました.");
    receive_message.text = @"コネクションが開きました.";
}

//---ソケット開かなかったら行う動作---
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"コネクションが開きませんでした");
    receive_message.text = @"コネクションが開きませんでした";
}

//------------------------
// ソケット通信の送受信関連
//------------------------

//---送信---
- (void)sending_data:(NSString*)str1 :(NSString*)str2 {
    NSString *requestBody = [NSString stringWithFormat:@"{\"request\":\"%@\", \"data_key\":\"%@\"}", str1, str2];
    NSLog(@"str1: %@, str2 %@", str1, str2);
    [socket send:requestBody];
}
//---受信---
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    NSLog(@"もらったデータ:: 「%@」", message);
    NSString* check_str = [message substringWithRange:NSMakeRange(0,4)];
    NSLog(@"check_str:: %@", check_str);
    if ([message isEqualToString:@"wrong"]) {
        isStarted = NO;
        seikaiLabel.hidden = YES;
    } else if ([message isEqualToString:@"true"]){
        isStarted = NO;
        seikaiLabel.hidden = NO;
    }
    if ([message isEqualToString:@"correct"]) {
        seikaiLabel.hidden = NO;
    } else if ([message isEqualToString:@"false"]){
        seikaiLabel.hidden = YES;
    }
    if([check_str isEqualToString:@"http"]){
        Q_img.hidden = NO;
        receive_message.hidden = YES;
        [self open_url_img:message];
    } else {
        if([message isEqualToString:@"beacon"]){
            isType = 1;
            NSLog(@"次の問題はbeacon型です。");
        } else if ([message isEqualToString:@"string"]) {
            isType = 2;
            NSLog(@"次の問題はstring型です。");
        } else {
            Q_img.hidden = YES;
            receive_message.hidden = NO;
            receive_message.text = [NSString stringWithFormat:@"%@", message];
            seikaiLabel.hidden = YES;
        }
    }
}

- (IBAction)socket_open:(id)sender {
    [self connect];
}

- (IBAction)socket_close:(id)sender {
    [socket close];
    receive_message.text = @"コネクションを閉じました";
}

//- (IBAction)send_token:(UIButton *)sender {
//    switch(sender.tag){
//        case 1:
//            //[self sending_data:@"beacon":@"A"];
//            [self sending_data:@"Q_num":[NSString stringWithFormat:@"%d", Q_num]];
//            break;
//        case 2:
//            [self sending_data:@"beacon":@"B"];
//            break;
//        case 3:
//            [self sending_data:@"beacon":@"C"];
//            break;
//        case 4:
//            [self sending_data:@"beacon":@"D"];
//            break;
//        case 5:
//            [self sending_data:@"beacon":@"E"];
//            break;
//        case 6:
//            [self sending_data:@"beacon":@"F"];
//            break;
//    }
//}
- (void)send_string{
    [self sending_data:@"string" :answerField.text];
    NSLog(@"送信データ %@", answerField.text);
}

- (IBAction)ss_tap:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)set_num:(UIButton *)sender {
    Q_num = (int) sender.tag;
}
- (void) open_url_img:(NSString*)img_url {
    NSString* path = img_url;
    NSURL* url = [NSURL URLWithString:path];
    NSData* data = [NSData dataWithContentsOfURL:url];
    UIImage* img = [[UIImage alloc] initWithData:data];
    Q_img.image = img;
}

- (IBAction)sendAnswer
{
    [self send_string];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [socket close];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - timer

-(void)timerUpdate{
    NSTimeInterval time= [NSDate timeIntervalSinceReferenceDate] - startTime; // 基準の時間からの「時間差」を取る。
    // 以下、①と同じ方法で"00:00:00"表示にする。
    int restTime = ceil (countTime - time); // ceil は切り捨て関数。「残り時間」restTime（秒）を算出。
    int restTimeH = restTime/3600; //「時」。
    int restTimeM = (restTime - restTimeH*3600) / 60;// 「分」。
    if (ms < 0) {
        ms = 99;
    } else {
        ms--;
    }
    timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", //それぞれ、整数二桁。
                            restTimeM,  restTime%60, ms]; //　代入。
    
    if (restTime <= 0 ) {  // 「残り時間」が０(秒)を切ると、タイマーを停止する。
        [timer invalidate];
        timer = nil;
    }
}

-(void)TimerAction{
//    if(countTime>0){
//        countTime--;
//        [timeLabel setText:[NSString stringWithFormat:@"%d",countTime]]; // ラベルに時間を表示
//    }else{
//        [timer invalidate]; // タイマーを停止する
//        NSLog(@"---------タイムオーバ-----------");
//    }
    NSTimeInterval time= [NSDate timeIntervalSinceReferenceDate] - startTime; // 基準の時間からの「時間差」を取る。
    // 以下、①と同じ方法で"00:00:00"表示にする。
    int restTime = ceil (countTime - time); // ceil は切り捨て関数。「残り時間」restTime（秒）を算出。
    int restTimeH = restTime/3600; //「時」。
    int restTimeM = (restTime - restTimeH*3600) / 60;// 「分」。
    if (ms < 0) {
        ms = 99;
    } else {
        ms--;
    }
    timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", //それぞれ、整数二桁。
                      restTimeM,  restTime%60, ms]; //　代入。
    
    if (restTime <= 0 ) {  // 「残り時間」が０(秒)を切ると、タイマーを停止する。
        [timer invalidate];
        timer = nil;
    }

}

@end
