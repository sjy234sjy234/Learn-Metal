//
//  GaussianBlurEncoder.m
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "GaussianBlurEncoder.h"

@interface GaussianBlurEncoder ()

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MPSUnaryImageKernel *gaussianBlurKernel;

@end

@implementation GaussianBlurEncoder

- (instancetype)initWithContext: (MetalContext *)context andSigma: (const float) sigma
{
    if ((self = [super init]))
    {
        _metalContext=context;
        self.gaussianBlurKernel = [[MPSImageGaussianBlur alloc] initWithDevice: _metalContext.device sigma: sigma];
        [self.gaussianBlurKernel setEdgeMode: MPSImageEdgeModeClamp];
    }
    return self;
}

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer srcTexture: (id<MTLTexture>) srcTexture dstTexture: (id<MTLTexture>) dstTexture
{
    if(!commandBuffer)
    {
        NSLog(@"invalid commandBuffer");
        return ;
    }
    if(!srcTexture || !dstTexture)
    {
        NSLog(@"invalid texture");
        return ;
    }
    if(srcTexture.width != dstTexture.width || srcTexture.height != dstTexture.height)
    {
        NSLog(@"invalid size for blending");
        return ;
    }
    
    [_gaussianBlurKernel encodeToCommandBuffer: commandBuffer sourceTexture: srcTexture destinationTexture: dstTexture];
}

@end
