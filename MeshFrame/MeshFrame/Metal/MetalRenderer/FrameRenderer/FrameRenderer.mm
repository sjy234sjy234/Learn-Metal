//
//  FrameRenderer.m
//  MeshFrame
//
//  Created by  沈江洋 on 2018/8/29.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrameRenderer.h"

@interface FrameRenderer ()
@property (nonatomic, strong) CAMetalLayer *layer;
@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> lineRenderPipeline;
@property (nonatomic, strong) id<MTLRenderPipelineState> meshRenderPipeline;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> meshIndexBuffer;
@property (nonatomic, strong) id<MTLBuffer> lineIndexBuffer;
@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;
@property (nonatomic, strong) id<MTLBuffer> whRatioBuffer;
@property (nonatomic, strong) id<MTLBuffer> thicknessBuffer;

@property (nonatomic, strong) id<MTLTexture> depthTexture;
@property (nonatomic, strong) id<MTLDepthStencilState> depthState;

@end

@implementation FrameRenderer

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
    
    CGSize drawableSize = _layer.drawableSize;
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                          width:drawableSize.width
                                                                                         height:drawableSize.height
                                                                                      mipmapped:NO];
    
    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthWriteEnabled = YES;
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    _depthState = [_metalContext.device newDepthStencilStateWithDescriptor:depthDescriptor];
    descriptor.usage = MTLTextureUsageRenderTarget;
    _depthTexture = [_metalContext.device newTextureWithDescriptor:descriptor];
}

- (void)buildResources
{
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    
    _whRatioBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
    
    const float thickness = 0.001;
    _thicknessBuffer = [_metalContext.device newBufferWithLength:sizeof(float)
                                                                          options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_thicknessBuffer contents], &thickness, sizeof(float));
    
}

- (void)setThickNess: (float) thickness
{
    thickness = thickness < 0.0 ? 0.0 : thickness;
    thickness = thickness > 1.0 ? 1.0 : thickness;
    memcpy([_thicknessBuffer contents], &thickness, sizeof(float));
}

- (void)setupFrameWithVertex: (const float *) vertices andIndex: (const uint32_t *)indices andVertexNum: (int) vertexNum andFaceNum: (int) faceNum
{
    //vertex
    _vertexBuffer = [_metalContext.device newBufferWithLength: vertexNum * 4 * 4 options:MTLResourceOptionCPUCacheModeDefault];
    void *pointBaseAddress=_vertexBuffer.contents;
    float *floatPointAddress=(float*)pointBaseAddress;
    for(int i = 0; i < vertexNum; ++i)
    {
        floatPointAddress[4 * i] = vertices[3 * i];
        floatPointAddress[4 * i + 1] = vertices[3 * i + 1];
        floatPointAddress[4 * i + 2] = vertices[3 * i + 2];
        floatPointAddress[4 * i + 3] = 1.0;
    }
    //mesh index
    _meshIndexBuffer = [_metalContext.device newBufferWithBytes: indices
                                                         length: faceNum * 3 * 4
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
                                                         length: faceNum * 6 * 4
                                                        options:MTLResourceOptionCPUCacheModeDefault];
    delete[] lineIndices;
}

- (void)drawWithMvpMatrix:  (simd::float4x4)mvpTransform
{
    if(!_vertexBuffer || !_meshIndexBuffer || !_lineIndexBuffer)
    {
        NSLog(@"invalid buffer");
        return ;
    }
    
    float ratio = _layer.drawableSize.width / _layer.drawableSize.height;
    memcpy([_whRatioBuffer contents], &ratio, sizeof(float));
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    
    id<CAMetalDrawable> drawable = [_layer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    if (drawable)
    {
        MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        passDescriptor.colorAttachments[0].texture = framebufferTexture;
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.85, 0.85, 0.85, 1);
        passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        passDescriptor.depthAttachment.texture = _depthTexture;
        passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        passDescriptor.depthAttachment.clearDepth = 1.0;
        
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"FrameRendererCommand";
        
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
        [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount: _lineIndexBuffer.length / (2 * sizeof(uint32_t))];
        [commandEncoder endEncoding];
        
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

@end
