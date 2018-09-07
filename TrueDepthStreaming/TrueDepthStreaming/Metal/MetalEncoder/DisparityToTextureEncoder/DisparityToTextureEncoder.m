//
//  DisparityToTextureEncoder.m
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "DisparityToTextureEncoder.h"

@interface DisparityToTextureEncoder ()

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) MTLSize threadgroupSize;
@property (nonatomic, assign) MTLSize threadgroupCount;

@end

@implementation DisparityToTextureEncoder

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    // Load the kernel function from the library
    id<MTLFunction> kernelFunction = [library newFunctionWithName:@"disparityToTexture"];
    
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

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer inDisparityBuffer:(const id<MTLBuffer>)inDisparityBuffer outTexture: (id<MTLTexture>) outTexture
{
    if(!commandBuffer)
    {
        NSLog(@"invalid commandBuffer");
        return ;
    }
    if(!inDisparityBuffer)
    {
        NSLog(@"invalid disparity buffer");
        return ;
    }
    if(!outTexture)
    {
        NSLog(@"invalid out texture");
        return ;
    }
    
    const NSUInteger width = 8;
    const NSUInteger height = 8;
    const NSUInteger depth = 1;
    _threadgroupSize = MTLSizeMake((width), (height), depth);
    _threadgroupCount.width  = (outTexture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (outTexture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
    _threadgroupCount.depth = depth;
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipeline];
    [computeEncoder setBuffer: inDisparityBuffer offset:0 atIndex:0];
    [computeEncoder setTexture: outTexture atIndex:0];
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];
}

@end
