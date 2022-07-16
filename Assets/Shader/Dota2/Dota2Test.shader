Shader "Unlit/Dota2Test"
{
  	Properties
	{
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
		/*
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 1
		[Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
		*/
		[Space(10)]
		_ColorTex("Color(RGB)", 2D) = "white"{}
		[Space(10)]
		_Tint("Tint", Color) = (1,1,1,1)
		_TintByBaseTex("Tint Mask(Grey)",2D) = "white"{}
		[Space(10)]
		_NormalTex("Normal(RGB)", 2D)="bump"{}
		[Space(10)]
		_MetalnessTex("Metalness Mask(Grey)", 2D) = "white"{}
		_Metalness("Metalness Intensity", Range(0,1)) = 0.0
		[Space(10)]
		_SpeculerTex("Speculer Mask(Grey)", 2D) = "white"{}
		_SpeculerExpTex("Speculer Exponent(Grey)", 2D) = "black"{}
		_Speculer("Speculer Intensity", Range(0,1)) = 0.0
		[Space(10)]
		_SelfIllumTex("SelfIllum Mask(Grey)", 2D) = "black"{}
		_SelfIllum("SelfIllum Intensity", Range(0,1)) = 0.0
		[Space(10)]
		_RimTex("Rim Mask(Grey)", 2D) = "black"{}
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_Rim("Rim Intensity", Range(0,1)) = 0.0
		[Space(10)]
		_CubeMap("Cube Map(RGB)", CUBE) = "black"{}
		_Cube("Cube Intensity",Range(0,1)) = 0.0
		[Space(10)]
		_TranslucencyTex("Translucency Mask(Grey)", 2D) = "white"{}
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.1
	}
	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest"
			"IgnoreProjector" = "True"
			"RenderType" = "TransparentCutout"
		}
		Cull [_Cull]
		/*
		Blend [_SrcBlend] [_DstBlend]
		ZWrite [_ZWrite]
		ZTest [_ZTest]
		*/

		CGPROGRAM
		#pragma surface surf CustomStandard fullforwardshadows alphatest:_Cutoff vertex:vert addshadow
		#pragma target 3.0
		#include "UnityPBSLighting.cginc"

		//PBS光照
		inline void LightingCustomStandard_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, s.Occlusion, s.Smoothness, s.Normal);
		}
		inline half4 LightingCustomStandard(SurfaceOutputStandard s, half3 viewDir, UnityGI gi)
		{
			s.Normal = normalize(s.Normal);

			half oneMinusReflectivity;
			half3 specColor;
			s.Albedo = DiffuseAndSpecularFromMetallic(s.Albedo, s.Metallic, specColor, oneMinusReflectivity);

			// shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
			// this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
			half outputAlpha;
			s.Albedo = PreMultiplyAlpha(s.Albedo, s.Alpha, oneMinusReflectivity, outputAlpha);

			half4 c = UNITY_BRDF_PBS(s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
			c.rgb += UNITY_BRDF_GI(s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);
			c.a = outputAlpha;

			return c;
		}

		struct Input 
		{
			float2 uv_ColorTex;
			float3 viewDir;
			float3 worldRefl;
			INTERNAL_DATA
		};

		sampler2D _ColorTex;
		sampler2D _TintByBaseTex;
		sampler2D _NormalTex;
		sampler2D _MetalnessTex;
		sampler2D _SpeculerTex;
		sampler2D _SpeculerExpTex;
		sampler2D _SelfIllumTex;
		sampler2D _RimTex;
		sampler2D _TranslucencyTex;
		samplerCUBE _CubeMap;

		fixed _Normal;
		fixed _Speculer;
		fixed _Metalness;
		fixed _SelfIllum;
		fixed _Rim;
		fixed3 _RimColor;
		fixed _Cube;
		fixed3 _Tint;

		void vert(inout appdata_full v) 
		{
			
		}

		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			//效果倍增器
			fixed multipler = 2;
			//颜色
			fixed tintByBaseMask = tex2D(_TintByBaseTex, IN.uv_ColorTex);
			half3 color = tex2D(_ColorTex, IN.uv_ColorTex);
			half3 colorTinted = tex2D(_ColorTex, IN.uv_ColorTex) * _Tint;
			half3 albedo = lerp(color, colorTinted, tintByBaseMask);
			//法线
			half3 normal = UnpackNormal(tex2D(_NormalTex,IN.uv_ColorTex));
			//金属性
			fixed metalnessTexed = tex2D(_MetalnessTex, IN.uv_ColorTex);
			fixed metallic = lerp(0, metalnessTexed * multipler, _Metalness);
			//高光
			fixed speculerTexed = tex2D(_SpeculerTex, IN.uv_ColorTex);
			fixed speculerExpTexed = tex2D(_SpeculerExpTex, IN.uv_ColorTex);
			fixed smoothness = lerp(0, speculerTexed * exp(speculerExpTexed) * multipler, _Speculer);
			//自发光
			half3 emission = lerp(0, (albedo * tex2D(_SelfIllumTex, IN.uv_ColorTex) * multipler), _SelfIllum);
			//边缘光
			fixed rimTexed = tex2D(_RimTex, IN.uv_ColorTex);
			fixed3 rim = lerp(0, _Rim * _RimColor * saturate(1 - saturate(dot(normal, IN.viewDir)) * 1.8), rimTexed);
			//立方环境贴图
			half3 cube = lerp(0, texCUBE(_CubeMap, WorldReflectionVector(IN, o.Normal)).rgb, _Cube);
			//抠图
			fixed alpha = tex2D(_TranslucencyTex, IN.uv_ColorTex);
			//clip(alpha - _Cutout);

			o.Albedo = albedo.rgb;
			o.Normal = normal;
			o.Metallic = metallic;
			o.Smoothness = smoothness;
			o.Emission = emission + rim + cube;
			o.Alpha = alpha;
		}
		ENDCG
	}
	FallBack "Diffuse"
	//CustomEditor "CustomEditor_Dota2_Standard"
}
