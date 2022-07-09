Shader "Unlit/PBRExample"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}

        _Emissive("Emissive", 2D) = "white" {}
        [HDR]_EmissiveColor("EmissiveColor",Color)=(1, 1, 1, 1)

        [Gamma]_Roughness("Roughness", Range(0.0, 1.0)) = 0.0
        _Roughness("Roughness", 2D) = "white" {}
        _RoughnessFactor("RoughnessFactor", Range(0.2, 2)) = 1.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        _AO("AO", 2D) = "white" {}

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        [NoScaleOffset]_LUT("LUT", 2D) = "white" {}

        _Color("Color",Color)=(1, 1, 1, 1)
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque"}
        LOD 300

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        //D 法线分布函数GGX
        float D(float NdotH, float Roughness)
        {
            float alpha_2 = pow(lerp(0.002, 1, Roughness), 2);
            float NdotH_2 = pow(saturate(NdotH), 2);
            float deno = UNITY_PI * pow((NdotH_2 * (alpha_2 - 1) + 1), 2);
            
            return  alpha_2 / deno;
        }

        //F 菲涅尔近似方程 Fresnel-Schlick
        float F(float VdotH, float3 F0)
        {
            half t = Pow5 (1 - VdotH);
            return lerp(t, 1, F0);
        }

        //G 几何函数 GeometrySchlickGGX
        float G(float NdotV, float NdotL, float Roughness)
        {
            //float k = pow(Roughness+1, 2) / 8;
            float k = pow(Roughness, 2) / 2;
            float g_sub1 = NdotV / (NdotV * (1 - k) + k);
            float g_sub2 = NdotL / (NdotL * (1 - k) + k);

            return g_sub1 * g_sub2;
        }

        //高光反射
        float3 Specular(float D, float F, float G, float NdotV, float NdotL)
        {
            return (D * F * G) / (4 * NdotL * NdotV + 0.000001);//防除0
        }

        //Lambert漫反射
        float3 Diffuse(float NdotH, float3 Albedo, float Tint)
        {
            return Albedo * Tint * NdotH ;
        }

        //菲涅尔近似方程 Fresnel-Schlick
        float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
        {
            return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
        }

        //漫反射系数
        float3 Kd(float3 Flast, float Metallic)
        {
            return (1 - Flast) * (1 - Metallic);
        }

        //间接光漫反射
        float3 IBL_Diffse(float Albedo, float3 Ndir, float Kd)
        {
            //球谐
            half3 ambient_contrib = ShadeSH9(float4(Ndir, 1));
            float3 ambient = 0.03 * Albedo;
            float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);

            return  iblDiffuse * Albedo * Kd;
        }
        
        ENDCG

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM

            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityStandardBRDF.cginc" 

            struct appdata
            {
                float4 vertex       : POSITION;
                float3 normal       : NORMAL;
                float2 uv           : TEXCOORD0;
                float4 tangent      :TANGENT;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;               
                float3 lightDir     : TEXCOORD1;
                float3 viewDir      : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _Emissive;
            sampler2D _Emissive_ST;
            float4 _EmissiveColor;

            sampler2D _Roughness;
            sampler2D _Roughness_ST;
            float _RoughnessFactor;
            sampler2D _MetallicGlossMap;
            sampler2D _MetallicGlossMap_ST;
            sampler2D _AO;
            sampler2D _AO_ST;
            
            float _BumpScale;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;

            sampler2D _LUT;
            fixed4 _Color;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                TANGENT_SPACE_ROTATION;//省写TBN真好用(
                o.lightDir=mul(rotation,ObjSpaceLightDir(v.vertex).xyz);
                o.viewDir=mul(rotation,ObjSpaceViewDir(v.vertex).xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //准备数据
                float4 albedo = tex2D(_MainTex,i.uv) * _Color;                                  //颜色
                float4 packNormal = tex2D(_BumpMap,i.uv);                                       //法线
                float metallic = tex2D(_MetallicGlossMap,i.uv).r;                               //金属
                float roughness = tex2D(_Roughness,i.uv).r * _RoughnessFactor;                  //粗糙
                float ao = tex2D(_AO,i.uv).r;                                                   //环境光遮蔽
                float4 emissive = tex2D(_Emissive,i.uv).r;                                        //自发光
                
                float3 nDir = UnpackNormal(packNormal);
                nDir.xy *= _BumpScale;
                nDir.z = sqrt(1 - saturate(dot(nDir.xy,nDir.xy)));                              //法线转切线空间
                float3 lDir = normalize(i.lightDir);
                float3 vDir=normalize(i.viewDir);
                float3 hDir=normalize(lDir+vDir);    

                //准备中间数据1
                float NdotH = saturate(dot(nDir,hDir));
                float VdotH = saturate(dot(vDir,hDir));
                float NdotV = saturate(dot(nDir,vDir));
                float NdotL = saturate(dot(nDir,lDir));
                //准备中间数据2
                float3 F0 = float3(0.04, 0.04, 0.04);
                F0=lerp(F0, albedo.rgb, metallic);
                float3 Flast_VH = fresnelSchlickRoughness(max(VdotH, 0.0), F0, roughness);     //微观
                float3 Flast_NV = fresnelSchlickRoughness(max(NdotV, 0.0), F0, roughness);     //宏观
                float kd_VH = Kd(Flast_VH, metallic);
                float kd_NV = Kd(Flast_VH, metallic);
                float d = D(NdotH, roughness);
                float f = F(VdotH, F0);
                float g = G(NdotV, NdotL, roughness);
                
                float2 LUT_lerp = float2( lerp(0, 0.99, NdotV), lerp(0, 0.99, roughness) );
                float2 envBDRF = tex2D(_LUT,  LUT_lerp).rg; // LUT采样
                //计算
                float3 diffuse = Diffuse(NdotH, albedo.rgb, _Color);
                float3 specular = Specular(d, f, g, NdotV, NdotL);
                diffuse = diffuse * kd_VH;
                specular = specular * _Color * NdotL * UNITY_PI;
                float3 DirectLight = diffuse + specular;

                float3 ibl_Diffse = IBL_Diffse(albedo, nDir, kd_NV);
                
                //这部分为ibl_specular-----------------------
                float mip_roughness = roughness * (1.7 - 0.7 * roughness);
                float3 reflectVec = reflect(-vDir, nDir);
                half mip = mip_roughness * 6;
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip);
                float3 ibl_Specular = DecodeHDR(rgbm, unity_SpecCube0_HDR) * (Flast_NV * envBDRF.r + envBDRF.g);
                //--------------------------------------------

                float3 inDirectLight = (ibl_Diffse + ibl_Specular) * ao;
                
                return float4(DirectLight + inDirectLight + emissive * _EmissiveColor, 1);
            }
            ENDCG
        }
    }
}
