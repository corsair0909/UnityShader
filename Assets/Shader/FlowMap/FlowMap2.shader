Shader "Unlit/FlowMap2"
{
    Properties
    {
        _Color ("Color",color) = (1,1,1,1)
        
        [Space(10)]
        
        [Header(Texture)]
        [Space(5)]
        _MainTex ("MainTex", 2D) = "white" {}
        _FlowMap ("FlowMap", 2D) = "white" {}
        _NormalMap("Derivative",2D) = "White"{}
        
        [Space(5)]
        [Header(LightParameter)]
        [Space(5)]
        _NormalScale("NormalScale",range(0,4)) = 0.5
        _Gloss("Gloss",range(30,90)) = 70
        
        [Space(15)]
        [Header(FlowParameter)]
        [Space(5)]
        _FlowStrange ("FlowStrange",range(0,3)) = 0.2
        _FlowSpeed ("FlowSpeed",range(0,5)) = 0.2
        _FlowOffset ("FlowOffset",range(0,5)) = 0.2
        _Jump1("JumpA",range(0,0.25)) = 0
        _Jump2("JumpB",range(0,0.25)) = 0
        _Tiling("Tiling",float) = 0
        
        [Space(15)]
        [Header(WaveParameter)]
        _Amplitude("Amplitude",range(0,1)) = 0.45
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 LdirTS : TEXCOORD1;
                float3 VdirTS : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            sampler2D _NormalMap;
            
            fixed _FlowStrange,_FlowSpeed,_FlowOffset;
            fixed _Jump1,_Jump2;
            fixed _Tiling;
            fixed _NormalScale,_Gloss;

            fixed _Amplitude;

            half4 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;

                float4 WaveVertex = v.vertex;
                WaveVertex.y = _Amplitude*sin(WaveVertex.x);
                
                o.vertex = UnityObjectToClipPos(WaveVertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_ROTATION;
                o.LdirTS = mul(rotation,ObjSpaceLightDir(v.vertex));
                o.VdirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                return o;
            }
            float3 FlowUVW(float2 uv,float2 offset,float tiling,float2 jump,float time,bool flow)
            {
                float LoopOffset = flow? 0.5:0;
                float pregress = frac(time+LoopOffset);
                float3 UVW;//带有权重的返回值，W分量保存权重

                UVW.xy = uv - offset * (pregress+_FlowOffset);
                //
                UVW.xy *= tiling;
                //将两次偏移错开半个周期，否则每秒循环两次
                UVW.xy +=LoopOffset;
                //构造相差半个周期的权重，W(1) = W(0) = 0 ，W(1/2) = W(1/2) = 1 ，
                UVW.z = 1-abs(1-2*pregress);
                return UVW;
            }

            float3 UnpackDerivativeMap(float4 var_DerivativeMap)
            {
                float3 rgb = var_DerivativeMap.agb;
                rgb.xy *= 2 - 1;
                return rgb;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 LdirTS = normalize(i.LdirTS);
                float3 VdirTS = normalize(i.VdirTS);
                
                float2 var_FlowMap = tex2D(_FlowMap,i.uv).rg * 2 - 1 ;
                var_FlowMap *= _FlowStrange;
                
                float noise  = tex2D(_FlowMap,i.uv).a;
                float time = _Time.y * _FlowSpeed + noise;

                float2 jump = float2(_Jump1,_Jump2);
                
                float3 uv1 = FlowUVW(i.uv,var_FlowMap,_Tiling,jump,time,true);
                float3 uv2 = FlowUVW(i.uv,var_FlowMap,_Tiling,jump,time,false);

                half3 var_Normal1 = UnpackNormalWithScale(tex2D(_NormalMap,uv1.xy),_NormalScale) * uv1.z;
                half3 var_Normal2 = UnpackNormalWithScale(tex2D(_NormalMap,uv2.xy),_NormalScale) * uv2.z;
                half3 NDir = normalize(var_Normal1+var_Normal2);

                fixed NdotL = saturate(dot(NDir,LdirTS)) * 0.5f + 0.5f;
                fixed3 halfWay = normalize(VdirTS+LdirTS);
                fixed NdotH = saturate(dot(NDir,halfWay));
                
                half4 var_MainTex1 = tex2D(_MainTex,uv1.xy) * uv1.z;
                half4 var_MainTex2 = tex2D(_MainTex,uv2.xy) * uv2.z;
                
                fixed3 diffuse = (var_MainTex1.rgb+var_MainTex2.rgb) * _Color.rgb * NdotL;
                fixed3 specular = _LightColor0.rgb * pow(NdotH,_Gloss); 
                fixed3 finalColor = diffuse+specular;
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
}
