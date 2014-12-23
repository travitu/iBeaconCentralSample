//
//  ViewController.m
//  iBeaconCentralSample
//
//  Created by Toshikazu Fukuoka on 2014/12/23.
//  Copyright (c) 2014年 Toshikazu Fukuoka. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

// proximityUUIDとして利用するUUID（Macターミナル：$ uuidgen）
#define UUID_FOR_PROXIMITY @"23959981-C41C-4D6F-BC40-3656D56A4D6B"

// アプリ内でRegionを特定するために利用するID
#define REGION_ID @"com.travitu.ibeacontest"

@interface ViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUUID            *proximityUUID;
@property (nonatomic, strong) CLBeaconRegion    *beaconRegion;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // iBeaconによる領域観測が可能かどうかをチェック
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        NSLog(@"isMonitoringAvailableForClass");
        
        // CLLocationManagerの生成とデリゲート設定
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        
        // 生成したUUIDからNSUUIDを生成する
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:UUID_FOR_PROXIMITY];
        // CLBeaconRegionを生成する
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID identifier:REGION_ID];
        self.beaconRegion.notifyEntryStateOnDisplay = YES;
        self.beaconRegion.notifyOnEntry = YES;
        self.beaconRegion.notifyOnExit = YES;
        
        // Beaconによる領域観測を開始する
//        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            
            // iOS バージョンが 8 以上で、requestAlwaysAuthorization メソッドが利用できる場合
            
            // 位置情報測位の許可を求めるメッセージを表示する
//            [self.locationManager requestWhenInUseAuthorization]; // アプリ使用中のみ許可
            [self.locationManager requestAlwaysAuthorization]; // 常に許可
        } else {
            // iOS バージョンが 8 未満で、requestAlwaysAuthorization メソッドが利用できない場合

            // 測位を開始する
            [self.locationManager startUpdatingLocation];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UILocalNotification Method
- (void)sendLocalNotificationForMessage:(NSString *)message
{
    NSLog(@"sendLocalNotificationForMessage");
    
    // 通知時間 < 現在時 なら設定しない
//    if ([[NSDate date] timeIntervalSinceNow] <= 0) {
//        return;
//    }
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // インスタンス生成
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    // 即通知する場合
//    notification.fireDate = [NSDate date];
    // 時間指定する場合（設定は秒単位）
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(1 * 1)];
    
    // タイムゾーンの設定
    notification.timeZone = [NSTimeZone defaultTimeZone];
    // 通知時に表示させるメッセージ内容
    notification.alertBody = message;
    
    // アプリ起動中に通知するときに渡す情報
    notification.userInfo = @{@"message":message};
    
    // 通知の登録
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}


#pragma mark - CLLocationManagerDelegate

// ユーザの位置情報の許可状態を確認するメソッド
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
}

// モニタリング開始が正常に始まったときに呼ばれる
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"didStartMonitoringForRegion");
    [self.locationManager requestStateForRegion:self.beaconRegion];
}

/**
 アプリ起動時に既にリージョン内にいる場合は、locationManager:didEnterRegion:が呼ばれないため、
 このメソッドで現在リージョン内にいるかどうかを確認する必要がある。
 */
// モニタリング監視の状態を確認する
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    
    switch (state) {
        case CLRegionStateInside: // 既にリージョン内にいる
            NSLog(@"CLRegionStateInside");
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
            }
            break;
        case CLRegionStateOutside:
            NSLog(@"CLRegionStateOutside");
        case CLRegionStateUnknown:
            NSLog(@"CLRegionStateUnknown");
        default:
            break;
    }
}

/**
 領域観測のイベントの処理
 */
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    
    // ローカル通知
    [self sendLocalNotificationForMessage:NSLocalizedString(@"Enter Region", @"")];
    
    // Beaconの距離計測を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        NSLog(@"startRangingBeaconsInRegion");
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion");
    // ローカル通知
    [self sendLocalNotificationForMessage:NSLocalizedString(@"Exit Region", @"")];
    
    // Beaconの距離計測を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        NSLog(@"stopRangingBeaconsInRegion");
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

/**
 距離観測のイベントの処理
 */
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"beacons.count=%lu",(unsigned long)beacons.count);
    if (beacons.count > 0) {
        
        /*
         引数beaconsには距離測定中のBeaconの配列が渡される。
         この配列はBeaconまでの距離が近い順にソートされているので、
         最も距離の近いBeaconについて処理するためには配列の先頭を取得する
         */
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        
        // Beaconの距離でメッセージを変える
        NSString *rangeMessage = @"";
        
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = NSLocalizedString(@"Range Immediate", @"");
                break;
            case CLProximityNear:
                rangeMessage = NSLocalizedString(@"Range Near", @"");
                break;
            case CLProximityFar:
                rangeMessage = NSLocalizedString(@"Range Far", @"");
                break;
            default:
                rangeMessage = NSLocalizedString(@"Range UnKnown", @"");
                break;
        }
        
        // ローカル通知
        NSString *message = [NSString stringWithFormat:@"%@/major:%@, minor:%@, accuracy:%f, rssi:%ld",rangeMessage, nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
        [self sendLocalNotificationForMessage:message];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Ranging error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Monitoring error: %@", error);
}

@end
