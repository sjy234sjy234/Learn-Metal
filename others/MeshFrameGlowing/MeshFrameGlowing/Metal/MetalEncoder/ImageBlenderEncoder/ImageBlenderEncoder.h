//
//  ImageBlenderEncoder.h
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalContext.h"

@interface ImageBlenderEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context andAlpha: (const float) alpha;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer firstTexture: (id<MTLTexture>) firstTexture secondTexture: (id<MTLTexture>) secondTexture dstTexture: (id<MTLTexture>) dstTexture;

@end
