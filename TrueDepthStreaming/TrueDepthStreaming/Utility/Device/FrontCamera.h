//
//  FrontCamera.h
//  Learn-Metal
//
//  Created by  沈江洋 on 22/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol FrontCameraDelegate <NSObject>

- (void)didOutputVideoBuffer: (CVPixelBufferRef) videoPixelBuffer andDepthBuffer: (CVPixelBufferRef) depthPixelBuffer ;

- (void)didOutputVideoBuffer: (CVPixelBufferRef) videoPixelBuffer;

@end

@interface FrontCamera : NSObject

@property (nonatomic, assign) id<FrontCameraDelegate> delegate;

- (instancetype)initWithDepthTag: (BOOL) isEnabled;
- (void)startCapture;
- (void)stopCapture;
- (void)setExposurePoint: (CGPoint) pos;
- (void)getFrameWidth: (size_t *) width andFrameHeight: (size_t *)height;

@end
