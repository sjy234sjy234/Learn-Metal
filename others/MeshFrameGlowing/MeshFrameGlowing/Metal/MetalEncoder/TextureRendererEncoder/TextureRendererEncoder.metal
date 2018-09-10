#include <metal_stdlib>

using namespace metal;

struct TextureVertex
{
    float4 position [[position]];
    float2 texCoords;
};

struct InputFloat3
{
    float x;
    float y;
    float z;
};

vertex TextureVertex texture_vertex_main(constant InputFloat3 *inVertex [[buffer(0)]],
                                      uint vid [[vertex_id]])
{
    TextureVertex vert;
    vert.position = float4(inVertex[vid].x, inVertex[vid].y, inVertex[vid].z, 1.0);
    vert.texCoords = float2(0.5 + inVertex[vid].x / 2.0, 0.5 - inVertex[vid].y / 2.0);
    return vert;
}

fragment half4 texture_fragment_main(TextureVertex vert [[stage_in]],
                                 texture2d<float> videoTexture [[texture(0)]],
                                 sampler samplr [[sampler(0)]])
{
    float3 texColor = videoTexture.sample(samplr, vert.texCoords).rgb;
    float2 texCoords=vert.texCoords;
    return half4((half3)texColor, 1);
}
