//
//  ImageBlenderEncoder.m
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ImageBlenderEncoder.h"

@interface ImageBlenderEncoder ()

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;
@property (nonatomic, strong) id<MTLBuffer> alphaBuffer;

@end

@implementation ImageBlenderEncoder

- (instancetype)initWithContext: (MetalContext *)context andAlpha: (const float) alpha
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
        [self buildAlphaBuffer: alpha];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    // Load the kernel function from the library
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"imageBlender"];
    
    // Create a compute pipeline state
    _computePipeline = [_metalContext.device newComputePipelineStateWithFunction:kernelFunction
                                                                           error:&error];
    
    if(!_computePipeline)
    {
        // Compute pipeline State creation could fail if kernelFunction failed to load from the
        //   library.  If the Metal API validation is enabled, we automatically be given more
        //   information about what went wrong.  (Metal API validation is enabled by default
        //   when a debug build is run from Xcode)
        NSLog(@"Failed to create compute pipeline state, error %@", error);
    }
}

- (void)buildAlphaBuffer: (const float) alpha
{
    float a = alpha;
    a = a < 0.0 ? 0.0 : a;
    a = a > 1.0 ? 1.0 : a;
    _alphaBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_alphaBuffer contents], &a, sizeof(float));
}

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer firstTexture: (id<MTLTexture>) firstTexture secondTexture: (id<MTLTexture>) secondTexture dstTexture: (id<MTLTexture>) dstTexture
{
    if(!commandBuffer)
    {
        NSLog(@"invalid commandBuffer");
        return ;
    }
    if(!firstTexture || !secondTexture)
    {
        NSLog(@"invalid texture");
        return ;
    }
    if(firstTexture.width != secondTexture.width || firstTexture.height != secondTexture.height)
    {
        NSLog(@"invalid size for blending");
        return ;
    }
    
    const NSUInteger width = 8;
    const NSUInteger height = 8;
    const NSUInteger depth = 1;
    _threadgroupSize = MTLSizeMake((width), (height), depth);
    _threadgroupCount.width  = (firstTexture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (firstTexture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = depth;
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setTexture: firstTexture atIndex:0];
    [computeEncoder setTexture: secondTexture atIndex:1];
    [computeEncoder setTexture: dstTexture atIndex:2];
    [computeEncoder setBuffer: _alphaBuffer offset:0 atIndex:0];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
    
}


@end
