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
    /*
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
    self.frameRenderer = [[FrameRenderer alloc] initWithLayer: self.myMetalView.metalLayer andContext: _metalContext];
    [self.frameRenderer setupFrameWithVertex:cubeVertices andIndex: cubeIndices andVertexNum: 8 andFaceNum: 12];
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
    //frame renderer
    self.frameRenderer = [[FrameRenderer alloc] initWithLayer: self.myMetalView.metalLayer andContext: _metalContext];
    [self.frameRenderer setupFrameWithVertex: vertexBase andIndex: indexBase andVertexNum: nvb andFaceNum: nfb];
    delete[] binBuffer;
    //projection matrix
    simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    const CGSize drawableSize = self.myMetalView.metalLayer.drawableSize ;
    const float aspect = drawableSize.width / drawableSize.height;
    const float fov = (56.56 * M_PI) / 180.0;
    const float near = 100;
    const float far = 30000;
    m_proTransform = matrix_float4x4_perspective(aspect, fov, near, far);
    //view matrix
    m_targetPos = {(xMin+xMax)/2, (yMin+yMax)/2, (zMin+zMax)/2};
    m_cameraPos = {(xMin+xMax)/2, (yMin+yMax)/2, (zMin+zMax)/2 + 400};
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
    m_viewTransform = m_orbitControl.getTransform();
    const simd::float4x4 mvpTransform = m_proTransform * m_viewTransform * m_modelTransform;
    [_frameRenderer drawWithMvpMatrix: mvpTransform];
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
