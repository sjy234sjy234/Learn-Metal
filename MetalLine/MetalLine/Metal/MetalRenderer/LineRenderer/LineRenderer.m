//
//  LineRenderer.m
//  MetalLine
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "LineRenderer.h"

typedef struct
{
    vector_float4 position;
    vector_float4 color;
} Vertex;

@interface LineRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) id<MTLRenderPipelineState> lineRenderPipeline;
@property (nonatomic, strong) id<MTLBuffer> lineVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineIndexBuffer;

@end

@implementation LineRenderer

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
    
    id<MTLFunction> lineVertexFunc = [library newFunctionWithName:@"line_vertex_main"];
    id<MTLFunction> lineFragmentFunc = [library newFunctionWithName:@"line_fragment_main"];
    
    MTLRenderPipelineDescriptor *linePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    linePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    linePipelineDescriptor.vertexFunction = lineVertexFunc;
    linePipelineDescriptor.fragmentFunction = lineFragmentFunc;
    
    _lineRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:linePipelineDescriptor
                                                                                error:&error];
    
    if (!_lineRenderPipeline)
    {
        NSLog(@"Error occurred when creating line render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    static const Vertex lineVertices[] =
    {
        { .position = {  -0.5,  -0.5, 0, 1 }, .color = { 1, 0, 0, 1 } },
        { .position = { -0.5, 0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
        { .position = {  0.5, -0.5, 0, 1 }, .color = { 0, 0, 1, 1 } },
        { .position = {  0.5, 0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
    };
    _lineVertexBuffer = [_metalContext.device newBufferWithBytes:lineVertices
                                                           length:sizeof(lineVertices)
                                                          options:MTLResourceOptionCPUCacheModeDefault];
    
    static const uint lineIndices[]=
    {
        0, 1,
        1, 2,
        2, 3,
        0, 3
    };
    _lineIndexBuffer=[_metalContext.device newBufferWithBytes:lineIndices
                                         length:sizeof(lineIndices)
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
        commandBuffer.label = @"LineRendererCommand";
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:_lineRenderPipeline];
        [commandEncoder setVertexBuffer: _lineVertexBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer:self.lineIndexBuffer offset:0 atIndex:1];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:4];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end

