//
//  VideoRenderer.m
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "VideoRenderer.h"
#import "TextureRendererEncoder.h"

@interface VideoRenderer ()

@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@end

@implementation VideoRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
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
        //new commander buffer
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"VideoRendererCommand";
        
        //encode drawable render process
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: inTexture destinationTexture: drawable.texture];
        [commandBuffer presentDrawable:drawable];
        
        //commit commander buffer
        [commandBuffer commit];
    }
}

@end
