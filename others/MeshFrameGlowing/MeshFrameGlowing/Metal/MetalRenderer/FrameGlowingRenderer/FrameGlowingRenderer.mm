//
//  FrameGlowingRenderer.m
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrameGlowingRenderer.h"
#import "FrameRendererEncoder.h"
#import "GaussianBlurEncoder.h"
#import "ImageBlenderEncoder.h"
#import "TextureRendererEncoder.h"

@interface FrameGlowingRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) FrameRendererEncoder *frameRendererEncoder;
@property (nonatomic, strong) GaussianBlurEncoder *gaussianBlurEncoder;
@property (nonatomic, strong) ImageBlenderEncoder *imageBlenderEncoder;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@property (nonatomic, strong) id<MTLTexture> colorTexture;
@property (nonatomic, strong) id<MTLTexture> blurTexture;
@property (nonatomic, strong) id<MTLTexture> glowTexture;
@property (nonatomic, strong) id<MTLTexture> depthTexture;

@end

@implementation FrameGlowingRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context andBlurSigma: (const float) sigma andBlendAlpha: (const float) alpha
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.frameRendererEncoder = [[FrameRendererEncoder alloc] initWithContext: _metalContext];
        self.gaussianBlurEncoder = [[GaussianBlurEncoder alloc] initWithContext: _metalContext andSigma: sigma];
        self.imageBlenderEncoder = [[ImageBlenderEncoder alloc] initWithContext: _metalContext andAlpha: alpha];
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
    _colorTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
    _blurTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
    _glowTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
    textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    _depthTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
}

- (void)setThickNess: (const float) thickness
{
    [_frameRendererEncoder setThickNess: thickness];
}

- (void)setBackColor: (const simd::float4) color
{
    [_frameRendererEncoder setClearColor: MTLClearColorMake(color.x, color.y, color.z, color.w)];
}

- (void)setLineColor: (const simd::float4) color
{
    [_frameRendererEncoder setLineColor: color];
}

- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (const int) vertexNum andFaceNum: (const int) faceNum
{
    [_frameRendererEncoder setupFrameWithVertex: vertices andIndex: indices andVertexNum: vertexNum andFaceNum: faceNum];
}

- (void)setupFrameWithQuadrangleVertex: (const float *) vertices
                              andIndex: (const uint32_t *)indices
                          andVertexNum: (const int) vertexNum
                            andFaceNum: (const int) faceNum
{
    [_frameRendererEncoder setupFrameWithQuadrangleVertex: vertices andIndex: indices andVertexNum: vertexNum andFaceNum: faceNum];
}

- (void)renderWithMvpMatrix: (const simd::float4x4)mvpTransform
{
    //new commander buffer
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FrameGlowingRenderingCommand";
    
    //encode offscreen frame render process
    [_frameRendererEncoder encodeToCommandBuffer: commandBuffer
                                 dstColorTexture: _colorTexture
                                 dstDepthTexture: _depthTexture
                                      clearColor: YES
                                      clearDepth: YES
                                       mvpMatrix: mvpTransform];
    
    //encode gaussion process
    [_gaussianBlurEncoder encodeToCommandBuffer: commandBuffer srcTexture: _colorTexture dstTexture: _blurTexture];
    
    //encode blending process
    [_imageBlenderEncoder encodeToCommandBuffer: commandBuffer firstTexture: _colorTexture secondTexture: _blurTexture dstTexture: _glowTexture];
    
    //encode drawable render process
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {
        [_textureRendererEncoder encodeToCommandBuffer: commandBuffer sourceTexture: _glowTexture destinationTexture: drawable.texture];
        [commandBuffer presentDrawable:drawable];
    }
    
    //commit commander buffer
    [commandBuffer commit];
}

@end
