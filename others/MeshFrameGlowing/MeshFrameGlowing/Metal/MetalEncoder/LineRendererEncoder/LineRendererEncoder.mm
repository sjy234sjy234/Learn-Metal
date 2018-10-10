//
//  LineRendererEncoder.m
//  MeshFrameGlowing
//
//  Created by 美戴科技 on 2018/10/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "LineRendererEncoder.h"

@interface LineRendererEncoder ()
{
    MTLClearColor m_clearColor;
    double m_clearDepth;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> lineRenderPipeline;

@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;
@property (nonatomic, strong) id<MTLBuffer> whRatioBuffer;
@property (nonatomic, strong) id<MTLBuffer> thicknessBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineColorBuffer;

@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation LineRendererEncoder

- (instancetype)initWithContext: (MetalContext *)context
{
    if ((self = [super init]))
    {
        _metalContext=context;
        [self buildPipelines];
        [self buildResources];
    }
    return self;
}

- (void)buildPipelines
{
    NSError *error = nil;
    id<MTLLibrary> library = _metalContext.library;
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"lineRendererEncoder_vertex_main"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"lineRendererEncoder_fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    pipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    
    _lineRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                               error:&error];
    
    if (!_lineRenderPipeline)
    {
        NSLog(@"Error occurred when creating line render encoder pipeline state: %@", error);
    }
    
    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthWriteEnabled = YES;
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    _depthState = [_metalContext.device newDepthStencilStateWithDescriptor:depthDescriptor];
}

- (void)buildResources
{
    m_clearColor = {1.0, 1.0, 1.0, 1.0};
    m_clearDepth = 1.0;
    
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    
    _whRatioBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                       options:MTLResourceOptionCPUCacheModeDefault];
    const float thickness = 0.001;
    _thicknessBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_thicknessBuffer contents], &thickness, sizeof(float));
    
    simd::float4 color = {1.0, 0.0, 1.0, 1.0};
    _lineColorBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_lineColorBuffer contents], &color, sizeof(simd::float4));
}

- (void)setClearColor:(const MTLClearColor) color
{
    m_clearColor = color;
}

- (void)setClearDepth:(const double) depth
{
    m_clearDepth = depth;
}

- (void)setThickNess: (float) thickness
{
    thickness = thickness < 0.0 ? 0.0 : thickness;
    thickness = thickness > 1.0 ? 1.0 : thickness;
    memcpy([_thicknessBuffer contents], &thickness, sizeof(float));
}

- (void)setLineColor: (const simd::float4) color
{
    memcpy([_lineColorBuffer contents], &color, sizeof(simd::float4));
}

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer
              dstColorTexture: (id<MTLTexture>) colorTexture
              dstDepthTexture: (id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                  pointBuffer: (const id<MTLBuffer>) pointBuffer
                  indexBuffer: (const id<MTLBuffer>) indexBuffer
                    mvpMatrix: (simd::float4x4)mvpTransform
{
    if(!pointBuffer || !indexBuffer)
    {
        NSLog(@"invalid buffer");
        return ;
    }
    if(!colorTexture || !depthTexture)
    {
        NSLog(@"invalid texture");
        return ;
    }
    
    float ratio = (float) colorTexture.width / colorTexture.height;
    memcpy([_whRatioBuffer contents], &ratio, sizeof(float));
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = colorTexture;
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        if(isClearColor)
        {
            passDescriptor.colorAttachments[0].clearColor = m_clearColor;
            passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        }
        else
        {
            passDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        }
        passDescriptor.depthAttachment.texture = depthTexture;
        passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        if(isClearDepth)
        {
            passDescriptor.depthAttachment.clearDepth = m_clearDepth;
            passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        }
        else
        {
            passDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
        }
        
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        //        [commandEncoder setRenderPipelineState:_meshRenderPipeline];
        
        //        [commandEncoder setVertexBuffer: _vertexBuffer offset:0 atIndex:0];
        //        [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex:1];
        //        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
        //                                   indexCount:[_meshIndexBuffer length] / sizeof(uint32_t)
        //                                    indexType:MTLIndexTypeUInt32
        //                                  indexBuffer:_meshIndexBuffer
        //                            indexBufferOffset:0];
        
        [commandEncoder setDepthStencilState:_depthState];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder setRenderPipelineState:_lineRenderPipeline];
        [commandEncoder setVertexBuffer: pointBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer: indexBuffer offset:0 atIndex:1];
        [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex:2];
        [commandEncoder setVertexBuffer: _whRatioBuffer offset:0 atIndex:3];
        [commandEncoder setVertexBuffer: _thicknessBuffer offset:0 atIndex:4];
        [commandEncoder setFragmentBuffer: _lineColorBuffer offset: 0 atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount: indexBuffer.length / (2 * sizeof(uint32_t))];
        [commandEncoder endEncoding];
    }
}

@end
