//
//  FrameRenderer.h
//  OffScreenRendering
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MetalContext.h"

@interface FrameRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)setThickNess: (const float) thickness;
- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (const int) vertexNum andFaceNum: (const int) faceNum;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer dstColorTexture: (id<MTLTexture>) colorTexture dstDepthTexture: (id<MTLTexture>) depthTexture mvpMatrix: (simd::float4x4)mvpTransform;
- (void)renderWithMvpMatrix: (const simd::float4x4)mvpTransform;

@end
