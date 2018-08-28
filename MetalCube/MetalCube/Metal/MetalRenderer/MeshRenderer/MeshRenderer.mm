//
//  MeshRenderer.m
//  MetalCube
//
//  Created by  沈江洋 on 2018/8/28.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "MeshRenderer.h"
#import "MathUtilities.hpp"

typedef struct
{
    simd::float4 position;
    simd::float4 color;
} Vertex;

@interface MeshRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> meshRenderPipeline;

@end

@implementation MeshRenderer

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
    
    id<MTLFunction> meshVertexFunc = [library newFunctionWithName:@"mesh_vertex_main"];
    id<MTLFunction> meshFragmentFunc = [library newFunctionWithName:@"mesh_fragment_main"];
    
    MTLRenderPipelineDescriptor *meshPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    meshPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    meshPipelineDescriptor.vertexFunction = meshVertexFunc;
    meshPipelineDescriptor.fragmentFunction = meshFragmentFunc;
    
    _meshRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:meshPipelineDescriptor
                                                                               error:&error];
    
    if (!_meshRenderPipeline)
    {
        NSLog(@"Error occurred when creating mesh render pipeline state: %@", error);
    }
}

- (void)buildResources
{
    
}

- (void)drawMesh: (id<MTLBuffer>)vertexBuffer withIndexBuffer: (id<MTLBuffer>)indexBuffer withMvpMatrix:  (id<MTLBuffer>)mvpTransform
{
    if(!vertexBuffer || !indexBuffer || !mvpTransform)
    {
        NSLog(@"invalid buffer");
        return ;
    }
    
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
        commandBuffer.label = @"MeshRendererCommand";
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        [commandEncoder setRenderPipelineState:_meshRenderPipeline];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder setVertexBuffer: vertexBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer: mvpTransform offset:0 atIndex:1];
        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                   indexCount:[indexBuffer length] / sizeof(uint32_t)
                                    indexType:MTLIndexTypeUInt32
                                  indexBuffer:indexBuffer
                            indexBufferOffset:0];
        
        
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end
