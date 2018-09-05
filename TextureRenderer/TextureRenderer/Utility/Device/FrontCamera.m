//
//  FrontCamera.m
//  Learn-Metal
//
//  Created by  沈江洋 on 22/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "FrontCamera.h"

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface FrontCamera()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDataOutputSynchronizerDelegate>
{
    BOOL hasStarted;
    BOOL isDepthEnabled;
}

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) AVCaptureSession *avCaptureSession;
@property (nonatomic) dispatch_queue_t dataOutputQueue;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) AVCaptureDepthDataOutput *depthDataOutput;
@property (nonatomic) AVCaptureDataOutputSynchronizer *outputSynchronizer;

@end

@implementation FrontCamera

- (instancetype)initWithDepthTag: (BOOL) isEnabled
{
    if (self = [super init]) {
        
        isDepthEnabled=isEnabled;
        self.avCaptureSession=[[AVCaptureSession alloc] init];
        self.dataOutputQueue = dispatch_queue_create( "data output queue", DISPATCH_QUEUE_SERIAL );
        
        switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
            case AVAuthorizationStatusAuthorized:
            {
                break;
            }
            case AVAuthorizationStatusNotDetermined:
            {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                    if ( ! granted ) {
                        self.setupResult = AVCamSetupResultCameraNotAuthorized;
                    }
                }];
                break;
            }
            default:
            {
                self.setupResult = AVCamSetupResultCameraNotAuthorized;
                break;
            }
        }
        
        [self configureSession];
    }
    return self;
}

- (void)configureSession
{
    if ( self.setupResult != AVCamSetupResultSuccess ) {
        return;
    }
    
    // start and preset
    [self.avCaptureSession beginConfiguration];
    if(isDepthEnabled)
    {
        [self.avCaptureSession setSessionPreset: AVCaptureSessionPreset640x480];
        self.videoDevice=[AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInTrueDepthCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    }
    else
    {
        [self.avCaptureSession setSessionPreset: AVCaptureSessionPresetHigh];
        self.videoDevice=[AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    }
    
    // add videoDeviceInput
    NSError *error = nil;
    if ( ! self.videoDevice ) {
        NSLog(@"front true depth camera not available");
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.avCaptureSession commitConfiguration];
        return;
    }
    self.videoDeviceInput=[AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
    if ( ! self.videoDeviceInput ) {
        NSLog( @"Could not create video device input: %@", error );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.avCaptureSession commitConfiguration];
        return;
    }
    if ( [self.avCaptureSession canAddInput:self.videoDeviceInput] ) {
        [self.avCaptureSession addInput:self.videoDeviceInput];
    }
    else {
        NSLog( @"Could not add video device input to the session" );
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.avCaptureSession commitConfiguration];
        return;
    }
    
    // add videoDataOutput
    self.videoDataOutput=[[AVCaptureVideoDataOutput alloc] init];
    //[self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.dataOutputQueue];
    if([self.avCaptureSession canAddOutput:self.videoDataOutput]){
        [self.avCaptureSession addOutput:self.videoDataOutput];
    }
    else{
        NSLog( @"Could not add video data output to the session");
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.avCaptureSession commitConfiguration];
        return;
    }
    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    [videoConnection setVideoMirrored: YES];
    
    if(isDepthEnabled)
    {
        // add depthDataOutput
        self.depthDataOutput=[[AVCaptureDepthDataOutput alloc] init];
        if ([self.avCaptureSession canAddOutput:self.depthDataOutput]) {
            [self.avCaptureSession addOutput:self.depthDataOutput];
        }
        else{
            NSLog( @"Could not add depth data output to the session");
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            [self.avCaptureSession commitConfiguration];
            return;
        }
        [self.depthDataOutput setDelegate:self callbackQueue:self.dataOutputQueue];
        [self.depthDataOutput setFilteringEnabled:NO];
        [self.depthDataOutput setAlwaysDiscardsLateDepthData:YES];
        AVCaptureConnection *depthConnection = [self.depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
        [depthConnection setVideoOrientation: AVCaptureVideoOrientationPortrait];
        [depthConnection setVideoMirrored:YES];
        
//        float fov=self.videoDevice.activeFormat.videoFieldOfView;
//        NSLog(@"video horizonal FieldOfView: %f", fov);
        
        // add outputSynchronizer
        self.outputSynchronizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs: @[self.videoDataOutput, self.depthDataOutput]];
        [self.outputSynchronizer setDelegate:self queue: self.dataOutputQueue];
    }
    
    [self.avCaptureSession commitConfiguration];
}

- (void)startCapture
{
    switch (self.setupResult) {
        case AVCamSetupResultSuccess:
        {
            if (![self.avCaptureSession isRunning] && !hasStarted) {
                hasStarted = YES;
                [self.avCaptureSession startRunning];
                NSLog(@"AVCamSetupResultSuccess");
            }
            break;
        }
        case AVCamSetupResultCameraNotAuthorized:
        {
            NSLog(@"AVCamSetupResultCameraNotAuthorized");
            break;
        }
            
        default:
        {
            NSLog(@"configurationFailed");
            break;
        }
    }
}

- (void)stopCapture
{
    hasStarted = NO;
    if ([self.avCaptureSession isRunning]) {
        [self.avCaptureSession stopRunning];
    }
}

- (void)setExposurePoint: (CGPoint) pos
{
    NSError *error = nil;
    [self.videoDevice lockForConfiguration:&error];
    [self.videoDevice setExposurePointOfInterest:pos];
    [self.videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    [self.videoDevice unlockForConfiguration];
}

- (void)getFrameWidth: (size_t *) width andFrameHeight: (size_t *)height
{
    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(_videoDevice.activeFormat.formatDescription);
    AVCaptureConnection *videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if(AVCaptureVideoOrientationPortrait == videoConnection.videoOrientation)
    {
        *width = dimension.height;
        *height = dimension.width;
    }
    else
    {
        *width = dimension.width;
        *height = dimension.height;
    }
}

- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection{
    if([self.delegate respondsToSelector:@selector(didOutputVideoBuffer:andDepthBuffer:)])
    {
        CVPixelBufferRef depthPixelBuffer, videoPixelBuffer;
        
        AVCaptureSynchronizedData *syncedDepthData=[synchronizedDataCollection synchronizedDataForCaptureOutput:self.depthDataOutput];
        AVCaptureSynchronizedDepthData *syncedDepthBufferData=(AVCaptureSynchronizedDepthData *)syncedDepthData;
        if(!syncedDepthBufferData.depthDataWasDropped){
            depthPixelBuffer=[syncedDepthBufferData.depthData depthDataMap];
        }
        
        AVCaptureSynchronizedData *syncedVideoData=[synchronizedDataCollection synchronizedDataForCaptureOutput:self.videoDataOutput];
        AVCaptureSynchronizedSampleBufferData *syncedSampleBufferData=(AVCaptureSynchronizedSampleBufferData *)syncedVideoData;
        if(!syncedSampleBufferData.sampleBufferWasDropped){
            videoPixelBuffer = CMSampleBufferGetImageBuffer(syncedSampleBufferData.sampleBuffer);
            [self.delegate didOutputVideoBuffer:videoPixelBuffer andDepthBuffer:depthPixelBuffer];
        }
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if([self.delegate respondsToSelector:@selector(didOutputVideoBuffer:)])
    {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        [self.delegate didOutputVideoBuffer:pixelBuffer];
    }
}

@end
