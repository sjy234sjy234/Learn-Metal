//
//  DepthRenderer.m
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "DepthRenderer.h"
#import "DisparityToTextureEncoder.h"
#import "TextureRendererEncoder.h"

@interface DepthRenderer ()

@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) DisparityToTextureEncoder *disparityToTextureEncoder;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@end

@implementation DepthRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.disparityToTextureEncoder = [[DisparityToTextureEncoder alloc] initWithContext: _metalContext];
        self.textureRendererEncoder = [[TextureRendererEncoder alloc] initWithContext: _metalContext];
    }
    return self;
}

//- (void)render: (CVPixelBufferRef)videoPixelBuffer
//{
//    if(!videoPixelBuffer)
//    {
//        NSLog(@"invalid pixel buffer");
//        return;
//    }
//
//    id<MTLTexture> inTexture = [_metalContext textureFromPixelBuffer: videoPixelBuffer];
//    id<CAMetalDrawable> drawable = [_layer nextDrawable];
//    if(drawable)
//    {
//        //new commander buffer
//        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
//        commandBuffer.label = @"VideoRendererCommand";
//
//        //encode drawable render process
//        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: inTexture destinationTexture: drawable.texture];
//        [commandBuffer presentDrawable:drawable];
//
//        //commit commander buffer
//        [commandBuffer commit];
//    }
//}

- (void)render: (CVPixelBufferRef)depthPixelBuffer
{
    if(!depthPixelBuffer)
    {
        NSLog(@"invalid pixel buffer");
        return;
    }
    
    id<MTLBuffer> inDisparityBuffer = [_metalContext bufferWithF16PixelBuffer: depthPixelBuffer];
    
    size_t width = CVPixelBufferGetWidth(depthPixelBuffer);
    size_t height = CVPixelBufferGetHeight(depthPixelBuffer);
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage=MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget;
    id<MTLTexture> outTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
    
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {
        //new commander buffer
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"VideoRendererCommand";
        
        //encode depth to texture kernel
        [_disparityToTextureEncoder encodeToCommandBuffer: commandBuffer inDisparityBuffer: inDisparityBuffer outTexture: outTexture];
        
        //encode drawable render process
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: outTexture destinationTexture: drawable.texture];
        [commandBuffer presentDrawable:drawable];
        
        //commit commander buffer
        [commandBuffer commit];
    }
}

@end
