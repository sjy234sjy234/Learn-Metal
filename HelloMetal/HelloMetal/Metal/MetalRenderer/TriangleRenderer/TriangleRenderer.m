//
//  TriangleRenderer.m
//  HelloMetal
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "TriangleRenderer.h"

typedef struct
{
    vector_float4 position;
    vector_float4 color;
} Vertex;

@interface TriangleRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLRenderPipelineState> triangleRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> triangleVertexBuffer;

@end

@implementation TriangleRenderer

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
    
    id<MTLFunction> triangleVertexFunc = [library newFunctionWithName:@"triangle_vertex_main"];
    id<MTLFunction> triangleFragmentFunc = [library newFunctionWithName:@"triangle_fragment_main"];
    
    MTLRenderPipelineDescriptor *trianglePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    trianglePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    trianglePipelineDescriptor.vertexFunction = triangleVertexFunc;
    trianglePipelineDescriptor.fragmentFunction = triangleFragmentFunc;
    
    _triangleRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:trianglePipelineDescriptor
                                                                               error:&error];
    
    if (!_triangleRenderPipeline)
    {
        NSLog(@"Error occurred when creating line render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    static const Vertex triangleVertices[] =
    {
        { .position = { -0.5, -0.5, 0, 1 }, .color = { 1, 0, 0, 1 } },
        { .position = { -0.5,  0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
        { .position = {  0.5, -0.5, 0, 1 }, .color = { 0, 0, 1, 1 } },
        { .position = {  0.5, -0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
        { .position = { -0.5,  0.5, 0, 1 }, .color = { 1, 0, 1, 1 } },
        { .position = {  0.5,  0.5, 0, 1 }, .color = { 1, 0, 1, 1 } },
    };
    _triangleVertexBuffer = [_metalContext.device newBufferWithBytes:triangleVertices
                                                          length:sizeof(triangleVertices)
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
        commandBuffer.label = @"TriangleRendererCommand";
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:_triangleRenderPipeline];
        [commandEncoder setVertexBuffer: _triangleVertexBuffer offset:0 atIndex:0];
        [commandEncoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart: 0 vertexCount: 6];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end
