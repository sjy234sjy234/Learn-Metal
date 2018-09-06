//
//  ViewController.m
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"

#import "MetalContext.h"
#import "MetalView.h"
#import "VideoGaussianRenderer.h"

#import "FrontCamera.h"

@interface ViewController () <FrontCameraDelegate, MetalViewDelegate>

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MetalView *mainMetalView;
@property (nonatomic, strong) VideoGaussianRenderer *videoGaussianRenderer;

@property (nonatomic, strong) FrontCamera *frontCamera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self addObserver];
    
    self.mainMetalView = [[MetalView alloc] initWithFrame: self.view.frame];
    [self.view addSubview: self.mainMetalView];
    self.mainMetalView.delegate = self;
    
    self.metalContext = [MetalContext shareMetalContext];

    self.videoGaussianRenderer = [[VideoGaussianRenderer alloc] initWithLayer: _mainMetalView.metalLayer andContext: _metalContext andSigma: 10.0];
    
    self.frontCamera=[[FrontCamera alloc] initWithDepthTag:NO];
    self.frontCamera.delegate=self;
}

- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)willResignActive
{
    [self.frontCamera stopCapture];
}

- (void)didBecomeActive
{
    [self.frontCamera startCapture];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    [self.frontCamera startCapture];
}

//FrontCameraDelegate
- (void)didOutputVideoBuffer:(CVPixelBufferRef)videoPixelBuffer
{
    if(videoPixelBuffer)
    {
        [_videoGaussianRenderer render: videoPixelBuffer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
