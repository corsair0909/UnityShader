Shader "Custom/Cloud Parallax" 
{
	Properties {
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		_Alpha("Alpha", Range(0,1)) = 0.5
		_Height("Displacement Amount",range(0,1)) = 0.15
		_HeightAmount("Turbulence Amount",range(0,2)) = 1
		_HeightTileSpeed("Turbulence Tile&Speed",Vector) = (1.0,1.0,0.05,0.0)
		_LightIntensity ("Ambient Intensity", Range(0,3)) = 1.0
		[Toggle] _UseFixedLight("Use Fixed Light", Int) = 1
		_FixedLightDir("Fixed Light Direction", Vector) = (0.981, 0.122, -0.148, 0.0)

	}

	CGINCLUDE



	ENDCG

	SubShader 
	{
		LOD 300		
        Tags 
		{
            "IgnoreProjector"="True"
            "Queue"="Transparent-50"
            "RenderType"="Transparent"
			//"RenderType"="Opaque"
        }

		Pass
		{
		    Name "FORWARD"
            Tags 
			{
                "LightMode"="ForwardBase"
            }
			Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			
			#pragma multi_compile_fwdbase
            #pragma target 3.0

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half _Height;
			float4 _HeightTileSpeed;
			half _HeightAmount;
			half4 _Color;
			half _Alpha;
			half _LightIntensity;

			half4 _LightingColor;
			half4 _FixedLightDir;
			half _UseFixedLight;

			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float4 posWorld : TEXCOORD3;
				float2 uv2 : TEXCOORD4;
				float4 color : TEXCOORD5;
				UNITY_FOG_COORDS(7)
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex) + frac(_Time.y*_HeightTileSpeed.zw);
				o.uv2 = v.texcoord * _HeightTileSpeed.xy;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				TANGENT_SPACE_ROTATION;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				float3 viewRay=normalize(i.viewDir*-1);
				viewRay.z=abs(viewRay.z)+0.2;
				viewRay.xy *= _Height;

				float3 shadeP = float3(i.uv,0);
				float3 shadeP2 = float3(i.uv2,0);


				float linearStep = 16;

				float4 T = tex2D(_MainTex, shadeP2.xy);
				float h2 = T.a * _HeightAmount;

				float3 lioffset = viewRay / (viewRay.z * linearStep);
				float d = 1.0 - tex2Dlod(_MainTex, float4(shadeP.xy,0,0)).a * h2;
				float3 prev_d = d;
				float3 prev_shadeP = shadeP;
				while(d > shadeP.z)
				{
					prev_shadeP = shadeP;
					shadeP += lioffset;
					prev_d = d;
					d = 1.0 - tex2Dlod(_MainTex, float4(shadeP.xy,0,0)).a * h2;
				}
				float d1 = d - shadeP.z;
				float d2 = prev_d - prev_shadeP.z;
				float w = d1 / (d1 - d2);
				shadeP = lerp(shadeP, prev_shadeP, w);

				half4 c = tex2D(_MainTex,shadeP.xy) * T * _Color;
				half Alpha = lerp(c.a, 1.0, _Alpha) * i.color.r;

				float3 normal = normalize(i.normalDir);
				half3 lightDir1 = normalize(_FixedLightDir.xyz);
				half3 lightDir2 = UnityWorldSpaceLightDir(i.posWorld);
				half3 lightDir = lerp(lightDir2, lightDir1, _UseFixedLight);
				float NdotL = max(0,dot(normal,lightDir));
				half3 lightColor = _LightColor0.rgb;
                fixed3 finalColor = c.rgb*(NdotL*lightColor + 1.0);
                return half4(finalColor.rgb,Alpha);
			}
		ENDCG
		}
	}

	// no occlusion
	SubShader 
	{
		LOD 200		
        Tags 
		{
            "IgnoreProjector"="True"
            "Queue"="Transparent-50"
            "RenderType"="Transparent"
        }

		Pass
		{
		    Name "FORWARD"
            Tags 
			{
                "LightMode"="ForwardBase"
            }
			Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
            #pragma target 3.0

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half _Height;
			float4 _HeightTileSpeed;
			half _HeightAmount;
			half4 _Color;
			half _LightIntensity;
			half _Alpha;

			half _DirectLightAmount;
			half4 _LightingColor;
			half4 _FixedLightDir;
			half _UseFixedLight;

			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float4 posWorld : TEXCOORD3;
				float2 uv2 : TEXCOORD4;
				float4 color : TEXCOORD5;
				UNITY_FOG_COORDS(7)

			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex) + frac(_Time.y*_HeightTileSpeed.zw);
				o.uv2 = v.texcoord * _HeightTileSpeed.xy;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				TANGENT_SPACE_ROTATION;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
				o.color = v.color;

				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				float3 viewRay=normalize(i.viewDir*-1);
				viewRay.z=abs(viewRay.z)+0.42;
				viewRay.xy *= _Height;

				float3 shadeP = float3(i.uv,0);
				float3 shadeP2 = float3(i.uv2,0);

				float4 T = tex2D(_MainTex,shadeP2.xy);
				float h2 = T.a * _HeightAmount;

				float3 sioffset = viewRay / viewRay.z;
				float d = 1.0 - tex2Dlod(_MainTex, float4(shadeP.xy,0,0)).a * h2;
				shadeP += sioffset * d;

				half4 c = tex2D(_MainTex,shadeP.xy) * T * _Color;
				half Alpha = lerp(c.a, 1.0, _Alpha) * i.color.r;

				float3 normal = normalize(i.normalDir);
				half3 lightDir1 = normalize(_FixedLightDir.xyz);
				half3 lightDir2 = UnityWorldSpaceLightDir(i.posWorld);
				half3 lightDir = lerp(lightDir2, lightDir1, _UseFixedLight);
				float NdotL = max(0,dot(normal,lightDir));

				fixed initFactor = step(0.1, _LightingColor.a);
				_DirectLightAmount = lerp(1.0, _DirectLightAmount, initFactor);
				half3 lightColor = _LightColor0.rgb * _DirectLightAmount;

                fixed3 finalColor = c.rgb*(NdotL*lightColor + unity_AmbientEquator.rgb);
				UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return half4(finalColor.rgb,Alpha);
			}
		ENDCG
		}
	}

	FallBack "Diffuse"
}
