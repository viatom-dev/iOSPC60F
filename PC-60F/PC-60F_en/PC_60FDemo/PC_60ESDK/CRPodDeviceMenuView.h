//
//  CRPodDeviceMenuView.h
//  health
//
//  Created by Creative on 2020/11/17.
//  Copyright © 2020 creative. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CRPodDeviceMenuView : UIView

/**
 Encapsulate a view for displaying Pod device menu items（Spo2L，PrH，PrL， ContinuousOrSpot，Deep，Rotate）
 */

/** Spo2L：Blood oxygen lower limit setting menu item */
@property (nonatomic, assign) int lowSpO2;
/** PrH：Pulse rate upper limit device menu item */
@property (nonatomic, assign) int highPr;
/** PrL：Pulse rate lower limit device menu item */
@property (nonatomic, assign) int lowPr;
/** ContinuousOrSpot： 01: Spot check；02: Continuous */
@property (nonatomic, assign) int spot;
/** Deep：Beeper setting menu item。01，On；02，Off；00，Not set */
@property (nonatomic, assign) int beepOn;
/** Rotate：Rotary switch. 01，On；02，Off；00，Not set */
@property (nonatomic, assign) int rotateOn;

- (instancetype)initWithDeviceName:(NSString *)deviceName Update:(void(^)(int lowSpO2, int highPr, int lowPr, int spot, int beepOn, int rotateOn))update Cancel:(void(^)(void))cancel;

@end

NS_ASSUME_NONNULL_END
