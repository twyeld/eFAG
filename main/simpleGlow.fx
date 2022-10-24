////////////////////////////////////////////////////
// simpleglow.fx
// create a one-pass glow outline around the object
// in the entities' RGB color
// requires material TRANSLUCENT flag
////////////////////////////////////////////////////

#include <view>
float4x4 matProj;
float4 vecColor;

static float fGlowExtent = 1.0f; // glow thickness
 
struct out_glow 
{ 
   float4 Pos: POSITION; 
   float4 Color: COLOR; 
};

 
out_glow vs_glow( 
   in float4 Pos: POSITION,  
   in float3 Normal: NORMAL) 
{ 
   out_glow Out; 
 
   float3 N = normalize(DoView(Normal)); // normal (view space) 
   float3 P = DoView(Pos) + fGlowExtent * N; // displaced position (view space) 

   float fPower = N.z;
   fPower *= fPower;
   fPower -= 1; 
   fPower *= fPower;                   // fPower = ((N.z)^2-1)^2
     
   Out.Pos = mul(float4(P,1),matProj); // projected position 
   Out.Color = vecColor * fPower;      // modulated glow color + glow ambient 
    
   return Out; 
}

float4 ps_glow(out_glow In): COLOR
{
   return In.Color;
}

technique glow
{
	pass one { } // first draw the object 
	pass two     // then draw the glow
	{		
// enable additive blending
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;	
		DestBlend = ONE;
		VertexShader = compile vs_1_1 vs_glow();
		PixelShader = compile ps_1_1 ps_glow();
	}
}