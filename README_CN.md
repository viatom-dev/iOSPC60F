## iOSPC60F

- ##### 1.1 版本变更日志

  ##### [变更日志](https://github.com/viatom-dev/iOSPC60F/blob/main/ChangeLog.md)

- ##### 1.2 功能描述

  iOSPC60F 是为源动健康多款产品开发的 iOS 版本的 SDK，目前主要支持 PC_60F。

  主要功能大致分为通信和解析两部分。

  1、通信功能

  用于使用 Bluetooth 的 iOS 设备与作为外设的 PC_60F 进行通信，可以从中获取各类数据 

  2、解析功能

  用于解析通信获取后的各类数据，并返回相应的模型供其他开发者使用。

## 环境

  iOS 9.0及以上

## SDK 的导入

只需把SDK文件导入项目工程即可, SDK 中包含 4 个文件:

CRAP20SDK.h, CRBleDevice.h, CRBlueToothManager.h, libSpO2SDK.a

## 快速使用

### CRBlueToothManager

**处理中央和外设的蓝牙连接类，是一个单例。**

遵循代理：CRBlueToothManagerDelegate

- 当前 iOS 设备的蓝牙状态返回

  回调：- (void)bleManager:(CRBlueToothManager *)manager didUpdateState:(CBManagerState)state

- 扫描蓝牙设备。

  通过回调  - (void)bleManager:(CRBlueToothManager *)manager didSearchCompleteWithResult:(NSArray<CRBleDevice *> *)deviceList  从扫描到的设备列表中筛选出需要的。

```objective-c
- (void)startSearchDevicesForSeconds:(NSUInteger)seconds;
```

- 停止搜索蓝牙设备

```objective-c
- (void)stopSearch;
```

- 连接某一蓝牙设备，此方法调用前提是扫描到了符合条件的设备。

  连接成功的回调：- (void)bleManager:(CRBlueToothManager *)manager didConnectDevice:(CRBleDevice *)device

  连接失败的回调：- (void)bleManager:(CRBlueToothManager *)manager didFailToConnectDevice:(CRBleDevice *)device Error:(NSError *)error

```objective-c
- (void)connectDevice:(CRBleDevice *)device;
```

- 断开与设备的蓝牙连接；此方法调用的前提是已经与设备建立蓝牙连接。

  成功断开连接的回调：- (void)bleManager:(CRBlueToothManager *)manager didDisconnectDevice:(CRBleDevice *)device Error:(NSError *)error

```objective-c
- (void)disconnectDevice:(CRBleDevice *)device;
```

### CRBleDevice

**连接的设备模型**。

### CRAP20SDK

**为SDK对外暴露的方法，内部封装了蓝牙通信的数据处理逻辑，是一个单例。**

遵循代理：CRAP20SDKDelegate

- 接收血氧参数。

  在想要接收该数据的控制器中实现对应的代理方法：- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Value:(int)spo2 PulseRate:(int)pr PI:(int)pi State:(CRAP_20Spo2State)state Mode:(CRAP_20Spo2Mode)mode BattaryLevel:(int)battaryLevel FromDevice:(CRBleDevice *)device

- 查询设备序列号。

  查询成功的回调：- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSerialNumber:(NSString *)serialNumber FromDevice:(CRBleDevice *)device

```objective-c
- (void)queryForSerialNumberForDevice:(CRBleDevice *)device;
```

## 更多详细信息

参看对应协议和头文件。

蓝牙连接相关：[CRBlueToothManager.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRBlueToothManager.h)

设备模型：[CRBleDevice.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRBleDevice.h)

App 与蓝牙设备间的数据通信：[CRAP20SDK.h](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/PC_60FDemo/PC_60ESDK/PC_60ESDK/CRAP20SDK.h)

协议：《[科瑞康指夹血氧仪编程指南.doc](https://github.com/viatom-dev/iOSPC60F/blob/main/PC-60F/PC-60F_zh/科瑞康指夹血氧仪编程指南.doc)》



