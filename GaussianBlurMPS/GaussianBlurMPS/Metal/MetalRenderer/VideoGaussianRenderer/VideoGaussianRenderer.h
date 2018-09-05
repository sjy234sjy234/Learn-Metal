//
//  VideoGaussianRenderer.h
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalContext.h"

@interface VideoGaussianRenderer : NSObject

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context andSigma: (const float) sigma;
- (void)render: (CVPixelBufferRef)videoPixelBuffer;

@end
