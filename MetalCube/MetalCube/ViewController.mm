//
//  ViewController.m
//  MetalCube
//
//  Created by  沈江洋 on 2018/8/27.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"
#import "MathUtilities.hpp"
#import "OrbitControl.hpp"

typedef struct
{
    simd::float4 position;
    simd::float4 color;
} Vertex;

@interface ViewController () <MetalViewDelegate>
{
    simd::float4x4 m_proTransform;
    simd::float4x4 m_viewTransform;
    simd::float4x4 m_modelTransform;
    simd::float3 m_cameraPos;
    simd::float3 m_targetPos;
    OrbitControl m_orbitControl;
}

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic) MetalView *myMetalView;

@property (nonatomic) MeshRenderer *meshRenderer;

@property (nonatomic, strong) id<MTLBuffer> cubeVertexBuffer;

@property (nonatomic, strong) id<MTLBuffer> cubeIndexBuffer;

@property (nonatomic, strong) id<MTLBuffer> mvpTransformBuffer;

@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalContext = [MetalContext shareMetalContext];
    
    self.myMetalView=[[MetalView alloc] init];
    self.myMetalView.frame=CGRectMake(10, 100, 300, 400);
    self.myMetalView.backgroundColor = [UIColor grayColor];
    self.myMetalView.delegate = self;
    [self.view addSubview:self.myMetalView];
    
    [self buildResources];
    
    self.meshRenderer = [[MeshRenderer alloc] initWithLayer: self.myMetalView.metalLayer andContext: _metalContext];
    [self.meshRenderer drawMesh:_cubeVertexBuffer withIndexBuffer:_cubeIndexBuffer withMvpMatrix:_mvpTransformBuffer];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)buildResources
{
    static const Vertex cubeVertices[] =
    {
        { .position = { -100,  100,  100, 1 }, .color = { 0, 1, 1, 1 } },
        { .position = { -100, -100,  100, 1 }, .color = { 0, 0, 1, 1 } },
        { .position = {  100, -100,  100, 1 }, .color = { 1, 0, 1, 1 } },
        { .position = {  100,  100,  100, 1 }, .color = { 1, 1, 1, 1 } },
        { .position = { -100,  100, -100, 1 }, .color = { 0, 1, 0, 1 } },
        { .position = { -100, -100, -100, 1 }, .color = { 0, 0, 0, 1 } },
        { .position = {  100, -100, -100, 1 }, .color = { 1, 0, 0, 1 } },
        { .position = {  100,  100, -100, 1 }, .color = { 1, 1, 0, 1 } }
    };
    _cubeVertexBuffer = [_metalContext.device newBufferWithBytes:cubeVertices
                                                          length:sizeof(cubeVertices)
                                                         options:MTLResourceOptionCPUCacheModeDefault];
    m_targetPos = {0.0, 0.0, 0.0};
    m_cameraPos = {0.0, 0.0, 500.0};
    m_orbitControl.init(m_targetPos, m_cameraPos);
    
    static const uint32_t cubeIndices[]=
    {
        3, 2, 6, 6, 7, 3,
        4, 5, 1, 1, 0, 4,
        4, 0, 3, 3, 7, 4,
        1, 5, 6, 6, 2, 1,
        0, 1, 2, 2, 3, 0,
        7, 6, 5, 5, 4, 7
    };
    _cubeIndexBuffer=[_metalContext.device newBufferWithBytes:cubeIndices
                                                       length:sizeof(cubeIndices)
                                                      options:MTLResourceOptionCPUCacheModeDefault];
    
    simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    const CGSize drawableSize = self.myMetalView.metalLayer.drawableSize ;
    const float aspect = drawableSize.width / drawableSize.height;
    const float fov = (57.3 * M_PI) / 180.0;
    const float near = 100;
    const float far = 30000;
    const simd::float3 cameraTranslation = { 0, 0, -500 };
    m_proTransform = matrix_float4x4_perspective(aspect, fov, near, far);
    m_viewTransform = m_orbitControl.getTransform();
    m_modelTransform = simd::float4(onesFloat4);
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    
    _mvpTransformBuffer = [_metalContext.device newBufferWithLength:sizeof(simd::float4x4)
                                                            options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
}

//MetalViewDelegate
- (void)onTouchesMoved:(CGPoint)offset
{
    if(offset.x<0)
    {
        m_orbitControl.rotateRight();
    }
    else if(offset.x>0)
    {
        m_orbitControl.rotateLeft();
    }
    if(offset.y<0)
    {
        m_orbitControl.rotateDown();
    }
    else if(offset.y>0)
    {
        m_orbitControl.rotateUp();
    }
    
    m_viewTransform = m_orbitControl.getTransform();
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    [_meshRenderer drawMesh:_cubeVertexBuffer withIndexBuffer:_cubeIndexBuffer withMvpMatrix:_mvpTransformBuffer];
}

//MetalViewDelegate
- (void)onPinch:(BOOL)isZoomOut
{
    if(isZoomOut)
    {
        m_orbitControl.zoomOut();
    }
    else
    {
        m_orbitControl.zoomIn();
    }

    m_viewTransform = m_orbitControl.getTransform();
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    memcpy([_mvpTransformBuffer contents], &mvpTransform, sizeof(mvpTransform));
    [_meshRenderer drawMesh:_cubeVertexBuffer withIndexBuffer:_cubeIndexBuffer withMvpMatrix:_mvpTransformBuffer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
