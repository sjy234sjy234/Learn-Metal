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
#import "TextureRenderer.h"

#import "FrontCamera.h"

@interface ViewController () <FrontCameraDelegate, MetalViewDelegate>

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MetalView *mainMetalView;
@property (nonatomic, strong) TextureRenderer *textureRenderer;
@property (nonatomic, strong) MPSUnaryImageKernel *gaussianBlurKernel;
@property (nonatomic, strong) id<MTLTexture> outTexture;

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
    
    self.metalContext = [MetalContext newContext];
    
    self.textureRenderer = [[TextureRenderer alloc] initWithContext: _metalContext];
    self.gaussianBlurKernel = [[MPSImageGaussianBlur alloc] initWithDevice: _metalContext.device sigma: 10.0];
    
    self.frontCamera=[[FrontCamera alloc] initWithDepthTag:NO];
    self.frontCamera.delegate=self;
    
    [self buildOutTexture];
}

- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)buildOutTexture
{
    size_t width, height;
    [self.frontCamera getFrameWidth: &width andFrameHeight: &height];
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.usage = MTLTextureUsageShaderRead|MTLTextureUsageShaderWrite|MTLTextureUsageRenderTarget;
    self.outTexture = [_metalContext.device newTextureWithDescriptor:textureDescriptor];
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
        //pixel buffer to MTLTexture
        id<MTLTexture> inTexture = [_metalContext textureFromPixelBuffer: videoPixelBuffer];
        
        //new commander buffer
        id<MTLCommandBuffer> commandBuffer = [_metalContext.commandQueue commandBuffer];
        commandBuffer.label = @"GaussianBlurMPSCommand";
        
        //encode gaussion process
        [_gaussianBlurKernel encodeToCommandBuffer: commandBuffer sourceTexture: inTexture destinationTexture: _outTexture];
        
        //encode drawable render process
        id<CAMetalDrawable> drawable = [self.mainMetalView.metalLayer nextDrawable];
        [_textureRenderer encodeToCommandBuffer: commandBuffer sourceTexture: _outTexture destinationDrawable: drawable];
        
        //commit commander buffer
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
