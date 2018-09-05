//
//  VideoGaussianRenderer.m
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "VideoGaussianRenderer.h"
#import "GaussianBlurEncoder.h"
#import "TextureRendererEncoder.h"

@interface VideoGaussianRenderer ()

@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) GaussianBlurEncoder *gaussianBlurEncoder;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@end

@implementation VideoGaussianRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context andSigma: (const float) sigma
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.gaussianBlurEncoder = [[GaussianBlurEncoder alloc] initWithContext: _metalContext andSigma: sigma];
        self.textureRendererEncoder = [[TextureRendererEncoder alloc] initWithContext: _metalContext];
    }
    return self;
}

- (void)render: (CVPixelBufferRef)videoPixelBuffer
{
    if(!videoPixelBuffer)
    {
        NSLog(@"invalid pixel buffer");
        return;
    }
    
    id<MTLTexture> inTexture = [_metalContext textureFromPixelBuffer: videoPixelBuffer];
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {
        MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
        textureDescriptor.textureType = inTexture.textureType;
        textureDescriptor.pixelFormat = inTexture.pixelFormat;
        textureDescriptor.width = inTexture.width;
        textureDescriptor.height = inTexture.height;
        textureDescriptor.usage = inTexture.usage;
        id<MTLTexture> outTemp =  [_metalContext.device newTextureWithDescriptor:textureDescriptor];
        
        //new commander buffer
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"GaussianBlurMPSCommand";
        
        //encode gaussion process
        [_gaussianBlurEncoder encodeToCommandBuffer: commandBuffer srcTexture: inTexture dstTexture: outTemp];
        
        //encode drawable render process
        
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: outTemp destinationDrawable: drawable];
        
        //commit commander buffer
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

@end
