//
//  CRBlueToothManager.m
//  PC300SDKDemo
//
//  Created by Creative on 2018/2/1.
//  Copyright © 2018年 creative. All rights reserved.
//

#import "CRBlueToothManager.h"
#import "CRAP20SDK.h"
@interface CRBlueToothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>
/** 中心管理者 */
@property (nonatomic, strong) CBCentralManager *centralManager;
/** 扫描时长定时器 */
@property (nonatomic, weak) NSTimer *searchTimer;
/** 搜索到符合的,待连接的设备集合 */
@property (nonatomic, strong) NSMutableArray <CRBleDevice *> *fitDevices;
/** 连接设备的超时定时器 */
@property (nonatomic, strong) NSMutableDictionary <NSString *,NSTimer *> *outTimers;

@end

@implementation CRBlueToothManager

-(NSMutableArray *)fitDevices
{
    if (!_fitDevices)
        _fitDevices = [NSMutableArray array];
    return _fitDevices;
}

- (NSMutableDictionary<NSString *,NSTimer *> *)outTimers
{
    if (!_outTimers)
        _outTimers = [NSMutableDictionary dictionary];
    return _outTimers;
}

- (NSMutableDictionary *)connectedDevices
{
    if (!_connectedDevices)
        _connectedDevices = [NSMutableDictionary dictionary];
    return _connectedDevices;
}

- (CBManagerState)state
{
    return self.centralManager.state;
}
//
+(instancetype)shareInstance
{
    static CRBlueToothManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [[CRBlueToothManager alloc] init];
        [manager initManager];
    });
    return manager;
}

- (void)initManager
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
#pragma mark 设置工作模式
- (void)setWorkMode:(CRBLESDKWorkMode)mode
{
    if ((mode == CRBLESDKWorkModeForeground) && (_modeState == CRBLESDKWorkModeBackground))
    {
        if (self.centralManager.isScanning)
        {
            [self stopSearch];
            _modeState = mode;
            [self startSearchDevicesForSeconds:5];
        }
    }
    _modeState = mode;
}

#pragma mark - --------------------------- 业务逻辑
#pragma mark -
#pragma mark  开始搜索
- (void)startSearchDevice
{
    if (self.centralManager.isScanning)
    {
        return;
    }
    int waitTime = 0;
    if (self.centralManager.state != CBManagerStatePoweredOn)
        waitTime = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.centralManager scanForPeripheralsWithServices:@[] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        //    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    });
    
}
#pragma mark 扫描设备
- (void)startSearchDevicesForSeconds:(NSUInteger)seconds
{
    if ([self.centralManager isScanning])
    {
        [self stopSearch];
    }
    [self.fitDevices removeAllObjects];
    NSUInteger realSeconds = seconds;
    //判断一些奇怪的参数
    if (seconds <= 0)
        realSeconds = 5;
    //开始扫描
    [self startSearchDevice];
    //定时
    if (_modeState == CRBLESDKWorkModeForeground)
    {
        _searchTimer = [NSTimer scheduledTimerWithTimeInterval:realSeconds target:self selector:@selector(finishSearch) userInfo:nil repeats:NO];
    }
}
#pragma mark 停止搜索
- (void)stopSearch
{
    [_searchTimer invalidate];
    [self.centralManager stopScan];
}
#pragma mark 搜索完毕
- (void)finishSearch
{
    [_searchTimer invalidate];
    [self.centralManager stopScan];
    //2.告诉代理，搜索完成
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didSearchCompleteWithResult:)])
        [self.delegate bleManager:self didSearchCompleteWithResult:self.fitDevices];
}
#pragma mark 连接设备
- (void)connectDevice:(CRBleDevice *)device
{
    //停止扫描
    [self  stopSearch];
    if (!device)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
        {
            [_delegate bleManager:self didFailToConnectDevice:device Error:[NSError errorWithDomain:NSCocoaErrorDomain code:CRBLESDKConnectErrorDeviceIsNil userInfo:@{NSLocalizedDescriptionKey:@"Device cannot be nil"}]];
        }
        return;
    }
    device.connectionState = CRBLESDKConnectionStateConnecting;
    [self.centralManager connectPeripheral:device.peripheral options:nil];
    [self startOutTimerForDevice:device];
}

#pragma mark 断开重连
- (void)reconnectDevice:(CRBleDevice *)device{
    [self.fitDevices addObject:[[CRBleDevice alloc] initDeviceWithPeripheral:device.peripheral BLEName:device.peripheral.name] ];
    [self connectDevice:device];
}


