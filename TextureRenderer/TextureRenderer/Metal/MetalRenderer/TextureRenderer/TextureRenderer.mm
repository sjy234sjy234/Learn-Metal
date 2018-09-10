//
//  TextureRenderer.m
//  Learn-Metal
//
//  Created by  沈江洋 on 28/12/2017.
//  Copyright © 2017  沈江洋. All rights reserved.
//

#import "TextureRenderer.h"
#import "MathUtilities.hpp"

@interface TextureRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLSamplerState> samplerState;
@property (nonatomic, strong) id<MTLRenderPipelineState> textureRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> textureVertexBuffer;

@end

@implementation TextureRenderer

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _layer = layer;
        _metalContext=context;
        [self buildMetal];
        [self buildPipelines];
        [self buildResources];
    }
    return self;
}

- (void)buildMetal
{
    _layer.device = _metalContext.device;
    _layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    id<MTLFunction> textureVertexFunc = [library newFunctionWithName:@"texture_vertex_main"];
    id<MTLFunction> textureFragmentFunc = [library newFunctionWithName:@"texture_fragment_main"];
    
    MTLRenderPipelineDescriptor *texturePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    texturePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    texturePipelineDescriptor.vertexFunction = textureVertexFunc;
    texturePipelineDescriptor.fragmentFunction = textureFragmentFunc;
    
    _textureRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:texturePipelineDescriptor
                                                                                  error:&error];
    
    if (!_textureRenderPipeline)
    {
        NSLog(@"Error occurred when creating texture render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    const float textureVertices[] =
    {
        -1.0, -1.0, 0,
        -1.0,  1.0, 0,
        1.0, -1.0, 0,
        1.0,  1.0, 0
    };
    _textureVertexBuffer = [_metalContext.device newBufferWithBytes:textureVertices
                                                             length:sizeof(textureVertices)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
    _samplerState = [_metalContext.device newSamplerStateWithDescriptor:samplerDesc];
}

- (void)draw: (id<MTLTexture>) inTexture
{
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    if (drawable)
    {
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"TextureRendererCommand";
        
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 1.0, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        [renderEncoder setRenderPipelineState:_textureRenderPipeline];
        [renderEncoder setFragmentTexture:inTexture atIndex:0];
        [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
        [renderEncoder setVertexBuffer: _textureVertexBuffer offset:0 atIndex:0];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:1 vertexCount:3];
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end
