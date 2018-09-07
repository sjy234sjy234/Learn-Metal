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
#import "VideoRenderer.h"
#import "DepthRenderer.h"

#import "FrontCamera.h"

@interface ViewController () <FrontCameraDelegate, MetalViewDelegate>
{
    BOOL m_isStreaming;
    uint32_t m_streamFrameIndex;
}

@property (nonatomic, strong) MetalContext *metalContext;
@property (nonatomic, strong) MetalView *mainMetalView0;
@property (nonatomic, strong) MetalView *mainMetalView1;
@property (nonatomic, strong) VideoRenderer *videoRenderer;
@property (nonatomic, strong) DepthRenderer *depthRenderer;

@property (nonatomic, strong) FrontCamera *trueDepthCamera;

@property (nonatomic, strong) NSString *documentDirectory;
@property (nonatomic, strong) NSOutputStream *videoOutputStream;
@property (nonatomic, strong) NSString *videoOutputPath;
@property (nonatomic, strong) NSOutputStream *depthOutputStream;
@property (nonatomic, strong) NSString *depthOutputPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self addObserver];
    
    CGRect frameRect = self.view.frame;
    CGRect frameRect0 = CGRectMake(0, 0, frameRect.size.width / 2, frameRect.size.height / 2);
    self.mainMetalView0 = [[MetalView alloc] initWithFrame: frameRect0];
    [self.view addSubview: self.mainMetalView0];
    self.mainMetalView0.delegate = self;
    CGRect frameRect1 = CGRectMake(frameRect.size.width / 2, 0, frameRect.size.width / 2, frameRect.size.height / 2);
    self.mainMetalView1 = [[MetalView alloc] initWithFrame: frameRect1];
    [self.view addSubview: self.mainMetalView1];
    self.mainMetalView1.delegate = self;
    
    self.metalContext = [MetalContext shareMetalContext];

    self.videoRenderer = [[VideoRenderer alloc] initWithLayer: _mainMetalView0.metalLayer andContext: _metalContext];
    self.depthRenderer = [[DepthRenderer alloc] initWithLayer: _mainMetalView1.metalLayer andContext: _metalContext];
    
    self.trueDepthCamera=[[FrontCamera alloc] initWithDepthTag: YES];
    self.trueDepthCamera.delegate=self;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.documentDirectory = [paths objectAtIndex:0];
    self.videoOutputPath=[self.documentDirectory stringByAppendingPathComponent:@"bgra.bin"];
    self.depthOutputPath=[self.documentDirectory stringByAppendingPathComponent:@"depth.bin"];
    [self.stopStreamButton setEnabled: NO];
}

- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)willResignActive
{
    [self.trueDepthCamera stopCapture];
}

- (void)didBecomeActive
{
    [self.trueDepthCamera startCapture];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear: animated];
    [self.trueDepthCamera startCapture];
}

//FrontCameraDelegate
- (void) didOutputVideoBuffer:(CVPixelBufferRef)videoPixelBuffer andDepthBuffer:(CVPixelBufferRef)depthPixelBuffer
{
    if(videoPixelBuffer)
    {
        [_videoRenderer render: videoPixelBuffer];
    }
    if(depthPixelBuffer)
    {
        [_depthRenderer render: depthPixelBuffer];
    }
    if(m_isStreaming)
    {
        [self streamDepth:depthPixelBuffer andVideo:videoPixelBuffer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onStartStream:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.startStreamButton setEnabled: NO];
        [self.stopStreamButton setEnabled: YES];
    });
    
    NSLog(@"onStartStream");
    self.videoOutputStream=[[NSOutputStream alloc] initToFileAtPath:self.videoOutputPath append:NO];
    [self.videoOutputStream setDelegate:self];
    [self.videoOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.videoOutputStream open];
    
    self.depthOutputStream=[[NSOutputStream alloc] initToFileAtPath:self.depthOutputPath append:NO];
    [self.depthOutputStream setDelegate:self];
    [self.depthOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.depthOutputStream open];
    
    m_streamFrameIndex=0;
    m_isStreaming=YES;
}

- (IBAction)onStopStream:(id)sender {
    NSLog(@"onStopStream");
    NSLog(@"total Frame: %d", m_streamFrameIndex);
    m_isStreaming = NO;
    [self.videoOutputStream close];
    [self.depthOutputStream close];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.startStreamButton setEnabled: YES];
        [self.stopStreamButton setEnabled: NO];
    });
}

-(void)streamDepth: (CVPixelBufferRef) depthPixelBuffer andVideo: (CVPixelBufferRef) videoPixelBuffer{
    
    if(!depthPixelBuffer||!videoPixelBuffer){
        return;
    }
    
    CVPixelBufferLockBaseAddress(videoPixelBuffer, 0);
    CVPixelBufferLockBaseAddress(depthPixelBuffer, 0);
    
    // mark nan depth as -1.0
    size_t width=CVPixelBufferGetWidth(videoPixelBuffer);
    size_t height=CVPixelBufferGetHeight(videoPixelBuffer);
    void *depthBaseAddress=CVPixelBufferGetBaseAddress(depthPixelBuffer);
    float16_t *depthFloat16Buffer = (float16_t *)(depthBaseAddress);
    for(int j=0;j<height;++j){
        for(int i=0;i<width;++i){
            float16_t disparity=depthFloat16Buffer[width*j+i];
            if(!disparity==disparity){
                depthFloat16Buffer[width*j+i]=-1.0;
            }
        }
    }
    
    //streaming
    void *videoBaseAddress=CVPixelBufferGetBaseAddress(videoPixelBuffer);
    uint8_t *videoInt8Buffer=(uint8_t *)(videoBaseAddress);
    [self.videoOutputStream write:videoInt8Buffer maxLength:4*width*height];
    
    /* tansform disparity to float32 depth
    float32_t *videoFloat32Buffer = (float32_t *)(videoBaseAddress);
    for(int j=0;j<height;++j){
        for(int i=0;i<width;++i){
            videoFloat32Buffer[width*j+i]=1/depthFloat16Buffer[width*j+i];
        }
    }
    [self.depthOutputStream write:videoInt8Buffer maxLength:4*width*height];
     */
    
    uint8_t *depthInt8Buffer = (uint8_t *)(depthBaseAddress);
    [self.depthOutputStream write: depthInt8Buffer maxLength: 2 * width * height];
    
    m_streamFrameIndex++;
    NSLog(@"streaming frameIndex: %d", m_streamFrameIndex);
    CVPixelBufferUnlockBaseAddress(videoPixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(depthPixelBuffer, 0);
    
    if(m_streamFrameIndex > 255)
    {
        [self onStopStream: nil];
    }
}

@end
