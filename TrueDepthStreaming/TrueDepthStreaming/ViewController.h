//
//  ViewController.h
//  GaussianBlurMPS
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *startStreamButton;

@property (weak, nonatomic) IBOutlet UIButton *stopStreamButton;

@end

