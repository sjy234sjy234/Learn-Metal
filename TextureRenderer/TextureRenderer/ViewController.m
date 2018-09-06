//
//  ViewController.m
//  TextureRenderer
//
//  Created by  沈江洋 on 2018/9/3.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"

#import "MetalContext.h"
#import "MetalView.h"
#import "TextureRenderer.h"

#import "FrontCamera.h"

@interface ViewController () <FrontCameraDelegate, MetalViewDelegate>

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MetalView *mainMetalView;
@property (nonatomic, strong) TextureRenderer *textureRenderer;

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
    
    self.textureRenderer = [[TextureRenderer alloc] initWithLayer: self.mainMetalView.metalLayer andContext: _metalContext];
    
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
        [self.textureRenderer draw: [_metalContext textureFromPixelBuffer: videoPixelBuffer]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
