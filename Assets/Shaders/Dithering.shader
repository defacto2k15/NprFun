Shader "Custom/Dithering"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Unused Albedo (RGB)", 2D) = "white" {}
		_DitherPattern("DitherPattern", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_DebugToStandardLighting("_DebugToStandardLighting", Range(0,1)) = 0
		_Scale("_Scale", Range(0,1)) = 1
		_DebugScalar("DebugScalar",Range(0,1)) = 0
		_DebugLightIntensity("DebugLightIntensity",Range(0,1)) = 0
		_BrightColor("BrightColor",Color) = (1.0,1.0,1.0,1.0)
		_DarkColor("DarkColor",Color) = (0.0,0.0,0.0,0.0)
		_BiColourDitheringMarginSize("_BiColourDitheringMarginSize",Range(0,0.5)) = 0.1
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
		float _DebugScalar;
		float _DebugLightIntensity;
		float4 _BrightColor;
		float4 _DarkColor;
		float _BiColourDitheringMarginSize;

#include "UnityPBSLighting.cginc"

		float maxComponent(float3 v) {
			return max(max(v.x, v.y), v.z);
		}

		struct DitheringSurfaceOutputStandard
		{
			float DitherValue;
			fixed3 Albedo;      // base (diffuse or specular) color
			fixed3 Normal;      // tangent space normal, if written
			half3 Emission;
			half Metallic;      // 0=non-metal, 1=metal
			half Smoothness;    // 0=rough, 1=smooth
			half Occlusion;     // occlusion (default 1)
			fixed Alpha;        // alpha for transparencies
		};

		SurfaceOutputStandard DitheringSosToSos(DitheringSurfaceOutputStandard s) {
			SurfaceOutputStandard sos;
			sos.Albedo = s.Albedo;
			sos.Normal = s.Normal;
			sos.Emission = s.Emission;
			sos.Metallic = s.Metallic;
			sos.Smoothness = s.Smoothness;
			sos.Occlusion = s.Occlusion;
			sos.Alpha = s.Alpha;
			return sos;
		}

		float4 LightingBartekDithering(DitheringSurfaceOutputStandard s, float3 lightDir, UnityGI gi){
			float ditherValue = s.DitherValue;

			float3 originalAlbedo = s.Albedo;
			s.Albedo = 1;
			float pixelLighting = maxComponent(LightingStandard(DitheringSosToSos(s), lightDir, gi));

			float4 ditheredColor;
			ditheredColor = originalAlbedo.rgbb;
			//if (pixelLighting < 0.5) {
			//	float ditherFactor = pixelLighting / _BiColourDitheringMarginSize;
			//	if (ditherValue > ditherFactor) {
			//		ditheredColor = _DarkColor;
			//	}
			//	//ditheredColor = step(ditherValue, ditherFactor);
			//}
			//else {
			//	float ditherFactor = (1-pixelLighting) / _BiColourDitheringMarginSize;
			//	if (ditherValue > ditherFactor) {
			//		ditheredColor = _BrightColor;
			//	}
			//	//ditheredColor = step(ditherValue, ditherFactor);
			//}
			ditheredColor = step(ditherValue, pixelLighting);

			return lerp(ditheredColor, pixelLighting, _DebugToStandardLighting);
		}

		inline void LightingBartekDithering_GI(DitheringSurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi) {
			LightingStandard_GI(DitheringSosToSos(s), data, gi);
		}

        struct Input
        {
            float2 uv_MainTex;
			float4 screenPos;
        };

		float sawtooth(float x) {
			return abs(frac(x) - frac(2 * x));
		}

#include "SimplexNoise2D.hlsl"

        void surf (Input IN, inout DitheringSurfaceOutputStandard o)
        {
			float2 uv = IN.uv_MainTex;
			float2 screenPos = IN.screenPos.xy / IN.screenPos.w;
			float2 ditherCoordinate = _Scale* screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
			float ditherValue = sawtooth(snoise(ditherCoordinate*float2(10	,2)));

			ditherValue = sawtooth(snoise(ditherCoordinate*float2(10	,2) + snoise(uv*3)));
			//ditherValue = tex2D(_DitherPattern, ditherCoordinate*_Scale).r;

			o.Albedo = float4(0.7,0.25,0.5,1);
			o.Albedo.xy += 0.2 * sin(uv.xy * 100.31);
			o.DitherValue = ditherValue;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