#pragma mark 断开连接
- (void)disconnectDevice:(CRBleDevice *)device
{
    if (!device)
        return;
    if([device.peripheral.name containsString:pc100] || [device.peripheral.name containsString:pc200] || [device.peripheral.name containsString:pc300])
    {
        //       [[CRPC_300SDK shareInstance] performSelector:@selector(deviceWillDisconnect)];
    }
    else if ([device.peripheral.name containsString:pc_68b] || [device.peripheral.name containsString:pc_60nw] || [device.peripheral.name containsString:pod] || [device.peripheral.name containsString:sp_20] || [device.peripheral.name containsString:ap_10] || [device.peripheral.name containsString:ap_20])
    {
        //        [[CRAP20SDK shareInstance] performSelector:@selector(deviceWillDisconnect)];
    }
    else if([device.peripheral.name containsString:pc80b])
    {
        
    }
    [self stopSearch];
    [_centralManager cancelPeripheralConnection:device.peripheral];
}

#pragma  mark 超时处理
/** 根据设备获取超时定时器 */
- (NSTimer *)getOutTimerForDevice:(CRBleDevice *)device
{
    NSString *key = [self getKeyStringForPeripheral:device.peripheral];
    return self.outTimers[key];
}

/** 根据设备开始超时定时器 */
- (void)startOutTimerForDevice:(CRBleDevice *)device
{
    //定时器已存在
    NSTimer *timer = [self getOutTimerForDevice:device];
    if (timer)
        return;
    //开启定时器，存进self.outTimers
    NSString *key = [self getKeyStringForPeripheral:device.peripheral];
    timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(handleConnectionOutTimeWithTimer:) userInfo:device repeats:NO];
    [self.outTimers setObject:timer forKey:key];
}

/** 根据设备停止超时定时器 */
- (void)stopOutTimerForDevice:(CRBleDevice *)device
{
    NSTimer *timer = [self getOutTimerForDevice:device];
    if (timer)
    {
        CRBleDevice *device = timer.userInfo;
        [timer invalidate];
        NSString *key = [self getKeyStringForPeripheral:device.peripheral];
        [self.outTimers removeObjectForKey:key];
    }
}


- (void)handleConnectionOutTimeWithTimer:(NSTimer *)timer
{
    CRBleDevice *device = timer.userInfo;
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Connection OutTime"}];
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
    {
        [self.delegate bleManager:self didFailToConnectDevice:device Error:error];
    }
    //连接超时，移除待连接集合
    [self.fitDevices removeAllObjects];
    [self stopOutTimerForDevice:device];
}

//#pragma mark - 95秒重连
///** 扫描某个指定的设备-->95秒断开重连测试 */
////传入之前连接的设备信息
//-(void)scanForPeripheralsWithSerivesPeripheral:(CBPeripheral *)connectedPeripheral{
//    NSString *serviceID = [self getServiceIDForPeriName:connectedPeripheral.name];
//    CBUUID *deviceUUID =  [CBUUID UUIDWithString:serviceID];
//    [_centralManager scanForPeripheralsWithServices:@[deviceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
//}


#pragma mark - --------------------------- centralManager Delegate
#pragma mark -
#pragma mark 中心管理者状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBManagerStateUnknown:
            //CRLog(@"CBManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            //CRLog(@"CBManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            //CRLog(@"CBManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            //CRLog(@"CBManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            //CRLog(@"CBManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            //CRLog(@"CBManagerStatePoweredOn");
            break;
        default:
            break;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didUpdateState:)])
        [_delegate bleManager:self didUpdateState:central.state];
}
#pragma mark 找到设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //    NSLog(@"%@",peripheral.name);
    //防止重复加入同一个设备
    for (CRBleDevice *device in self.fitDevices)
    {
        if (device.peripheral == peripheral )
            return;
    }
    // 🚫ZSY--TODO
    NSString *localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    localName = localName?localName:@"NULL";
    
    [self.fitDevices addObject:[[CRBleDevice alloc] initDeviceWithPeripheral:peripheral BLEName:localName] ];
    
    if (_modeState == 1)
    {
        if (_delegate &&[_delegate respondsToSelector:@selector(bleManager:didFindDevice:)])
        {
            [_delegate bleManager:self didFindDevice:self.fitDevices];
        }
    }
}
#pragma mark 连接设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
//    if (device.peripheral == peripheral)
//    {
        //移除超时定时器
    NSLog(@"-----didConnectPeripheral----");
        NSString *key = [self getKeyStringForPeripheral:peripheral];
        [self.outTimers[key] invalidate];
    
        peripheral.delegate = self;
        [peripheral discoverServices:nil];
        return;
//    }
}

