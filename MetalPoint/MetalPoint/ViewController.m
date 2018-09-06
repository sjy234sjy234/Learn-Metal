//
//  ViewController.m
//  MetalPoint
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <MetalViewDelegate>

@property (nonatomic, strong) MetalContext *metalContext;

@property (nonatomic) MetalView *myMetalView;

@property (nonatomic) PointRenderer *pointRenderer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.metalContext = [MetalContext shareMetalContext];
    
    self.myMetalView=[[MetalView alloc] init];
    self.myMetalView.frame=CGRectMake(10, 150, 300, 300);
    self.myMetalView.backgroundColor = [UIColor grayColor];
    self.myMetalView.delegate = self;
    [self.view addSubview:self.myMetalView];
    
    self.pointRenderer = [[PointRenderer alloc] initWithLayer: self.myMetalView.metalLayer andContext: _metalContext];
    [self.pointRenderer draw];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
