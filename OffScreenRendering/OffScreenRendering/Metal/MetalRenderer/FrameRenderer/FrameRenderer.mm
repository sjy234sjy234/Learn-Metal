//
//  FrameRenderer.m
//  OffScreenRendering
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrameRenderer.h"
#import "FrameRendererEncoder.h"
#import "TextureRendererEncoder.h"

@interface FrameRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) FrameRendererEncoder *frameRendererEncoder;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@property (nonatomic, strong) id<MTLTexture> colorTexture;
@property (nonatomic, strong) id<MTLTexture> depthTexture;

@end

@implementation FrameRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.frameRendererEncoder = [[FrameRendererEncoder alloc] initWithContext: _metalContext];
        self.textureRendererEncoder = [[TextureRendererEncoder alloc] initWithContext: _metalContext];
        [self buildTextures];
    }
    return self;
}

- (void)buildTextures
{
    CGSize drawableSize = _layer.drawableSize;
    size_t width = drawableSize.width;
    size_t height = drawableSize.height;
    
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage=MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget;
    _colorTexture=[_metalContext.device newTextureWithDescriptor:textureDescriptor];
    textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    _depthTexture=[_metalContext.device newTextureWithDescriptor:textureDescriptor];
}

- (void)setThickNess: (const float) thickness
{
    [_frameRendererEncoder setThickNess: thickness];
}
- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (const int) vertexNum andFaceNum: (const int) faceNum
{
    [_frameRendererEncoder setupFrameWithVertex: vertices andIndex: indices andVertexNum: vertexNum andFaceNum: faceNum];
}

- (void)renderWithMvpMatrix: (const simd::float4x4)mvpTransform
{
    //new commander buffer
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FrameRendererCommand";
    
    //encode offscreen frame render process
    [_frameRendererEncoder encodeToCommandBuffer: commandBuffer dstColorTexture: _colorTexture dstDepthTexture: _depthTexture mvpMatrix: mvpTransform];
    
    //encode drawable render process
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: _colorTexture destinationTexture: drawable.texture];
//        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: _depthTexture destinationTexture: drawable.texture];
        [commandBuffer presentDrawable:drawable];
    }
    
    //commit commander buffer
    [commandBuffer commit];
}

@end
