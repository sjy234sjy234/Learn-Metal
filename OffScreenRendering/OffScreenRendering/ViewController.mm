//
//  ViewController.m
//  OffScreenRendering
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"
#import "MathUtilities.hpp"
#import "OrbitControl.hpp"

#import "MetalContext.h"
#import "MetalView.h"
#import "FrameRenderer.h"

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
@property (nonatomic, strong) MetalView *myMetalView;
@property (nonatomic, strong) FrameRenderer *frameRenderer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalContext = [MetalContext shareMetalContext];
    
    self.myMetalView=[[MetalView alloc] initWithFrame: self.view.frame];
    self.myMetalView.backgroundColor = [UIColor grayColor];
    self.myMetalView.delegate = self;
    [self.view addSubview:self.myMetalView];
    
    [self buildFrameRenderer];
    [self redraw];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)buildFrameRenderer
{
    const float cubeVertices[] =
    {
        -100,  100,  100,
        -100, -100,  100,
        100, -100,  100,
        100,  100,  100,
        -100,  100, -100,
        -100, -100, -100,
        100, -100, -100,
        100,  100, -100,
    };
    const uint32_t cubeIndices[]=
    {
        3, 2, 6, 6, 7, 3,
        4, 5, 1, 1, 0, 4,
        4, 0, 3, 3, 7, 4,
        1, 5, 6, 6, 2, 1,
        0, 1, 2, 2, 3, 0,
        7, 6, 5, 5, 4, 7
    };
    
    self.frameRenderer = [[FrameRenderer alloc] initWithLayer: _myMetalView.metalLayer andContext: _metalContext];
    [self.frameRenderer setupFrameWithVertex: cubeVertices andIndex: cubeIndices andVertexNum: 8 andFaceNum: 12];
    [self.frameRenderer setThickNess: 0.01];
    
    //projection matrix
    simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    const CGSize drawableSize = self.myMetalView.metalLayer.drawableSize ;
    const float aspect = drawableSize.width / drawableSize.height;
    const float fov = (56.56 * M_PI) / 180.0;
    const float near = 100;
    const float far = 30000;
    m_proTransform = matrix_float4x4_perspective(aspect, fov, near, far);
    //view matrix
    m_targetPos = {0.0, 0.0, 0.0};
    m_cameraPos = {0.0, 0.0, 500.0};
    m_orbitControl.init(m_targetPos, m_cameraPos);
    m_viewTransform = m_orbitControl.getTransform();
    //model matrix
    m_modelTransform = simd::float4(onesFloat4);
    //mvp matrix
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
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
    
    [self redraw];
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
    
    [self redraw];
}

- (void)redraw
{
    //mvp matrix
    m_viewTransform = m_orbitControl.getTransform();
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    
    [_frameRenderer renderWithMvpMatrix: mvpTransform];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
