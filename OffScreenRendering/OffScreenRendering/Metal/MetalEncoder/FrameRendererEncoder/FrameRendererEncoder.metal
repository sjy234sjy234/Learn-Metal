//
//  frame.metal
//  MeshFrame
//
//  Created by  沈江洋 on 2018/8/29.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
};

struct MvpTransform
{
    float4x4 matrix;
};

struct WHRatio
{
    float ratio;
};

struct ThickNess
{
    float val;
};

vertex Vertex frameLine_vertex_main(device Vertex *vertices [[buffer(0)]],
                               device uint2 *lineIndices [[buffer(1)]],
                               constant MvpTransform *mvpTransform [[buffer(2)]],
                               constant WHRatio *whRatio [[buffer(3)]],
                               constant ThickNess *thickness [[buffer(4)]],
                               uint vid [[vertex_id]],
                               uint iid [[instance_id]])
{
    uint lineIndex1=lineIndices[iid].x;
    uint lineIndex2=lineIndices[iid].y;
    
    float4 position1 = mvpTransform->matrix * vertices[lineIndex1].position;
    float4 position2 = mvpTransform->matrix * vertices[lineIndex2].position;
    position1 = position1 / position1.w;
    position2 = position2 / position2.w;
    
    float4 v = position2 - position1;
    float2 p0 = float2(position1.x,position1.y);
    float2 v0 = float2(v.x,v.y);
    float2 v1 = thickness->val * normalize(v0) * float2x2(float2(0,-1),float2(1,0));
    v1.x /= whRatio->ratio;
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
    
    outVertex.position.z -= 0.001;
    
    return outVertex;
}

fragment half4 frameLine_fragment_main(Vertex inVertex [[stage_in]])
{
    return {1.0, 0.0, 1.0, 1.0};
}

vertex Vertex frameMesh_vertex_main(device Vertex *vertices [[buffer(0)]],
                               constant MvpTransform *mvpTransform [[buffer(1)]],
                               uint vid [[vertex_id]])
{
    Vertex vertexOut;
    vertexOut.position = mvpTransform->matrix * vertices[vid].position;
    return vertexOut;
}

fragment half4 frameMesh_fragment_main(Vertex vertexIn [[stage_in]])
{
    return {1.0,1.0,1.0,0.0};
}


