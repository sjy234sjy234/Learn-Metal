//
//  LineRenderer.h
//  MetalLine
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

@interface LineRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)draw;

@end
