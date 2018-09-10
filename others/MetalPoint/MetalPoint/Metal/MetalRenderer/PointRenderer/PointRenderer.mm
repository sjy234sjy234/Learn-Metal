//
//  PointRenderer.m
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/9.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "PointRenderer.h"
#import "PointRendererEncoder.h"

@interface PointRenderer ()

@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) PointRendererEncoder *pointRendererEncoder;

@property (nonatomic, strong) id<MTLTexture> depthTexture;

@end

@implementation PointRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext = context;
        self.pointRendererEncoder = [[PointRendererEncoder alloc] initWithContext: _metalContext];
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
    textureDescriptor.pixelFormat = MTLPixelFormatDepth32Float;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage=MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget;
    _depthTexture = [_metalContext.device newTextureWithDescriptor: textureDescriptor];
}

- (void)setBackColor: (const simd::float4) color
{
    [_pointRendererEncoder setClearColor: MTLClearColorMake(color.x, color.y, color.z, color.w)];
}

- (void)setPointSize: (const float) size
{
    [_pointRendererEncoder setPointSize: size];
}

- (void)setPointColor: (const simd::float4) color
{
    [_pointRendererEncoder setPointColor: color];
}

- (void)renderPoints: (const float *) points
            pointNum: (const int) pNum
           mvpMatrix: (const simd::float4x4)mvpTransform
{
    if(!points || pNum <= 0)
    {
        NSLog(@"invalid points");
        return;
    }
    
    id<MTLBuffer> pointBuffer = [_metalContext.device newBufferWithBytes: points length: pNum * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    //new commander buffer
    id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
    commandBuffer.label = @"PointRendererCommand";
    
    //encode drawable render process
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    if(drawable)
    {
        [_pointRendererEncoder encodeToCommandBuffer: commandBuffer
                                            outColor: drawable.texture
                                            outDepth: _depthTexture
                                          clearColor: YES
                                          clearDepth: YES
                                         pointBuffer: pointBuffer
                                           mvpMatrix: mvpTransform];
        [commandBuffer presentDrawable:drawable];
    }
    
    //commit commander buffer
    [commandBuffer commit];
}

@end
