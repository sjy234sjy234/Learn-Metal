#include <metal_stdlib>

using namespace metal;

struct TextureVertex
{
    float4 position [[position]];
    float2 texCoords;
};

vertex TextureVertex texture_vertex_main(constant TextureVertex *vertices [[buffer(0)]],
                                      uint vid [[vertex_id]])
{
    return vertices[vid];
}

fragment float4 texture_fragment_main(TextureVertex vert [[stage_in]],
                                 texture2d<float> videoTexture [[texture(0)]],
                                 sampler samplr [[sampler(0)]])
{
    float3 texColor = videoTexture.sample(samplr, vert.texCoords).rgb;
    float2 texCoords=vert.texCoords;
    return float4(texColor, 1);
    
//    float3 texColor = videoTexture.sample(samplr, vert.texCoords).rgb;
//    float2 texCoords=vert.texCoords;
//    float2 texCenter={0.5,0.5};
//    if(distance(texCoords,texCenter)<=0.2859)
//    {
//        return float4(texColor, 1);
//    }
//    else
//    {
//        return float4(texColor/3, 1);
//    }
}
