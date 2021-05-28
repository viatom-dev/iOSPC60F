//
//  ViewController.m
//  PC_60ESDK
//
//  Created by Creative on 2020/11/19.
//

#import "ViewController.h"
#import "CRBlueToothManager.h"
#import "CRAP20SDK.h"
#import "CRHeartLiveView.h"
#import "CRPodDeviceMenuView.h"

@interface ViewController ()<CRBlueToothManagerDelegate, CRAP20SDKDelegate>

/** Bound device  */
@property (nonatomic, strong) CRBleDevice *device;
/** Connected device name Label  */
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
/** Hardware version number Label  */
@property (weak, nonatomic) IBOutlet UILabel *hardWareVersionLabel;
/** Software version number Label  */
@property (weak, nonatomic) IBOutlet UILabel *softWareVersionLabel;
/** Device serial number Label  */
@property (weak, nonatomic) IBOutlet UILabel *serialNumberLabel;
/** Battery Label  */
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
/** SpO2% Label  */
@property (weak, nonatomic) IBOutlet UILabel *spo2Label;
/** Pulse bpm Label  */
@property (weak, nonatomic) IBOutlet UILabel *prLabel;
/** PI Label  */
@property (weak, nonatomic) IBOutlet UILabel *piLabel;
/** Enable/disable uploading of blood oxygen parameters to Switch */
@property (weak, nonatomic) IBOutlet UISwitch *parameterSwitch;
/** Enable/disable uploading of blood oxygen waveform to Switch */
@property (weak, nonatomic) IBOutlet UISwitch *waveformSwitch;
/** Bottom view  */
@property (weak, nonatomic) IBOutlet UIView *bottomContentView;
/** Measurement result Label  */
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
/** Measurement mode Label  */
@property (weak, nonatomic) IBOutlet UILabel *workModeLabel;
/** Latest acquired points array */
@property (nonatomic, strong) NSArray<CRPoint *> *lastPoints;
/** Drawing timer */
@property (nonatomic, weak) NSTimer *timer;
/** Waveform graph  */
@property (nonatomic, weak) CRHeartLiveView *heartLiveView;
/** Number of draws  */
@property (nonatomic, assign) int drawCount;

@property (nonatomic, strong) NSTimer *testTiemr;
@property (nonatomic, assign) NSUInteger testCount;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [CRBlueToothManager shareInstance].delegate = self;
    self.testCount = 0;
    
}

// Click to search for Bluetooth
- (IBAction)searchClieked:(UIBarButtonItem *)sender {
    [[CRBlueToothManager shareInstance] startSearchDevicesForSeconds:1];
}

