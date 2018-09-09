//
//  FrameRendererEncoder.mm
//  MeshFrame
//
//  Created by  沈江洋 on 2018/8/29.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrameRendererEncoder.h"

@interface FrameRendererEncoder ()
{
    MTLClearColor m_clearColor;
    double m_clearDepth;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> lineRenderPipeline;
@property (nonatomic, strong) id<MTLRenderPipelineState> meshRenderPipeline;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> meshIndexBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineIndexBuffer;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;
@property (nonatomic, strong) id<MTLBuffer> whRatioBuffer;
@property (nonatomic, strong) id<MTLBuffer> thicknessBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineColorBuffer;

@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation FrameRendererEncoder

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
    
    id<MTLFunction> lineVertexFunc = [library newFunctionWithName:@"frameLine_vertex_main"];
    id<MTLFunction> lineFragmentFunc = [library newFunctionWithName:@"frameLine_fragment_main"];
    
    MTLRenderPipelineDescriptor *linePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    linePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    linePipelineDescriptor.vertexFunction = lineVertexFunc;
    linePipelineDescriptor.fragmentFunction = lineFragmentFunc;
    linePipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    
    _lineRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:linePipelineDescriptor
                                                                               error:&error];
    
    if (!_lineRenderPipeline)
    {
        NSLog(@"Error occurred when creating line render pipeline state: %@", error);
    }
    
    id<MTLFunction> meshVertexFunc = [library newFunctionWithName:@"frameMesh_vertex_main"];
    id<MTLFunction> meshFragmentFunc = [library newFunctionWithName:@"frameMesh_fragment_main"];
    
    MTLRenderPipelineDescriptor *meshPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    meshPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    meshPipelineDescriptor.colorAttachments[0].blendingEnabled = YES; //启用混合
    meshPipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    meshPipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    meshPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    meshPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    meshPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    meshPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    meshPipelineDescriptor.vertexFunction = meshVertexFunc;
    meshPipelineDescriptor.fragmentFunction = meshFragmentFunc;
    meshPipelineDescriptor.depthAttachmentPixelFormat=MTLPixelFormatDepth32Float;
    
    
    
    _meshRenderPipeline = [_metalContext.device newRenderPipelineStateWithDescriptor:meshPipelineDescriptor
                                                                               error:&error];
    
    if (!_meshRenderPipeline)
    {
        NSLog(@"Error occurred when creating mesh render pipeline state: %@", error);
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

- (void)setupFrameWithVertex: (const float *) vertices
                    andIndex: (const uint32_t *)indices
                andVertexNum: (int) vertexNum
                  andFaceNum: (int) faceNum
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

- (void)encodeToCommandBuffer: (id<MTLCommandBuffer>) commandBuffer
              dstColorTexture: (id<MTLTexture>) colorTexture
              dstDepthTexture: (id<MTLTexture>) depthTexture
                   clearColor: (const BOOL) isClearColor
                   clearDepth: (const BOOL) isClearDepth
                    mvpMatrix: (simd::float4x4)mvpTransform
{
    if(!_vertexBuffer || !_meshIndexBuffer || !_lineIndexBuffer)
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
        passDescriptor.depthAttachment.texture = depthTexture;
        passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        if(isClearDepth)
        {
            passDescriptor.depthAttachment.clearDepth = m_clearDepth;
            passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        }

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
        
        [commandEncoder setRenderPipelineState:_meshRenderPipeline];
        [commandEncoder setDepthStencilState:_depthState];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder setVertexBuffer: _vertexBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex:1];
        [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                   indexCount:[_meshIndexBuffer length] / sizeof(uint32_t)
                                    indexType:MTLIndexTypeUInt32
                                  indexBuffer:_meshIndexBuffer
                            indexBufferOffset:0];
        
        [commandEncoder setRenderPipelineState:_lineRenderPipeline];
        [commandEncoder setVertexBuffer: _vertexBuffer offset:0 atIndex:0];
        [commandEncoder setVertexBuffer: _lineIndexBuffer offset:0 atIndex:1];
        [commandEncoder setVertexBuffer: _mvpTransformBuffer offset:0 atIndex:2];
        [commandEncoder setVertexBuffer: _whRatioBuffer offset:0 atIndex:3];
        [commandEncoder setVertexBuffer: _thicknessBuffer offset:0 atIndex:4];
        [commandEncoder setVertexBuffer: _lineColorBuffer offset:0 atIndex:5];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount: _lineIndexBuffer.length / (2 * sizeof(uint32_t))];
        [commandEncoder endEncoding];
    }
}

@end
