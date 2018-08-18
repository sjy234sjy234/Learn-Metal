//
//  point.metal
//  MetalPoint
//
//  Created by  沈江洋 on 2018/8/18.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    float4 color;
};

struct PVertex{
    float4 position [[position]];
    float4 color;
    float size[[point_size]];
};

vertex PVertex point_vertex_main(device Vertex *vertices [[buffer(0)]],
                           uint vid [[vertex_id]])
{
    PVertex outVertex;
    outVertex.position = vertices[vid].position;
    outVertex.color = vertices[vid].color;
    outVertex.size = 30;
    
    return outVertex;
}

fragment float4 point_fragment_main(PVertex inVertex [[stage_in]])
{
    return inVertex.color;
}


