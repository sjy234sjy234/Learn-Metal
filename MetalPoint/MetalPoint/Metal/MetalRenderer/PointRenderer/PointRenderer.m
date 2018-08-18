//
//  PointRenderer.m
//  MetalPoint
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "PointRenderer.h"

typedef struct
{
    vector_float4 position;
    vector_float4 color;
} Vertex;

@interface PointRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLRenderPipelineState> pointRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> pointVertexBuffer;

@end

@implementation PointRenderer

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
    
    id<MTLFunction> pointVertexFunc = [library newFunctionWithName:@"point_vertex_main"];
    id<MTLFunction> pointFragmentFunc = [library newFunctionWithName:@"point_fragment_main"];
    
    MTLRenderPipelineDescriptor *pointPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pointPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pointPipelineDescriptor.vertexFunction = pointVertexFunc;
    pointPipelineDescriptor.fragmentFunction = pointFragmentFunc;
    
    _pointRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pointPipelineDescriptor
                                                                                   error:&error];
    
    if (!_pointRenderPipeline)
    {
        NSLog(@"Error occurred when creating point render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    static const Vertex pointVertices[] =
    {
        { .position = { -0.5, -0.5, 0, 1 }, .color = { 1, 0, 0, 1 } },
        { .position = { -0.5,  0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
        { .position = {  0.5, -0.5, 0, 1 }, .color = { 0, 0, 1, 1 } },
        { .position = {  0.5,  0.5, 0, 1 }, .color = { 0, 1, 0, 1 } }
    };
    _pointVertexBuffer = [_metalContext.device newBufferWithBytes:pointVertices
                                                              length:sizeof(pointVertices)
                                                             options:MTLResourceOptionCPUCacheModeDefault];
}

- (void)draw
{
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    if (drawable)
    {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"PointRendererCommand";
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:_pointRenderPipeline];
        [commandEncoder setVertexBuffer: _pointVertexBuffer offset:0 atIndex:0];
        [commandEncoder drawPrimitives: MTLPrimitiveTypePoint vertexStart: 0 vertexCount: 4];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end
