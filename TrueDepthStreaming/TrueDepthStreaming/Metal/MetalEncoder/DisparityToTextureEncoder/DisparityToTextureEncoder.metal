//
//  DisparityToTextureEncoder.metal
//  TrueDepthStreaming
//
//  Created by  沈江洋 on 2018/9/6.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// disparityToTexture compute kernel
kernel void
disparityToTexture(constant half*  currentDisparityBuffer  [[buffer(0)]],
               texture2d<float, access::write> outTexture [[texture(0)]],
               uint2  gid         [[thread_position_in_grid]],
               uint2  tspg        [[threads_per_grid]])
{
    uint invid = gid.y * tspg.x + gid.x;
    half inDisparity = currentDisparityBuffer[invid];
    half inDepth = 1.0 / inDisparity;
    float4 outColor = {inDepth, inDepth, inDepth, inDepth};
    outTexture.write(outColor, gid);
}
