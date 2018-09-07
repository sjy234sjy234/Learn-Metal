//
//  DepthRenderer.h
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalContext.h"

@interface DepthRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
//- (void)render: (CVPixelBufferRef)videoPixelBuffer;
- (void)render: (CVPixelBufferRef)depthPixelBuffer;

@end
