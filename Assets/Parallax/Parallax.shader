Shader "Unlit/Parallax"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex ("Normal", 2D) = "white" {}
        _Height ("Parallax", 2D) = "white" {}
        _AO ("Ao", 2D) = "white" {}
        _Roughness ("Roughness", 2D) = "white" {}
        _BumpScale ("BumpScale",range(0.2,8)) = 0.2
        _AOFactor ("AOFactor",range(0,2)) = 0
        _RoughnessFactor ("RoughnessFactor",range(0.04,1)) = 0.04 
        _ParallaxFactor ("Parallax",range(0,1)) = 0.2
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
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 uv2 : TEXCOORD1;
                float3 VDirTS : TEXCOORD2;
                float3 LdirTS : TEXCOORD3;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            sampler2D _Height;
            float4 _Height_ST;
            sampler2D _AO;
            float4 _AO_ST;
            sampler2D _Roughness;
            float4 _Roughness_ST;

            fixed _BumpScale;
            fixed _AOFactor;
            fixed _RoughnessFactor;
            fixed _ParallaxFactor;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_ROTATION;
                o.VDirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                o.LdirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                return o;
            }

            //普通视差映射
            fixed2 ApplyParallax(float3 Vdir,fixed Scale,float2 uv)
            {
                fixed Height =  tex2D(_Height,uv);
                float2 offset = Vdir.xy/Vdir.z * Height * Scale;
                return offset;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 LdirTS = normalize(i.LdirTS);
                fixed3 VdirTS = normalize(i.VDirTS);
                fixed3 HdirTS = normalize(LdirTS+VdirTS);
                
                fixed2 offset = ApplyParallax(VdirTS,_ParallaxFactor,i.uv);
                i.uv += offset;
                fixed3 Var_Normal = UnpackNormalWithScale(tex2D(_NormalTex,i.uv),_BumpScale);
                fixed Var_AO = tex2D(_AO,i.uv).r *_AOFactor;
                fixed Var_Roughness = tex2D(_Roughness,i.uv).r * _RoughnessFactor;
                fixed4 col = tex2D(_MainTex, i.uv);
                


                fixed NdotL = saturate(dot(Var_Normal,LdirTS)) *0.5 + 0.5 ;
                fixed NdotV = saturate(dot(Var_Normal,VdirTS));
                fixed LdotH = saturate(dot(LdirTS,HdirTS));

                
                fixed Fresnel = DisneyDiffuse(NdotV,NdotL,LdotH,Var_Roughness) ;
                fixed3 diffuse = (_LightColor0.rgb *  col.rgb * NdotL) * Fresnel * Var_AO;
                return fixed4(diffuse,1);
            }
            ENDCG
        }
    }
}