#pragma mark 断开连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    //已连接列表移除改设备
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didDisconnectDevice:Error:)])
    {
        [self.delegate bleManager:self didDisconnectDevice:[self getConnectedDeviceForPeripheral:peripheral] Error:error];
        [self.connectedDevices removeObjectForKey:[self getKeyStringForPeripheral:peripheral]];
    }
}
#pragma mark 连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //已连接列表移除改设备
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
    {
        [self.delegate bleManager:self didFailToConnectDevice:[self getConnectedDeviceForPeripheral:peripheral] Error:error];
    }
    
}
#pragma mark - --------------------------- peripheral Delegate
#pragma mark -
#pragma mark 发现设备服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"--发现设备服务--");
    
    NSArray *services = nil;
    if (error != nil)
    {
        //CRLog(@"Error %@\n", error);
        return ;
    }
    services = [peripheral services];
    if (!services || ![services count])
    {
        //CRLog(@"No Services");

        return ;
    }
    // 分情况处理服务UUID
    [self handleDifferentDevice:peripheral ForService:services];
}

#pragma mark 分设备处理服务
- (void)handleDifferentDevice:(CBPeripheral *)peripheral ForService:(NSArray<CBService *> *)services
{
    //根据设备名称获取指定服务名称
    NSString *serviceID = [self getServiceIDForPeriName:peripheral.name];
    //获取不到则返回
    if (!serviceID)
        return;
    //搜索该服务中的特征值
    [self discoverCharaterForServiceID:serviceID FromServices:services periperal:peripheral];
}

/* 根据不同设备查找指定服务名称 */
- (NSString *)getServiceIDForPeriName:(NSString *)periName
{
    if ([periName containsString:pc_60nw] && ![periName containsString:pc_60nw_1])
    {
//        return @"49535343-FE7D-4AE5-8FA9-9FAFD205E455";
        return @"FFF0";
    }
    if ([periName containsString:ap_10] || [periName containsString:ap_20] || [periName containsString:pc_60nw_1] || [periName containsString:h600] || [periName containsString:pc_68b] || [periName containsString:pod])
        return @"FFB0";
    else if ([periName containsString:sp_20] || [periName containsString:pc300] || [periName containsString:pc200] || [periName containsString:pc100] || [periName containsString:pc80b] || [periName containsString:eBody_Scale] || [periName containsString:pc_66b])
        return @"FFF0";
    if ([periName containsString:pc_60f] || [periName containsString:OxySmart] || [periName containsString:BabyOximeter] || [periName containsString:OxyKnight]|| [periName containsString:pc_60e])
        return @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
    return nil;
}

/* 遍历服务数组，找出指定服务，并查找其特征值。*/
- (void)discoverCharaterForServiceID:(NSString *)serviceID FromServices:(NSArray<CBService *> *)services periperal:(CBPeripheral *)peri
{
    //遍历服务
    for (CBService *service in services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:serviceID]])
            [peri discoverCharacteristics:nil forService:service];
    }
}

#pragma mark 发现指定服务的特征值
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //分设备
    if (error != nil)
    {
        //CRLog(@"Error %@\n", error);
        return ;
    }
    //找到对应的设备
    CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
    if (!device)
        return;
    //保存特征值
    [self handleCharacteristicsForService:service device:device];
}

- (void)handleCharacteristicsForService:(CBService *)service device:(CRBleDevice *)device
{
    NSArray *characteristics = [service characteristics];
    //PC100，PC200，PC300，PC80B
    if ([device.peripheral.name containsString:pc100] || [device.peripheral.name containsString:pc200] || [device.peripheral.name containsString:pc300] || [device.peripheral.name containsString:pc80b] || [device.peripheral.name containsString:pc_66b] || [device.peripheral.name containsString:sp_20 ])
    {
        //保存特征值
        for (CBCharacteristic *cha in characteristics)
        {
            //通知特征，订阅
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
            //写特征，保存
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]])
                device.writeCharact = cha;
        }
        return;
    }
    if ([device.peripheral.name containsString:pc_60nw] || [device.peripheral.name containsString:h600] || [device.peripheral.name containsString:pc_68b] || [device.peripheral.name containsString:pod] || [device.peripheral.name containsString:ap_10] || [device.peripheral.name containsString:ap_20])
    {
        //pc_60nw 和 pc_60nw_1 都能进这里，在此区分，不包含pc_60nw_1的位FFF1,2
        if (![device.peripheral.name containsString:pc_60nw_1] && [device.peripheral.name containsString:pc_60nw])
        {
            //保存特征值
            for (CBCharacteristic *cha in characteristics)
            {
                if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]])             //通知特征，订阅
                    [device.peripheral setNotifyValue:YES forCharacteristic:cha];
                if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]])               //写特征，保存
                    device.writeCharact = cha;
            }
            return;
        }
        //保存特征值
        for (CBCharacteristic *cha in characteristics)
        {
            //通知特征，订阅
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFB2"]])
            {
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
                //写特征，保存
                device.writeCharact = cha;
            }
        }
        return;
    }
    if ([device.peripheral.name containsString:eBody_Scale])
    {
        //保存特征值
        for (CBCharacteristic *cha in characteristics)
        {
            //通知特征，订阅
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF4"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
        }
        return;
    }
    if ([device.peripheral.name containsString:pc_60f] || [device.peripheral.name containsString:OxySmart] || [device.peripheral.name containsString:BabyOximeter]|| [device.peripheral.name containsString:OxyKnight]|| [device.peripheral.name containsString:pc_60e])
    {
        //保存特征值
        for (CBCharacteristic *cha in characteristics)
        {
            //通知特征，订阅
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"]])
                //写特征，保存
                device.writeCharact = cha;
        }
        return;
    }
}

