//
//  ViewController.m
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"
#import "MathUtilities.hpp"
#import "OrbitControl.hpp"

#import "MetalContext.h"
#import "MetalView.h"
#import "FrameGlowingRenderer.h"
#import "FrameTestRenderer.h"

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

@property (nonatomic, strong) MetalView *testMetalView1;
@property (nonatomic, strong) MetalView *testMetalView2;
@property (nonatomic, strong) MetalView *testMetalView3;

@property (nonatomic, strong) FrameGlowingRenderer *frameGlowingRenderer;

@property (nonatomic, strong) FrameTestRenderer *frameTestRenderer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalContext = [MetalContext shareMetalContext];
    
    CGRect frameRect = self.view.frame;
    
    self.myMetalView = [[MetalView alloc] initWithFrame: CGRectMake(0, 0, frameRect.size.width / 2 - 2, frameRect.size.height / 2 - 2)];
//     self.myMetalView = [[MetalView alloc] initWithFrame: frameRect];
    self.myMetalView.backgroundColor = [UIColor grayColor];
    self.myMetalView.delegate = self;
    [self.view addSubview: self.myMetalView];
    
    self.testMetalView1 = [[MetalView alloc] initWithFrame: CGRectMake(frameRect.size.width / 2, 0, frameRect.size.width / 2 - 2, frameRect.size.height / 2 - 2)];
    self.testMetalView1.backgroundColor = [UIColor grayColor];
    self.testMetalView1.delegate = self;
    [self.view addSubview: self.testMetalView1];
    self.testMetalView2 = [[MetalView alloc] initWithFrame: CGRectMake(0, frameRect.size.height / 2, frameRect.size.width / 2 - 2, frameRect.size.height / 2 - 2)];
    self.testMetalView2.backgroundColor = [UIColor grayColor];
    self.testMetalView2.delegate = self;
    [self.view addSubview: self.testMetalView2];
    self.testMetalView3 = [[MetalView alloc] initWithFrame: CGRectMake(frameRect.size.width / 2, frameRect.size.height /2 , frameRect.size.width / 2 - 2, frameRect.size.height / 2 - 2)];
    self.testMetalView3.backgroundColor = [UIColor grayColor];
    self.testMetalView3.delegate = self;
    [self.view addSubview: self.testMetalView3];
    
    [self buildFrameRenderer];

    [self redraw];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)buildFrameRenderer
{
    /*
     //test for quadrangle mesh frame
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
        3, 2, 6, 7,
        4, 5, 1, 0,
        4, 0, 3, 7,
        1, 5, 6, 2,
        0, 1, 2, 3,
        7, 6, 5, 4
    };
    
    //frame test renderer rendering middle result
    self.frameTestRenderer = [[FrameTestRenderer alloc] initWithLayer1: _testMetalView1.metalLayer andLayer2: _testMetalView2.metalLayer andLayer3: _testMetalView3.metalLayer  andContext: _metalContext andBlurSigma: 3.0 andBlendAlpha: 0.5];
    [self.frameTestRenderer setupFrameWithQuadrangleVertex: cubeVertices andIndex: cubeIndices andVertexNum: 8 andFaceNum: 6];
    [self.frameTestRenderer setThickNess: 0.002];
    [self.frameTestRenderer setBackColor: {24.0 / 255, 31.0 / 255, 50.0 / 255, 1}];
    [self.frameTestRenderer setLineColor: {36.0 / 255, 210.0 / 255, 214.0 / 255, 1.0}];
    
    //frame glowing renderer
    self.frameGlowingRenderer = [[FrameGlowingRenderer alloc] initWithLayer: _myMetalView.metalLayer andContext: _metalContext andBlurSigma: 3.0 andBlendAlpha: 0.5];
    [self.frameGlowingRenderer setupFrameWithQuadrangleVertex: cubeVertices andIndex: cubeIndices andVertexNum: 8 andFaceNum: 6];
    [self.frameGlowingRenderer setThickNess: 0.002];
    [self.frameGlowingRenderer setBackColor: {24.0 / 255, 31.0 / 255, 50.0 / 255, 1}];
    [self.frameGlowingRenderer setLineColor: {36.0 / 255, 210.0 / 255, 214.0 / 255, 1.0}];
    
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
    m_cameraPos = {0.0, 0.0, 800.0};
    m_orbitControl.init(m_targetPos, m_cameraPos);
    m_viewTransform = m_orbitControl.getTransform();
    //model matrix
    m_modelTransform = simd::float4(onesFloat4);
    //mvp matrix
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    */
    
     //load asset and parse vertex and index
     NSString *resourcepath = [[NSBundle mainBundle] resourcePath];
     NSString *mesh_path = [resourcepath stringByAppendingString:@"/sjy.bin"];
     const char* mesh_path_c_str = [mesh_path UTF8String];
     std::ifstream mesh_fin(mesh_path_c_str);
     int nvb =  [self readInt: mesh_fin];
     int nfb = [self readInt: mesh_fin];
     int binSize=nvb*3*4+nfb*3*4;
     char *binBuffer = new char[binSize];
     mesh_fin.read(binBuffer, binSize);
     float* vertexBase=(float *)binBuffer;
     uint32_t* indexBase=(uint32_t *)(binBuffer + 3 * nvb * 4);
     float xMin, xMax;
     float yMin, yMax;
     float zMin, zMax;
     xMin = yMin = zMin = 1000000;
     xMax = yMax = zMax = -1000000;
     for(int i = 0; i < nvb; ++i)
     {
     xMin = min(xMin, vertexBase[3 * i]);
     xMax = max(xMax, vertexBase[3 * i]);
     yMin = min(yMin, vertexBase[3 * i + 1]);
     yMax = max(yMax, vertexBase[3 * i + 1]);
     zMin = min(zMin, vertexBase[3 * i + 2]);
     zMax = max(zMax, vertexBase[3 * i + 2]);
     }
    
    //frame test renderer rendering middle result
    self.frameTestRenderer = [[FrameTestRenderer alloc] initWithLayer1: _testMetalView1.metalLayer andLayer2: _testMetalView2.metalLayer andLayer3: _testMetalView3.metalLayer  andContext: _metalContext andBlurSigma: 3.0 andBlendAlpha: 0.5];
    [self.frameTestRenderer setupFrameWithVertex: vertexBase andIndex: indexBase andVertexNum: nvb andFaceNum: nfb];
    [self.frameTestRenderer setThickNess: 0.002];
    [self.frameTestRenderer setBackColor: {24.0 / 255, 31.0 / 255, 50.0 / 255, 1}];
    [self.frameTestRenderer setLineColor: {36.0 / 255, 210.0 / 255, 214.0 / 255, 1.0}];
    
     //frame glowing renderer
    self.frameGlowingRenderer = [[FrameGlowingRenderer alloc] initWithLayer: _myMetalView.metalLayer andContext: _metalContext andBlurSigma: 3.0 andBlendAlpha: 0.5];
    [self.frameGlowingRenderer setupFrameWithVertex: vertexBase andIndex: indexBase andVertexNum: nvb andFaceNum: nfb];
    [self.frameGlowingRenderer setThickNess: 0.002];
    [self.frameGlowingRenderer setBackColor: {24.0 / 255, 31.0 / 255, 50.0 / 255, 1}];
    [self.frameGlowingRenderer setLineColor: {36.0 / 255, 210.0 / 255, 214.0 / 255, 1.0}];
     delete[] binBuffer;
    
     //projection matrix
     simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
     const CGSize drawableSize = self.myMetalView.metalLayer.drawableSize ;
     const float aspect = drawableSize.width / drawableSize.height;
     const float fov = (56.56 * M_PI) / 180.0;
     const float near = 10;
     const float far = 30000;
     m_proTransform = matrix_float4x4_perspective(aspect, fov, near, far);
     //view matrix
     m_targetPos = {(xMin+xMax)/2, (yMin+yMax)/2, (zMin+zMax)/2};
     m_cameraPos = {(xMin+xMax)/2, (yMin+yMax)/2, (zMin+zMax)/2 + 300};
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
    
    //render
    [self.frameGlowingRenderer renderWithMvpMatrix: mvpTransform];
    
    [self.frameTestRenderer renderWithMvpMatrix: mvpTransform];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int) readInt:(std::ifstream&) fin {
    char buffer[4];
    fin.read(buffer, 4);
    int c0 = int(buffer[0] & 0xff); // to unsigned
    int c1 = int(buffer[1] & 0xff);
    int c2 = int(buffer[2] & 0xff);
    int c3 = int(buffer[3] & 0xff);
    return c0 + (c1<<8) + (c2<<16) + (c3<<24);
}

@end
