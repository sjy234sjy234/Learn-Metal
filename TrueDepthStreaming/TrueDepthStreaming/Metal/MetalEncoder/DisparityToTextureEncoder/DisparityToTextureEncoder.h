//
//  DisparityToTextureEncoder.h
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalContext.h"

@interface DisparityToTextureEncoder : NSObject

- (instancetype)initWithContext: (MetalContext *)context;
- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer inDisparityBuffer:(const id<MTLBuffer>)inDisparityBuffer outTexture: (id<MTLTexture>) outTexture;

@end