// Display the searched Bluetooth device list and connect manually
- (void)displayDeviceList:(NSArray *)deviceList {
    if (deviceList.count == 1) {
        // Connect Bluetooth
        [[CRBlueToothManager shareInstance] connectDevice:deviceList[0]];
        return;
    }
    
    NSString *tipStr = @"Select device";
    if (deviceList.count <= 0) {
        tipStr = @"No matching device has been found yet";
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:tipStr message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (int i = 0; i < deviceList.count; i++) {
        NSString *bleName = ((CRBleDevice *)deviceList[i]).bleName;
        UIAlertAction *action = [UIAlertAction actionWithTitle:bleName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // Connect Bluetooth
            [[CRBlueToothManager shareInstance] connectDevice:deviceList[i]];
            [alertVC dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertVC addAction:action];
    }
    // Cancel
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [alertVC addAction:cancelAction];
    // Pop-up selection box
    [self presentViewController:alertVC animated:YES completion:nil];
}
// Click to disconnect Bluetooth
- (IBAction)disconnectClicked:(id)sender {
    [[CRBlueToothManager shareInstance] disconnectDevice:self.device];
}
// Enable/disable upload of blood oxygen parameters
- (IBAction)valueChangedWithParameterSwitch:(UISwitch *)sender {
    [self setSpo2ParamEnable:sender.isOn];
}
// Enable/disable upload of blood oxygen waveform
- (IBAction)valueChangedWithWaveformSwitch:(UISwitch *)sender {
    [self setSpo2WaveEnable:sender.isOn];
}
// Set device menu item
- (IBAction)setupClicked:(UIButton *)sender {
    [self queryMenuOptions];
}
// Measurement view (load UI after successful BLE connection)
- (void)loadMessureUI {
    CGSize size = self.view.bounds.size;
    CRHeartLiveView *heartL = [[CRHeartLiveView alloc] initWithFrame:CGRectMake(size.width * 0.03, 0, size.width * 0.94, size.width * 0.9 / 1.85)];
    [_bottomContentView addSubview:heartL];
    _heartLiveView = heartL;
}
// Initialize the interface
- (void)initUI {
    self.deviceNameLabel.text = @"--";
    self.hardWareVersionLabel.text = @"--";
    self.softWareVersionLabel.text = @"--";
    self.serialNumberLabel.text = @"--";
    self.batteryLabel.text = @"0";
    self.spo2Label.text = @"0";
    self.prLabel.text = @"0";
    self.piLabel.text = @"0";
    self.waveformSwitch.on = YES;
    self.parameterSwitch.on = YES;
    [self.timer invalidate];
    self.timer = nil;
    [self.heartLiveView clearPath];
    [self.heartLiveView removeFromSuperview];
    self.resultLabel.text = @"";
    self.workModeLabel.text = @"";
}

#pragma mark - BLE connection
//BLE status
- (void)bleManager:(CRBlueToothManager *)manager didUpdateState:(CBManagerState)state API_AVAILABLE(ios(10.0)) {
    if (state == CBManagerStatePoweredOn)
        NSLog(@"Bluetooth is on.");
    else
        NSLog(@"Bluetooth is off.");
}
// Filter PC_60E from the list of acquired BLE devices
- (void)bleManager:(CRBlueToothManager *)manager didSearchCompleteWithResult:(NSArray<CRBleDevice *> *)deviceList {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (CRBleDevice *device in deviceList) {
        if ([device.bleName containsString:pc_60e] ||[device.bleName containsString:pc_60f]||[device.bleName containsString:pc_68b]||
            [device.bleName containsString:OxyKnight] ||
            [device.bleName containsString:OxySmart]) {
            NSLog(@"The identifier when connecting =  %@",device.peripheral.identifier);
            [array addObject:device];
        }
    }
    // Display the list of searched devices
    [self displayDeviceList:array];
}
// Connected successfully
- (void)bleManager:(CRBlueToothManager *)manager didConnectDevice:(CRBleDevice *)device {
    NSLog(@"Bluetooth connection is successful");
    self.device = device;
    [[CRAP20SDK shareInstance] didConnectDevice:device];
    // BLE command read/write callback protocol
    [CRAP20SDK shareInstance].delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Query version information, serial number, Mac address
        [self queryDeviceInfo];
        [self querySerialNumber];
        [self queryMacAddress];
        // Default setting: enable blood oxygen data upload
        [self setSpo2EnableAction];
    });
    
    // Update UI
    self.deviceNameLabel.text = device.peripheral.name;
    [self loadMessureUI];
    
    if (!self.testTiemr) {
        self.testTiemr = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(openFire) userInfo:nil repeats:YES];
        
    }
    
}
- (void)openFire{
    self.testCount++;
    NSLog(@"%lu",self.testCount);
    self.timerLabel.text = [NSString stringWithFormat:@"%lu", self.testCount];
}

// Disconnect
- (void)bleManager:(CRBlueToothManager *)manager didDisconnectDevice:(CRBleDevice *)device Error:(NSError *)error{
    [[CRAP20SDK shareInstance] willDisconnectWithDevice:device];
    // Release of BLE command read/write callback protocol
    [CRAP20SDK shareInstance].delegate = nil;
    // Clear the interface
    [self initUI];
    if (error) {
        NSLog(@"Abnormal-->Bluetooth disconnected");
        [manager reconnectDevice:device];
        
    }else{
        NSLog(@"Normal-->Bluetooth disconnected");
    }
    
    if (self.testTiemr) {
        [self.testTiemr invalidate];
        self.testTiemr = nil;
        self.testCount = 0;
    }
   
}
// Connection failed
- (void)bleManager:(CRBlueToothManager *)manager didFailToConnectDevice:(CRBleDevice *)device Error:(NSError *)error {
    NSLog(@"Connection failed error = %@", error.localizedDescription);
}

#pragma mark - CRAP20SDK BLE command reading and writing
#pragma mark - Device information
/** Device information (software version number, hardware version number, product name) */
//【Query device information】
- (void)queryDeviceInfo {
    [[CRAP20SDK shareInstance] queryForDeviceFourBitVersionForDevice:self.device];
}
// Receive callback for 【Query device information】
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetDeviceInfoForSoftWareVersion:(NSString *)softWareV HardWaveVersion:(NSString *)hardWareV ProductName:(NSString *)productName FromDevice:(CRBleDevice *)device {
    self.hardWareVersionLabel.text = hardWareV;
    self.softWareVersionLabel.text = softWareV;
}
#pragma mark - Device Serial Number
//【Query device Serial Number】
- (void)querySerialNumber {
    [[CRAP20SDK shareInstance] queryForSerialNumberForDevice:self.device];
}
// Receive callback for【Query device Serial Number】
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSerialNumber:(NSString *)serialNumber FromDevice:(CRBleDevice *)device {
    self.serialNumberLabel.text = serialNumber;
}

