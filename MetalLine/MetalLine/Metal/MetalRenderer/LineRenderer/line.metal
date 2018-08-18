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
                                device uint2 *lineIndices [[buffer(1)]],
                                uint vid [[vertex_id]],
                                uint iid [[instance_id]])
{
    float thickness=0.02;
    uint lineIndex1=lineIndices[iid].x;
    uint lineIndex2=lineIndices[iid].y;
    
    float4 position1=vertices[lineIndex1].position;
    float4 position2=vertices[lineIndex2].position;
    
    float4 v = position2 - position1;
    float2 p0 = float2(position1.x,position1.y);
    float2 v0 = float2(v.x,v.y);
    float2 v1 = thickness * normalize(v0) * float2x2(float2(0,-1),float2(1,0));
    float2 pa = p0 + v1;
    float2 pb = p0 - v1;
    float2 pc = p0 - v1 + v0;
    float2 pd = p0 + v1 + v0;
    
    Vertex outVertex;
    switch(vid)
    {
        case 0:
            outVertex.position = float4(pa.x,pa.y,position1.z,position1.w);
            break;
        case 1:
            outVertex.position = float4(pb.x,pb.y,position1.z,position1.w);
            break;
        case 2:
            outVertex.position = float4(pc.x,pc.y,position2.z,position2.w);
            break;
        case 3:
            outVertex.position = float4(pa.x,pa.y,position1.z,position1.w);
            break;
        case 4:
            outVertex.position = float4(pc.x,pc.y,position2.z,position2.w);
            break;
        case 5:
            outVertex.position = float4(pd.x,pd.y,position2.z,position2.w);
            break;
    }
    
    outVertex.color={1.0,0.0,0.0,1.0};
    return outVertex;
}

fragment float4 line_fragment_main(Vertex inVertex [[stage_in]])
{
    return inVertex.color;
}

