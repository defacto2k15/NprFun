Shader "Custom/Dithering"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Unused Albedo (RGB)", 2D) = "white" {}
		_DitherPattern("DitherPattern", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_DebugToStandardLighting("_DebugToStandardLighting", Range(0,1)) = 0
		_Scale("_Scale", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf BartekDithering
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _DitherPattern;
		float4 _DitherPattern_TexelSize;
        half _Glossiness;
        half _Metallic;
		float _DebugToStandardLighting;
		float _Scale;

#include "UnityPBSLighting.cginc"

		float maxComponent(float3 v) {
			return max(max(v.x, v.y), v.z);
		}

		float4 LightingBartekDithering(SurfaceOutputStandard s  , float3 lightDir, UnityGI gi){
			float ditherValue = s.Albedo.x;

			s.Albedo = 1;
			float pixelLighting = maxComponent(LightingStandard(s, lightDir, gi));
			//return step(ditherValue, _DebugToStandardLighting);
			return lerp(step(ditherValue, pixelLighting), pixelLighting, _DebugToStandardLighting);
		}

		inline void LightingBartekDithering_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi) {
			LightingStandard_GI(s, data, gi);
		}

        struct Input
        {
            float2 uv_MainTex;
			float4 screenPos;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float2 screenPos = IN.screenPos.xy / IN.screenPos.w;
			float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
			float ditherValue = tex2D(_DitherPattern, ditherCoordinate*_Scale).r;

			o.Albedo = float3(ditherValue,0, 0);
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
