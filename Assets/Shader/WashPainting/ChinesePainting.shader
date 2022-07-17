Shader "Unlit/ChinesePainting"
{
    Properties
    {
        [Header(Outline)]

        _PainNoiseTex("Noise",2D) = "white"{}
        _LineWidth("LineWidth",float) = 0.1
        _NoiseWidth("NoiseWidth",float) = 0.1
        _LineColor("LineColor",color) = (0,0,0,1)
        
        [Space(15)]
        [Header(Painting)]
        _RampTex("Ramp",2D) = "white"{}
        _Painting ("Painting", 2D) = "white" {}
        _PaintingNoise("PaintingNoise",2D) = "white"{}
        _PaintWidth ("PaintWidth",float) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
            };

            sampler2D _PainNoiseTex;
            float4 _MainTex_ST;
            fixed _LineWidth;
            fixed _NoiseWidth,_PaintCutOut;
            half4 _LineColor;

            v2f vert (appdata_base v)
            {
                float noise = tex2Dlod(_PainNoiseTex,v.vertex).r;
                v2f o;
                float4 PosVS = mul(UNITY_MATRIX_MV,v.vertex);
                float3 NdirVS = normalize(mul(UNITY_MATRIX_IT_MV,float4(v.normal,1)).xyz);
                NdirVS.z = -0.5;
                
                float linewidth = -PosVS.z / (unity_CameraProjection[1].y);
				linewidth = sqrt(linewidth);
                
                PosVS += float4(NdirVS,0)* linewidth *  _LineWidth * noise * _NoiseWidth;
                o.vertex = mul(UNITY_MATRIX_P,PosVS);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _LineColor;
            }
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 Normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 WorldPos : TEXCOORD2;
            };

            sampler2D _RampTex,_Painting,_PaintingNoise;
            fixed _PaintWidth,_radius,_Resolution;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.Normal = UnityObjectToWorldNormal(v.normal);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 NdirWS = normalize(i.Normal);
                fixed3 LdirWS = normalize(UnityWorldSpaceLightDir(i.WorldPos.xyz));
                fixed HalfNdotL = saturate(dot(NdirWS,LdirWS)) * 0.5f + 0.5f;
                float2 NoiseUV = float2(HalfNdotL,HalfNdotL);
                float4 Noise = tex2D(_PaintingNoise,i.uv);
                float2 curUV = NoiseUV + (Noise * _PaintWidth);
                curUV = clamp(curUV,0,1);
                
                return tex2D(_RampTex,curUV);
                // sum += tex2D(_RampTex,float2(curUV.x - 4 * weightVal,curUV.y - 4 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 3 * weightVal,curUV.y - 3 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 2 * weightVal,curUV.y - 2 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 1 * weightVal,curUV.y - 1 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x * weightVal,curUV.y * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 1 * weightVal,curUV.y - 1 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 2 * weightVal,curUV.y - 2 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 3 * weightVal,curUV.y - 3 * weightVal));
                // sum += tex2D(_RampTex,float2(curUV.x - 4 * weightVal,curUV.y - 4 * weightVal));
                // return sum;
            }
            ENDCG
        }
    }
}
