//
//  MeshDepthMaskEncoder.metal
//  MeshFrameGlowing
//
//  Created by 美戴科技 on 2018/10/10.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
};

struct InputFloat3
{
    float x;
    float y;
    float z;
};

vertex Vertex meshDepthMaskEncoder_vertex_main(constant InputFloat3  *vertices [[buffer(0)]],
                                              constant float4x4 &mvpTransform [[buffer(1)]],
                                              uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform * float4(vertices[vid].x, vertices[vid].y, vertices[vid].z, 1.0);
    return vertexOut;
}

fragment half4 meshDepthMaskEncoder_fragment_main(Vertex vertexIn [[stage_in]])
{
    return {1.0,1.0,1.0,0.0};
}

