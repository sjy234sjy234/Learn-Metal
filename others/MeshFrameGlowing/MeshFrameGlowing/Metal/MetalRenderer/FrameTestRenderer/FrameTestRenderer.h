//
//  FrameTestRenderer.h
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalContext.h"

@interface FrameTestRenderer : NSObject

- (instancetype)initWithLayer1:(CAMetalLayer *)layer1
                    andLayer2:(CAMetalLayer *)layer2
                    andLayer3:(CAMetalLayer *)layer3
                    andContext: (MetalContext *)context
                  andBlurSigma: (const float) sigma
                 andBlendAlpha: (const float) alpha;
- (void)setThickNess: (const float) thickness;
- (void)setBackColor: (const simd::float4) color;
- (void)setLineColor: (const simd::float4) color;
- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (const int) vertexNum andFaceNum: (const int) faceNum;
- (void)setupFrameWithQuadrangleVertex: (const float *) vertices
                              andIndex: (const uint32_t *)indices
                          andVertexNum: (const int) vertexNum
                            andFaceNum: (const int) faceNum;
- (void)renderWithMvpMatrix: (const simd::float4x4)mvpTransform;

@end