- (CRBleDevice *)getFitDeviceForPeripheral:(CBPeripheral *)peripheral
{
    CRBleDevice *device;
    for (CRBleDevice *dev in self.fitDevices)
    {
        if (dev.peripheral == peripheral)
        {
            device = dev;
            break;
        }
    }
    return device;
}

- (CRBleDevice *)getConnectedDeviceForPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral)
        return nil;
    return self.connectedDevices[[NSString stringWithFormat:@"%@-%@",peripheral.name,peripheral.identifier.UUIDString]];
}

- (NSString *)getKeyStringForPeripheral:(CBPeripheral *)peripheral
{
    return [NSString stringWithFormat:@"%@-%@",peripheral.name,peripheral.identifier];
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    
    NSLog(@"---到这是去发现服务特征了---");
    
    NSStringFromSelector(@selector(setName:));
    if (characteristic.isNotifying)
    {
        CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
        //更改连接状态
        device.connectionState = CRBLESDKConnectionStateConnecting;
        //加入已连接集合
        [self.connectedDevices setObject:device forKey:[NSString stringWithFormat:@"%@-%@",device.peripheral.name,device.peripheral.identifier.UUIDString]];
        //1.通知代理连接成功
        if (self.delegate &&[self.delegate respondsToSelector:@selector(bleManager:didConnectDevice:)])
        {
            [self.delegate bleManager:self didConnectDevice:device];
        }
        //连接成功，移除待连接集合
        [self.fitDevices removeObject:device];

        //2.开始发送心跳包
    }
}
#pragma mark 设备写入二进制数据后
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error)
    {
        return;
    }
    [peripheral readValueForCharacteristic:characteristic];
}
#pragma mark 获取到设备发送的二进制数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    //NSLog(@"data == %@",data);
    /*   调试用(-------------------开始) */
    NSUInteger len = data.length;
    Byte *byte = (Byte *)[data bytes];
    NSString *commandString = @"";
    for (int i = 0; i < len; i++)
    {
        NSString *byteS =  [NSString stringWithFormat:@"-%02x",byte[i]];
        commandString =  [commandString stringByAppendingString:byteS];
    }
//    if ([commandString containsString:@"aa-55-53-07-01"])
//    {
//        NSLog(@"%@",commandString);
//
//    }
    /*   调试用(-------------------结束) */
    if (!data || !data.length)
        return;
    CRBleDevice *device = [self getConnectedDeviceForPeripheral:peripheral];
    //数据不为空时，增加数据
    //PC100,PC200,PC300 共用
    if ([peripheral.name containsString:pc100] || [peripheral.name containsString:pc200] || [peripheral.name containsString:pc300]){}
        //[[CRPC_300SDK shareInstance] appendingNewData:data FromDevice:device];
    //pc_60nw,pod,ap_20,sp_20, pc_68b共用
    else if ([peripheral.name containsString:pc_60nw] ||[peripheral.name containsString:pod] ||[peripheral.name containsString:ap_10] ||[peripheral.name containsString:ap_20] ||[peripheral.name containsString:sp_20] ||[peripheral.name containsString:pc_68b]||[peripheral.name containsString:pc_66b] ||[peripheral.name containsString:pc_60f] || [device.peripheral.name containsString:OxySmart] || [device.peripheral.name containsString:BabyOximeter]|| [device.peripheral.name containsString:OxyKnight]|| [peripheral.name containsString:pc_60e])
        [[CRAP20SDK shareInstance] appendingNewData:data FromDevice:device];
    else if([peripheral.name containsString:pc80b]){}
        //[[CRPC80BSDK shareInstance] appendingNewData:data FromDevice:device];
    else if([peripheral.name containsString:h600]){}
        //[[CRH600SDK shareInstance] appendingNewData:data FromDevice:device];
    else if ([peripheral.name containsString:eBody_Scale]){}
        //[[CRWeightingScaleSDK shareInstance] appendingNewData:data FromDevice:device];
}


@end

