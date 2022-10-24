#include <transform>
#include <fog>
#include <pos>
#include <normal>
#include <tangent>
#include <light>

float4 vecLight;

texture entSkin1;	// texture
texture entSkin2;	// normal map

float4 vecSkill41;
//vecSkill41.x: float facAmbient = 0.2;
//vecSkill41.y: float facDiff = 0.5;
//vecSkill41.z: float facSpec = 0.8;
//vecSkill41.w: float shininess = 4;

float3 LiteColor = {0.8f, 0.5f, 0.1f};
float3 DarkColor = {0.0f, 0.0f, 0.0f};
float3 WarmColor = {0.5f, 0.4f, 0.05f};
float3 CoolColor = {0.05f, 0.05f, 0.6f};
float3 SpecColor = {0.7f, 0.7f, 1.0f};

float GlossTop = 0.7;
float GlossBot = 0.5;
float GlossDrop = 0.2;

sampler sBaseTex = sampler_state { Texture = <entSkin1>; MipFilter = Linear;	};
sampler sBump = sampler_state { Texture = <entSkin2>; MipFilter = Linear;	};

struct goochOut
{
	float4 Pos:    	POSITION;
	float  Fog:			FOG;
	float4 Color:		COLOR;		
	float4 Ambient:	COLOR1;
	float2 Tex:   		TEXCOORD0;	
	float3 Position:	TEXCOORD1;	
	float3 Light:		TEXCOORD2;	
	float3 Normal: 	TEXCOORD3;	
	float3 Tangent:	TEXCOORD4;
};

goochOut perPixel_VS(
in float4 inPos: 		POSITION, 
in float3 inNormal:	NORMAL,
in float2 inTex: 		TEXCOORD0,
in float3 inTangent: TEXCOORD2)
{
	goochOut Out;

	Out.Pos	= DoTransform(inPos);
	Out.Tex	= inTex;
	Out.Fog	= DoFog(inPos);
	float facAmbient = vecSkill41.x / 100.;
	Out.Ambient = facAmbient*vecLight;	
	
	Out.Normal = inNormal;
	Out.Tangent = inTangent;
	
	Out.Position = inPos;
	
	float3 P = DoPos(inPos);
	
	Out.Light = vecLightPos[0].xyz;
	
	float fDist = length(vecLightPos[0].xyz - P)/vecLightPos[0].w;
	if (vecLightPos[0].w>9000)	fDist = 0.;
   if (fDist < 1.f)	fDist = 1.f - fDist;
   else	fDist = 0.f; 
	 
	Out.Color = fDist*vecLightColor[0];
	
	return Out;		
}


float4 specularGooch_PS(goochOut In): COLOR
{
	float4 base = tex2D(sBaseTex,In.Tex);
	float3 bumpNormal = tex2D(sBump,In.Tex)*2-1;
	
	CreateTangents(In.Normal,In.Tangent);
	float3 lightDir = DoTangent(normalize(In.Light-In.Position));
	float3 viewDir = DoTangent( normalize(vecViewPos-In.Position) );	
	float3 halfway = normalize(lightDir+viewDir);
		
	float mixer = 0.5 * ( dot(lightDir,bumpNormal) + 1. );
	float facDiff = vecSkill41.y / 20.;
	float3 diffuse = ( lerp(DarkColor,LiteColor,mixer) + lerp(CoolColor,WarmColor,mixer) ) * facDiff;
	
	float facSpec = vecSkill41.z / 20.;
	float shininess;
	if ( vecSkill41.w <= 20. )
		shininess = vecSkill41.w / 20.;
	else
		shininess = (vecSkill41.w-19)*2.;
	float spec = pow( max( 0 , dot(halfway,bumpNormal) ) , shininess ) * facSpec;
	spec *= ( GlossDrop + smoothstep ( GlossBot , GlossTop , spec ) * ( 1.0 - GlossDrop ) );
	float3 specular = spec * SpecColor;
	
	return base * float4(specular+diffuse,1);
}

technique gooch
{
	pass One
	{		
		VertexShader = compile vs_2_0 perPixel_VS();
		PixelShader = compile ps_2_0 specularGooch_PS();
	}
}

technique fallback { pass one { } }