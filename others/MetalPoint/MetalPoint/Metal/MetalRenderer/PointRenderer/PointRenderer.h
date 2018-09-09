//
//  PointRenderer.h
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/9.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "MetalContext.h"

@interface PointRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)setBackColor: (const simd::float4) color;
- (void)setPointSize: (const float) size;
- (void)setPointColor: (const simd::float4) color;
- (void)renderPoints: (const float *) points
                     pointNum: (const int) pNum
                    mvpMatrix: (const simd::float4x4)mvpTransform;

@end
