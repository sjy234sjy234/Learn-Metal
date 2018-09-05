//
//  FrameRenderer.h
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

@interface FrameRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)setThickNess: (float) thickness;
- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (int) vertexNum andFaceNum: (int) faceNum;
- (void)drawWithMvpMatrix:  (simd::float4x4)mvpTransform;

@end
