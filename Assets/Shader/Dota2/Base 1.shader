Shader "Unlit/Dota2"
{
    Properties
    {
        [Header(MainTexture)]
        _Color ("Color",Color) = (1,1,1,1)
        _MainTex ("MainTex（主贴图）", 2D) = "white" {}
        _NormalScale ("NormalScale",range(0,1.5)) = 0
        _NormalTex("NormalMap（法线贴图）",2D) = "White"{}
        
        //金属度遮罩
        _MetalnessMask("MetalnessMask（金属度遮罩）",2D) = "White"{}
        
        //环境光
        _CubeMap("CubeMap（环境光反射）",cube) = "White"{}
        _EnvInt("EnvInt(环境光强度)",float) = 1
        
        //边缘光遮罩
        _RimMask("RimMask（边缘光遮罩）",2D) = "White"{}
        _RimPower("RimPower(边缘光次幂)",float) = 5
        _RimColor ("RimColor",color) = (1,1,1,1)
        _RimInt("Rimint(边缘光强度)",float) = 1
        
        //自发光遮罩 * 原有色 = 自发光
        _Selfllum("EmissiveMap（自发光遮罩）",2D) = "White"{}
        _SelfInt("SelfInt",float) = 1
        _EmissiveColor ("EmissiveColor",color) = (1,1,1,1)
        
        //透切
        _Translucency("Translucency（透明度贴图）",2D) = "White"{}//透明度
        
        [Speac(5)]
        [Header(Specular)]
        _SpecularMask("SpecularMask（高光遮罩）",2D) = "White"{}//高光遮罩，显示有高光的部分
        _SpecularExponent("SpecularExponent（高光次幂）",2D) = "White"{}//高光次幂
        _TinyMask("TinyMask（高光遮罩）",2D) = "White"{}//高光遮罩，显示有高光的部分
        _SpecularColor ("SpecularColor",color) = (1,1,1,1)
        _SpecularInt ("SpecularInt(高光强度)",float) = 1
        
//        [Space(10)]//细节纹理*细节遮罩纹理 叠加到原有色上
//        [Header(DetailTexture)]
//        _Detail("DetailTex（细节纹理）",2D) = "White"{}
//        _DetailMaks("DetailMask（细节遮罩）",2D) = "White"{}
        
        [Space(10)]
        [Header(rimColor)]
        _WarpCol ("_WarpCol", 2D) = "white" {}
        _WarpRim ("_WarpRim", 2D) = "white" {}
        _WarpSpec ("_WarpSpec）", 2D) = "white" {}
        
        [Space(10)]
        [Header(Environment)]
        _EnvCol("EnvCol(环境光颜色)",color) = (1,1,1,1)
        _EnvDiffInt ("EnvDiffInt(环境漫反射强度)",float) = 1
//        _EnvSpecInt ("EnvSpecInt(环境高光反射强度)",float) = 1
        
        [Space(10)]
        [Header(Environment)]
        _CutOff ("CutOff(透切阈值)",range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float2 uv      : TEXCOORD0;
                float4 vertex  : SV_POSITION;
                float3 NDirWS  : TEXCOORD1;
                float3 TDirWS  : TEXCOORD2;
                float3 BTDirWS : TEXCOORD3;
                float4 WorldPos : TEXCOORD4;
            };

            uniform sampler2D _MainTex;
            uniform sampler2D _NormalTex;
            uniform sampler2D _MetalnessMask;
            uniform sampler2D _SpecularMask;
            uniform sampler2D _SpecularExponent;
            uniform sampler2D _RimMask;
            uniform sampler2D _WarpSpec,_WarpRim;
            uniform samplerCUBE _CubeMap;
            uniform sampler2D _Selfllum;
            uniform sampler2D _Translucency,_TinyMask;
            uniform fixed _NormalScale;
            
            half4 _Color,_SpecularColor,_RimColor,_EnvCol,_EmissiveColor;

            fixed _RimPower,_SpecularInt,_RimInt,_EnvInt,_EnvDiffInt,_EnvSpecInt,_SelfInt;
            fixed _CutOff;
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.NDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.TDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,1)).xyz);
                o.BTDirWS = normalize(cross(o.NDirWS,o.TDirWS)*v.tangent.w);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                fixed3x3 TBN = fixed3x3(i.TDirWS,i.BTDirWS,i.NDirWS);
                fixed3 NdirTS = UnpackNormalWithScale(tex2D(_NormalTex,i.uv),_NormalScale);
                fixed3 LdirWS = normalize(WorldSpaceLightDir(i.WorldPos));
                fixed3 VdirWS = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                fixed3 NdirWS = normalize(mul(NdirTS,TBN));
                fixed3 RdirWS = reflect(-LdirWS,NdirWS);

                fixed NdotL = saturate(dot(NdirWS,LdirWS)) * 0.5f +0.5f;
                fixed3 HalfWay = normalize(LdirWS+VdirWS);
                fixed NdotH = saturate(dot(NdirWS,HalfWay));
                fixed NdotV = saturate(dot(NdirWS,VdirWS));

                half4 var_MainTex = tex2D(_MainTex,i.uv);
                fixed var_Trans = tex2D(_MainTex,i.uv).r;
                fixed var_Metalic = tex2D(_MetalnessMask,i.uv).r;
                fixed var_SpecMask = tex2D(_SpecularMask,i.uv).r;
                fixed var_SpecExp = tex2D(_SpecularExponent,i.uv).r;
                fixed var_RimMask = tex2D(_RimMask,i.uv).r;
                fixed var_Emissive = tex2D(_Selfllum,i.uv).r;
                fixed fresnelSpec = tex2D(_WarpSpec,i.uv).r;
                fixed fresnelRim = tex2D(_WarpRim,i.uv).r;
                fixed TinyMask = tex2D(_TinyMask,i.uv).r;
                fixed Opacity = tex2D(_Translucency,i.uv).r;
                
                half4 var_CubeMap = texCUBElod(_CubeMap,float4(RdirWS,lerp(0.0,8.0,var_SpecMask)));

                half3 diffuseCol = lerp(_Color.rgb,0.01,var_Metalic);
                half3 diffuse = _LightColor0.rgb * var_MainTex.rgb * diffuseCol * NdotL;

                half3 specularCol = lerp(var_MainTex.rgb,_SpecularColor.rgb,TinyMask) * fresnelSpec;
                fixed Billin_Phong = pow(NdotH,var_SpecExp);
                Billin_Phong = max(Billin_Phong,fresnelSpec);
                Billin_Phong *= _SpecularInt;
                half3 Specular = _LightColor0.rgb * specularCol * var_SpecMask * Billin_Phong;

                half rim = 1 - NdotV;
                half3 fresenlInt = pow(rim,_RimPower) * var_RimMask;
                half3 rimLight = fresenlInt * fresnelRim * max(0,NdirWS.g) * _RimColor.rgb * _RimInt;

                half reflectInt = max(fresnelSpec, var_Metalic) * var_SpecMask;
                half3 envSpec = specularCol * reflectInt * var_CubeMap.rgb * _EnvInt;
                half3 envDiffCol = _EnvCol.rgb * diffuseCol * _EnvDiffInt;

                half3 emissive = diffuseCol * var_Emissive * _SelfInt * _EmissiveColor.rgb;

                half3 finalColor = diffuse+Specular+envSpec+envDiffCol+rimLight+emissive;

                clip(Opacity-_CutOff);
                
                return half4(finalColor,var_Trans);
            }
            ENDCG
        }
    }
}
