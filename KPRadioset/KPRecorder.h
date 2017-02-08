//
//  KPRecoder.h
//  KPRadioset
//
//  Created by Developer on 2/7/17.
//  Copyright © 2017 Павел Квачан. All rights reserved.
//

#import <Foundation/Foundation.h>


@class KPRecorder;

@protocol KPRecorderDelegate

@optional

- (void)recorder:(KPRecorder *)recorder
          levels:(NSArray *)lvls;

@end


@interface KPRecorder : NSObject

@property (nonatomic, assign) id<KPRecorderDelegate> delegate;
@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, readonly) NSString *fileName;


- (BOOL)start;
- (void)stop;

@end
