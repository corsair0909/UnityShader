// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "PolyArtMaskTint"
{
	Properties
	{
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_Metallic("Metallic", Range( 0 , 1)) = 0
		_Hair("Hair", Color) = (0,0,0,0)
		_InnerCloth("InnerCloth", Color) = (0,0,0,0)
		_OuterChlothes("OuterChlothes", Color) = (0,0,0,0)
		_PolyArtAlbedo("PolyArtAlbedo", 2D) = "white" {}
		_PolyArtMask("PolyArtMask", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
		
		_MaskID ("MaskID",int) = 0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+2" }
		Cull Back
		Stencil
		{
			ref [_MaskID]
			Comp Equal
		}
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
			float3 worldPos;
		};

		uniform sampler2D _PolyArtAlbedo;
		uniform float4 _PolyArtAlbedo_ST;
		uniform sampler2D _PolyArtMask;
		uniform float4 _PolyArtMask_ST;
		uniform float4 _OuterChlothes;
		uniform float4 _InnerCloth;
		uniform float4 _Hair;
		uniform float _Metallic;
		uniform float _Smoothness;

		uniform sampler2D _NoiseTex;
		uniform float _Thrshold;
		uniform float _EdgeWidth;
		uniform float4 _DissloveNode;
		uniform float4 _DissloveDir;
		uniform float _DissloveScale;
		


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_PolyArtAlbedo = i.uv_texcoord * _PolyArtAlbedo_ST.xy + _PolyArtAlbedo_ST.zw;
			float4 tex2DNode16 = tex2D( _PolyArtAlbedo, uv_PolyArtAlbedo );
			float2 uv_PolyArtMask = i.uv_texcoord * _PolyArtMask_ST.xy + _PolyArtMask_ST.zw;
			float4 tex2DNode13 = tex2D( _PolyArtMask, uv_PolyArtMask );
			float4 temp_cast_0 = (tex2DNode13.r).xxxx;
			float4 temp_cast_1 = (tex2DNode13.g).xxxx;
			float4 temp_cast_2 = (tex2DNode13.b).xxxx;
			float4 blendOpSrc22 = tex2DNode16;
			float4 blendOpDest22 = ( min( temp_cast_0 , _OuterChlothes ) + min( temp_cast_1 , _InnerCloth ) + min( temp_cast_2 , _Hair ) );
			float4 lerpResult4 = lerp( tex2DNode16 , ( ( saturate( ( blendOpSrc22 * blendOpDest22 ) )) * 2.0 ) , ( tex2DNode13.r + tex2DNode13.g + tex2DNode13.b ));
			o.Albedo = lerpResult4.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	//CustomEditor "ASEMaterialInspector"
}