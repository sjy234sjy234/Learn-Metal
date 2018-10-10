//
//  FrameGlowingRenderer.m
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrameGlowingRenderer.h"
#import "MeshDepthMaskEncoder.h"
#import "LineRendererEncoder.h"
#import "GaussianBlurEncoder.h"
#import "ImageBlenderEncoder.h"
#import "TextureRendererEncoder.h"

@interface FrameGlowingRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) MeshDepthMaskEncoder *meshDepthMaskEncoder;
@property (nonatomic, strong) LineRendererEncoder *lineRendererEncoder;
@property (nonatomic, strong) GaussianBlurEncoder *gaussianBlurEncoder;
@property (nonatomic, strong) ImageBlenderEncoder *imageBlenderEncoder;
@property (nonatomic, strong) TextureRendererEncoder *textureRendererEncoder;

@property (nonatomic, strong) id<MTLTexture> colorTexture;
@property (nonatomic, strong) id<MTLTexture> blurTexture;
@property (nonatomic, strong) id<MTLTexture> glowTexture;
@property (nonatomic, strong) id<MTLTexture> depthTexture;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> meshIndexBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineIndexBuffer;

@end

@implementation FrameGlowingRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context andBlurSigma: (const float) sigma andBlendAlpha: (const float) alpha
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        self.meshDepthMaskEncoder = [[MeshDepthMaskEncoder alloc] initWithContext: _metalContext];
        self.lineRendererEncoder = [[LineRendererEncoder alloc] initWithContext: _metalContext];
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
    [_lineRendererEncoder setThickNess: thickness];
}

- (void)setBackColor: (const simd::float4) color
{
    MTLClearColor clearColor = MTLClearColorMake(color.x, color.y, color.z, color.w);
    [_meshDepthMaskEncoder setClearColor: clearColor];
    [_lineRendererEncoder setClearColor: clearColor];
}

- (void)setLineColor: (const simd::float4) color
{
    [_lineRendererEncoder setLineColor: color];
}

- (void)setupFrameWithVertex: (const float *) vertices
                    andIndex: (const uint32_t *)indices
                andVertexNum: (const int) vertexNum
                  andFaceNum: (const int) faceNum
{
    //vertex
    _vertexBuffer = [_metalContext.device newBufferWithBytes: vertices length: vertexNum * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    //mesh index
    _meshIndexBuffer = [_metalContext.device newBufferWithBytes: indices
                                                         length: faceNum * 3 * sizeof(uint32_t)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    //line index
    uint32_t *lineIndices = new uint32_t[faceNum * 6];
    for(int i = 0; i < faceNum; ++i)
    {
        lineIndices[6 * i] = indices[3 * i];
        lineIndices[6 * i + 1] = indices[3 * i + 1];
        lineIndices[6 * i + 2] = indices[3 * i + 1];
        lineIndices[6 * i + 3] = indices[3 * i + 2];
        lineIndices[6 * i + 4] = indices[3 * i + 2];
        lineIndices[6 * i + 5] = indices[3 * i];
    }
    _lineIndexBuffer = [_metalContext.device newBufferWithBytes: lineIndices
                                                         length: faceNum * 6 * sizeof(uint32_t)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    delete[] lineIndices;
}

- (void)setupFrameWithQuadrangleVertex: (const float *) vertices
                              andIndex: (const uint32_t *)indices
                          andVertexNum: (const int) vertexNum
                            andFaceNum: (const int) faceNum
{
    //vertex
    _vertexBuffer = [_metalContext.device newBufferWithBytes: vertices length: vertexNum * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    //mesh index
    uint32_t *meshIndices = new uint32_t[faceNum * 6];
    for(int i = 0; i < faceNum; ++i)
    {
        meshIndices[6 * i] = indices[4 * i];
        meshIndices[6 * i + 1] = indices[4 * i + 1];
        meshIndices[6 * i + 2] = indices[4 * i + 2];
        meshIndices[6 * i + 3] = indices[4 * i];
        meshIndices[6 * i + 4] = indices[4 * i + 2];
        meshIndices[6 * i + 5] = indices[4 * i + 3];
    }
    _meshIndexBuffer = [_metalContext.device newBufferWithBytes: meshIndices
                                                         length: faceNum * 6 * sizeof(uint32_t)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    delete[] meshIndices;
    //line index
    uint32_t *lineIndices = new uint32_t[faceNum * 8];
    for(int i = 0; i < faceNum; ++i)
    {
        lineIndices[8 * i] = indices[4 * i];
        lineIndices[8 * i + 1] = indices[4 * i + 1];
        lineIndices[8 * i + 2] = indices[4 * i + 1];
        lineIndices[8 * i + 3] = indices[4 * i + 2];
        lineIndices[8 * i + 4] = indices[4 * i + 2];
        lineIndices[8 * i + 5] = indices[4 * i + 3];
        lineIndices[8 * i + 6] = indices[4 * i + 3];
        lineIndices[8 * i + 7] = indices[4 * i];
    }
    _lineIndexBuffer = [_metalContext.device newBufferWithBytes: lineIndices
                                                         length: faceNum * 8 * sizeof(uint32_t)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    delete[] lineIndices;
}

- (void)renderWithMvpMatrix: (const simd::float4x4)mvpTransform
{
    //new commander buffer
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"FrameGlowingRenderingCommand";
    
    //encode offscreen frame render process
    //encode mesh depth mask
    [_meshDepthMaskEncoder encodeToCommandBuffer: commandBuffer
                                 dstColorTexture: _colorTexture
                                 dstDepthTexture: _depthTexture
                                      clearColor: YES
                                      clearDepth: YES
                                     pointBuffer: _vertexBuffer
                                     indexBuffer: _meshIndexBuffer
                                       mvpMatrix: mvpTransform];
    //encode line renderer
    [_lineRendererEncoder encodeToCommandBuffer: commandBuffer
                                dstColorTexture: _colorTexture
                                dstDepthTexture: _depthTexture
                                     clearColor: NO
                                     clearDepth: NO
                                    pointBuffer: _vertexBuffer
                                    indexBuffer: _lineIndexBuffer
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
