//
//  ImageBlenderEncoder.metal
//  MeshFrameGlowing
//
//  Created by  沈江洋 on 2018/9/5.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlendAlpha
{
    float val;
};

// imageBlender compute kernel
kernel void
imageBlender(texture2d<float, access::read> firstTexture [[texture(0)]],
             texture2d<float, access::read> secondTexture [[texture(1)]],
             texture2d<float, access::write> dstTexture [[texture(2)]],
             constant BlendAlpha*  blendAlpha  [[buffer(0)]],
                  uint2  gid         [[thread_position_in_grid]],
                  uint2  tspg        [[threads_per_grid]])
{
    float4 firstColor = firstTexture.read(gid);
    float4 secondColor = secondTexture.read(gid);
    float4 outColor = firstColor * blendAlpha->val + secondColor * (1.0 - blendAlpha->val);
    dstTexture.write(outColor, gid);
}

