//
//  ViewController.m
//  MetalPoint
//
//  Created by  沈江洋 on 2018/9/8.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"
#import "MetalContext.h"
#import "MetalView.h"
#import "PointRenderer.h"

@interface ViewController () <MetalViewDelegate>

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic, strong) MetalView *myMetalView;

@property (nonatomic, strong) PointRenderer *pointRenderer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalContext = [MetalContext shareMetalContext];
    
    self.myMetalView=[[MetalView alloc] initWithFrame: self.view.frame];
    self.myMetalView.backgroundColor = [UIColor grayColor];
    self.myMetalView.delegate = self;
    [self.view addSubview:self.myMetalView];
    
    self.pointRenderer = [[PointRenderer alloc] initWithLayer: self.myMetalView.metalLayer andContext: _metalContext];
    [self redraw];
    
    // Do any additional setup after loading the view, typically from a nib.
}

//MetalViewDelegate
- (void)onPinch:(BOOL)isZoomOut
{
    if(isZoomOut)
    {
        NSLog(@"zoom out");
    }
    else
    {
        NSLog(@"zoom in");
    }
}

- (void)redraw
{
    const int pNum = 4;
    const float points[] = {
        -0.5, -0.5, 0,
        -0.5,  0.5, 0,
        0.5, -0.5, 0,
        0.5,  0.5, 0,
    };
    
    const simd::float4 onesFloat4={1.0,1.0,1.0,1.0};
    const simd::float4x4 mvpTransform = simd::float4(onesFloat4);
    
    [_pointRenderer setBackColor: {0.0, 1.0, 1.0, 1.0}];
    [_pointRenderer setPointSize: 50];
    [_pointRenderer setPointColor: {1.0, 0.0, 1.0, 1.0}];
    [_pointRenderer renderPoints: points pointNum: pNum mvpMatrix: mvpTransform];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