#pragma mark - MAC address
- (void)queryMacAddress {
    [[CRAP20SDK shareInstance] queryForMACAddressForDevice:self.device];
}

- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetMACAddress:(NSString *)macAddress FromDevice:(CRBleDevice *)device {
    NSLog(@"Mac Address:%@", macAddress);
}

#pragma mark - Get battery
/** There are 4 levels of battery power level, the value range is 0-3 */
//【Query battery level】
- (void)queryBatteryLevel {
    //nil
}
// Receive automatic callback for【Query battery level】(After the BLE connection is successful, the device will automatically send the battery value to the iPhone every second)
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetBartteryLevel:(int)batteryLevel FromDevice:(CRBleDevice *)device {
    self.batteryLabel.text = [NSString stringWithFormat:@"%d", batteryLevel];
}
#pragma mark - Device menu item
//【Query device menu item】
- (void)queryMenuOptions {
    [[CRAP20SDK shareInstance] queryForMenuOptionsForDevice:_device];
}
// Receive callback for【Query device menu item】
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK getMenuLowSpO2:(int)lowSpO2 highPR:(int)highPr lowPR:(int)lowPr spot:(int)spot beepOn:(int)beepOn rotateOn:(int)rotateOn FromDevice:(CRBleDevice *)device {
    __block CRPodDeviceMenuView *deviceMenuView = [[CRPodDeviceMenuView alloc] initWithDeviceName:device.peripheral.name Update:^(int lowSpO2, int highPr, int lowPr, int spot, int beepOn, int rotateOn) {
        [deviceMenuView removeFromSuperview];
        //【Set Device Menu Item】（update）
        [[CRAP20SDK shareInstance] setMenuOptions:lowSpO2 highPR:highPr lowPR:lowPr spot:spot beepOn:beepOn rotateOn:rotateOn forDevice:device];
    } Cancel:^{
        [deviceMenuView removeFromSuperview];
    }];
    deviceMenuView.lowSpO2 = lowSpO2;
    deviceMenuView.highPr = highPr;
    deviceMenuView.lowPr = lowPr;
    deviceMenuView.spot = spot;
    deviceMenuView.beepOn = beepOn;
    deviceMenuView.rotateOn = rotateOn;
    [self.view addSubview:deviceMenuView];
}
//【Set device menu item】Success or failure callback
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK setMenuSuccess:(BOOL)failOrSuccess FromDevice:(CRBleDevice *)device {
    NSLog(@"Device menu item set successfully");
}

#pragma mark - Blood oxygen waveform, parameter enable
/** Enable/disable upload of blood oxygen parameters to APP, 0x00 disable, 0x01 enable (default) */
//【Set the upload switch of blood oxygen parameters】
- (void)setSpo2ParamEnable:(BOOL)beEnable {
    [[CRAP20SDK shareInstance] sendCommandForSpo2ParamEnable:beEnable ForDevice:self.device];
}
// Success 【Set the upload switch of blood oxygen parameters】Callback
- (void)successdToSetSpo2ParamEnableFromDevice:(CRBleDevice *)device {
    NSLog(@"Successfully set blood oxygen parameters: %d", self.parameterSwitch.isOn);
}

/** Enable/disable upload of blood oxygen waveform to APP, 0x00 disable, 0x01 enable (default) */
//【Set the blood oxygen waveform upload switch】
- (void)setSpo2WaveEnable:(BOOL)beEnable {
    [[CRAP20SDK shareInstance] sendCommandForSpo2WaveEnable:beEnable ForDevice:self.device];
}
// Success 【Set the blood oxygen waveform upload switch】Callback
- (void)successdToSetSpo2WaveEnableFromDevice:(CRBleDevice *)device {
    NSLog(@"Successfully set blood oxygen waveform: %d", self.waveformSwitch.isOn);
    //[[CRAP20SDK shareInstance] setMenuOptions:90 highPR:120 lowPR:60 spot:2 beepOn:1 forDevice:self.device];
}

