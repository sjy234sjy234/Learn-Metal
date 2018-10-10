//
//  MeshDepthMaskEncoder.h
//  MeshFrameGlowing
//
//  Created by 美戴科技 on 2018/10/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface MeshDepthMaskEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)setClearColor:(const MTLClearColor) color;
- (void)setClearDepth:(const double) depth;
- (void)encodeToCommandBuffer: (const id<MTLCommandBuffer>) commandBuffer
              dstColorTexture: (const id<MTLTexture>) colorTexture
              dstDepthTexture: (const id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (const id<MTLBuffer>) pointBuffer
                  indexBuffer: (const id<MTLBuffer>) indexBuffer
                    mvpMatrix: (simd::float4x4)mvpTransform;

@end

NS_ASSUME_NONNULL_END
