//
//  FrameRendererEncoder.h
//  MeshFrame
//
//  Created by  沈江洋 on 2018/8/29.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

@interface FrameRendererEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)setThickNess: (const float) thickness;
- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (int) vertexNum andFaceNum: (int) faceNum;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer dstColorTexture: (id<MTLTexture>) colorTexture dstDepthTexture: (id<MTLTexture>) depthTexture mvpMatrix: (const simd::float4x4)mvpTransform;

@end
