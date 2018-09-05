//
//  GaussianBlurEncoder.h
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "MetalContext.h"

@interface GaussianBlurEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context andSigma: (const float) sigma;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer srcTexture: (id<MTLTexture>) srcTexture dstTexture: (id<MTLTexture>) dstTexture;

@end
