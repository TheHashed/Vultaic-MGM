#include "mta-helper.fx"

#define SCALE 180.0

float2 resolution = float2(1, 1);
float intensity = 1;
float opacity = 1;
float3 color = float3(1.0, 1.0, 1.0);
float rate = 1.0;

struct vsin
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
};

struct vsout
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
};

vsout vs(vsin input)
{
	vsout output;
	output.Position = mul(input.Position, gWorldViewProjection);
	output.TexCoord = input.TexCoord;
	return output;
}

float4 ps(vsout input) : COLOR0
{
	float time = gTime * (0.5 + rate);
	float2 pos = input.TexCoord.xy;
	float pos1 = 0.0;
	float aspect = resolution.x / resolution.y;
	float texcolor = 0.0;
	texcolor += pow((sin((pos.x+pos1+time/50.) * SCALE * aspect) + 1.0)/2.0, 180.0);
	texcolor += pow((sin((pos.y+pos1*time/50.) * SCALE) + 1.0)/2.0, 180.0);
	texcolor += pow((sin((pos.x+pos1*time/30.) * SCALE * aspect) + 1.0)/2.0, 180.0);
	texcolor += pow((sin((pos.y+time/30.) * SCALE) + 1.0)/2.0, 180.0);
	float outFX = saturate(opacity * texcolor);
	return float4(color * texcolor * intensity, outFX);
}

float countDepthBias(float minBias, float maxBias, float closeBias)
{
    float4 viewPos = mul(float4(gWorld[3].xyz, 1), gView);
    float4 projPos = mul(viewPos, gProjection);
    float depthImpact = minBias + ((maxBias - minBias) * (1 - saturate(projPos.z / projPos.w)));
    depthImpact += closeBias * saturate(0.5 - (viewPos.z / viewPos.w));
    return depthImpact;
}

technique tec
{
	pass Pass0
	{
        SlopeScaleDepthBias = -0.5;
        DepthBias = countDepthBias(-0.000002, -0.0004, -0.001);
		AlphaBlendEnable = true;
		AlphaRef = 1;
		VertexShader = compile vs_3_0 vs();
		PixelShader = compile ps_3_0 ps();
	}
}