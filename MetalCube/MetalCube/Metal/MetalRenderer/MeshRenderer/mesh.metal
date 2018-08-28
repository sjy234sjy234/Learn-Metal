//
//  mesh.metal
//  MetalCube
//
//  Created by  沈江洋 on 2018/8/28.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    float4 color;
};

struct MvpTransform
{
    float4x4 matrix;
};

vertex Vertex mesh_vertex_main(device Vertex *vertices [[buffer(0)]],
                               constant MvpTransform *mvpTransform [[buffer(1)]],
                               uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform->matrix * vertices[vid].position;
    vertexOut.color = vertices[vid].color;
    
    return vertexOut;
}

fragment float4 mesh_fragment_main(Vertex vertexIn [[stage_in]])
{
    return float4(vertexIn.color);
}

