//
//  line.metal
//  MetalLine
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

vertex Vertex line_vertex_main(device Vertex *vertices [[buffer(0)]],
                                uint vid [[vertex_id]])
{
    Vertex outVertex;
    outVertex.position = vertices[vid].position;
    outVertex.color = vertices[vid].color;
    return outVertex;
}

fragment float4 line_fragment_main(Vertex inVertex [[stage_in]])
{
    return inVertex.color;
}

