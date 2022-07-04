Shader "Unlit/ParallaxCloud"
{
    Properties
    {
        _Color ("Color",color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal" ,2D) = "white" {}
        _BumpScale ("HeightScale",range(0.2,3)) = 0.2
        _Alpha ("Alpha",range(0,1)) = 0.2
        _StepLayer ("StepLayer",Range(1,100))= 1
        
        
    }
    SubShader
    {
        Tags
         { 
             "IgnoreProjector"="Treu"
             "Queue" = "Transparent-50"
             "RenderType" = "Transparent"
         }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                float2 uv2      : TEXCOORD1;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
            };

            struct v2f
            {
                float2 uv       : TEXCOORD0;
                float2 uv2      : TEXCOORD1;
                float4 vertex   : SV_POSITION;
                float3 VDirTS  : TEXCOORD2;
                float3 LdirTS   : TEXCOORD3;
                float4 WorldPos : TEXCOORD4;
           
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            
            fixed _BumpScale;
            fixed _ParallaxFactor;
            fixed _StepLayer;
            fixed _Alpha;

            fixed4 _Color;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex)+frac(_Time.y * 0.1f);
                o.uv2 = TRANSFORM_TEX(v.uv2, _MainTex);
                //可以少算一个TBN矩阵
                 TANGENT_SPACE_ROTATION;
                o.VDirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                o.LdirTS = mul(rotation,ObjSpaceLightDir(v.vertex));
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {

                
                float3 UV1 = float3(i.uv,0);//动态;
                float3 UV2 = float3(i.uv2,0);//静态
                float3 NdirTS = normalize(UnpackNormalWithScale(tex2D(_NormalMap,UV1),_BumpScale));
                float3 LdirWS  = normalize(i.LdirTS);
                float NdotL = saturate(dot(NdirTS,LdirWS));
                float3 Vdir = normalize(i.VDirTS);
                Vdir.xy *= _BumpScale;
                Vdir.z += 0.42f;
                
                float4 MainTex = tex2D(_MainTex,UV2);    
                float3 Offset = Vdir/(Vdir.z * _StepLayer);
                float Height = tex2D(_MainTex,UV1).r * MainTex.r;
                 //计算视差部分
                fixed3 prev_uv = UV1;
                fixed3 prev_height = Height;
                 [unroll(40)]
                 while (Height>UV1.z)
                 {
                     prev_uv = UV1;
                     prev_height = Height;
                     UV1 += Offset;
                     Height = tex2D(_MainTex,UV1).r * MainTex.r;
                 }
                
                 float d1 = Height - UV1.z;
                 float d2 = prev_height - prev_uv.z;
                 float w = d1 / (d1 - d2 + 0.0000001);
                 UV1 = lerp(UV1,prev_uv,w);
                 fixed4 result = tex2D(_MainTex,UV1) * MainTex * _Color;
                 fixed3 finalColor = result.rgb * (NdotL*_LightColor0.rgb + 1.0);
                
                fixed alpha = _Alpha*0.75f + MainTex.r*result.r;
                alpha = smoothstep(_Alpha,alpha,1.0);
                return fixed4(finalColor,alpha);
            }
            ENDCG
        }
    }
}