/** Settings after successful BLE connection: Enable blood oxygen waveform and parameter upload to APP */
- (void)setSpo2EnableAction {
    // Allow the device to automatically send blood oxygen waveform data to the APP
    [self setSpo2WaveEnable:YES];
    // Allow the device to automatically send blood oxygen parameters to the APP
    [self setSpo2ParamEnable:YES];
}
#pragma mark - Blood oxygen waveform
/** 【Spo2 Waveform Data】Automatic callback */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Wave:(struct waveData*)wave FromDevice:(CRBleDevice *)device {
    // Draw waveform
    [self handleSpo2WaveData:wave];
}
#pragma mark - Blood oxygen parameters
/** 【Blood oxygen parameters】Automatic callback */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Value:(int)spo2 PulseRate:(int)pr PI:(int)pi State:(CRAP_20Spo2State)state Mode:(CRAP_20Spo2Mode)mode BattaryLevel:(int)battaryLevel FromDevice:(CRBleDevice *)device {
    self.spo2Label.text = [NSString stringWithFormat:@"%d", spo2];
    self.prLabel.text = [NSString stringWithFormat:@"%d", pr];
    self.piLabel.text = [NSString stringWithFormat:@"%.1f", pi * 0.1];//PI*0.1
}
#pragma mark - Blood oxygen measurement status
/** 【Working status】Automatic callback */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetWorkStatusDataWithMode:(CRPC_60FWorkStatusMode)mode Stage:(CRPC_60FCommanMessureStage)stage Parameter:(int)para OtherParameter:(int)otherPara FromDevice:(CRBleDevice *)device {
    //NSLog(@"working status-%d，stage-%d, parameter-%d-%d", mode, stage, para, otherPara);
    NSMutableString *str = [NSMutableString string];
    // Measurement mode
    [str appendFormat:@"%@", mode == 1 ? @"Spot check" : @"Continuous"];
    // Measurement status
    [str appendFormat:@"\t\t%@", [self getMessureStage:stage]];
    if (stage == 2 && mode == 1)
        // It is measuring. If the mode is Spot check, add the countdown to para
        [str appendFormat:@" %d seconds", para];
    self.workModeLabel.text = str;
    // Measurement result
    if (stage == 3)
        self.resultLabel.text = [NSString stringWithFormat:@"Blood oxygen measurement result：SpO2：%d，PR：%d", para, otherPara];
    if (stage == 4) {
        NSString *string = [NSString stringWithFormat:@"%@", self.resultLabel.text];
        self.resultLabel.text = [string stringByAppendingFormat:@"\nPulse rate analysis result：%@", [self getMessureResult:para]];
    }
}

// Current measurement stage
- (NSString *)getMessureStage:(int)stage {
    if (stage < 0 || stage > 5) {
        return @"";
    }
    NSArray *array = @[@"", @"Preparation stage", @"Is measuring", @"Broadcast results", @"Pulse rate analysis result", @"Pulse rate analysis result"];
    NSString *str = array[stage];
    return str;
}
// Get the measured pulse rate analysis result
- (NSString *)getMessureResult:(int)para {
    NSString *str = @"";
    switch (para) {
        case 0:
            str = @"No irregularity found";
            break;
        case 1:
            str = @"Suspected a little fast pulse";
            break;
        case 2:
            str = @"Suspected fast pulse";
            break;
        case 3:
            str = @"Suspected short run of fast pulse";
            break;
        case 4:
            str = @"Suspected a little slow pulse";
            break;
        case 5:
            str = @"Suspected slow pulse";
            break;
        case 6:
            str = @"Suspected occasional short pulse interval";
            break;
        case 7:
            str = @"Suspected irregular pulse interval";
            break;
        case 8:
            str = @"Suspected fast pulse with short pulse interval";
            break;
        case 9:
            str = @"Suspected slow pulse with short pulse interval";
            break;
        case 10:
            str = @"Suspected slow pulse with irregular pulse interval";
            break;
        default:
            str = @"Poor signal. Measure again";
            break;
    }
    return str;
}

#pragma mark - Drawing
// Process waveform data, and generate the number of waveform points to be drawn (5)
- (void)handleSpo2WaveData:(struct waveData*)wave {
    NSMutableArray *points = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        CRPoint *point = [[CRPoint alloc] init];
        point.y = 128 - wave[i].waveValue;
        [points addObject:point];
        // Heart rate（1- point.y/ 128.0）
        // Pulse pulsation flag（wave[i].pulse=YES, display; otherwise hide）
    }
    // Divide the received waveform data into 5 draws, that is, redraw each point once
    _lastPoints = points;
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 *1.0 / 52 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
    }
    _drawCount = 0;
    [_timer setFireDate:[NSDate distantPast]];
}
// draw
- (void)fireTimer:(NSTimer *)timer {
    if (_drawCount == 5) {
        _drawCount = 0;
        [timer setFireDate:[NSDate distantFuture]];
        return;
    }
    [_heartLiveView addPoints:[_lastPoints subarrayWithRange:NSMakeRange(_drawCount , 1)]];
    _drawCount++;
}

@end
