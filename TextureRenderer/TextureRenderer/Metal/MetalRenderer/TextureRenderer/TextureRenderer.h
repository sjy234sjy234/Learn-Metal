//
//  TextureRenderer.h
//  Learn-Metal
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "MetalContext.h"

@interface TextureRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context;
- (void)draw: (id<MTLTexture>) inTexture;

@end
