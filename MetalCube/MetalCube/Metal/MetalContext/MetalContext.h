#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>

@protocol MTLDevice, MTLLibrary, MTLCommandQueue;

@interface MetalContext : NSObject

@property (strong) id<MTLDevice> device;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLCommandQueue> commandQueue;

+ (instancetype)newContext;

@end
