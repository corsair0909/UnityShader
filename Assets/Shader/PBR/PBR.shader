Shader "Unlit/PBR"
{
    Properties
    {
        _Tint ("LightColor",color) = (1,1,1,1)
        _MainTex ("Albedo", 2D) = "white" {}
        _NormalTex ("Normal",2D) = "white"{}
        _AO ("AO",2D) = "white"{} 
        _MetallicTex ("Metallic",2D) = "white"{}
        //_Metal("Metal",range(0,1)) = 0 
        _LUT ("LUT",2D) = "white"{}
        _Roughness ("Roughness",range(0,1)) = 0.2
        _BumpScale ("BumpScale",range(0,1)) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _NormalTex;
            sampler2D _MainTex;
            sampler2D _AO;
            sampler2D _MetallicTex;
            sampler2D _LUT;
            
            
            fixed _Roughness;
            fixed _BumpScale;
            
            fixed4 _Tint;
            
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
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            fixed4 BaseColor(fixed4 albedo,fixed4 LightCol,fixed NdotL)
            {
                return albedo * LightCol * NdotL;
            }
            fixed3 FresnelSchlick(fixed roughness,float F0,fixed VdotH)
            {
                return F0 + (max(float3(1-roughness,1-roughness,1-roughness),F0)-F0)* pow((1-VdotH),5);
            }
            fixed Disney(fixed VdotH,fixed NdotL,fixed NdotV,fixed roughness)
            {
                fixed LdotH2 = VdotH * VdotH;
                fixed Fd90 = 0.5 + 2 * LdotH2 * roughness;
                fixed CosNdotL = Pow5(1-NdotL);
                fixed CosNdotV = Pow5(1-NdotV);
                fixed fresnel = (1+(Fd90-1)*CosNdotL) * (1+(Fd90-1)*CosNdotV);
                return fresnel;
            }
            
            float3 Kd(float3 Flast, float Metallic)
            {
                //??????????????????????????????Ks??????????????? = 1-Ks??????????????????
                //1-???????????? ??????????????????
                 return (1 - Flast) * (1 - Metallic);
            }
            
            //??????????????????
            fixed D (fixed NdotH,fixed roughness)
            {
                fixed alpha2 = roughness * roughness;
                fixed NdotH2 = pow(NdotH,2);
                fixed denom = UNITY_PI * pow((NdotH2*(alpha2-1)+1),2);
                denom = max(denom, 0.0000001); //???????????????0
                return alpha2/denom;
            }
            //??????????????????
            fixed G (fixed NdotV,fixed roughness)
            {
                fixed K = pow(roughness+1,2)/8;
                fixed denom = NdotV*(1-K)+1;
                return NdotV/denom;
            }
            fixed GeometrySmith(fixed NdotV,fixed NdotL,fixed roughness )
            {
                //????????????????????????????????????????????????????????????
                //G = Gsub(n,v,k) * Gsub(n,l,k)
                fixed Gsub1 = G(NdotV,roughness);
                fixed Gsub2 = G(NdotL,roughness);
                return Gsub1 * Gsub2;
            }
            
            fixed F(fixed F0,fixed VdotH)
            {
                fixed Pow5 = pow((1-VdotH),5);
                return lerp(Pow5,1,F0);
            }

            fixed3 Specular(fixed d,fixed g,fixed f,fixed NdotV,fixed NdotL)
            {
                return (d*g*f) / 4*NdotV*NdotL;
            }

            fixed3 IBL_Diffuse_SH(float albedo,fixed3 Normal, float kd)
            {
                fixed3 ambient_contrib = ShadeSH9(float4(Normal,1));//???????????????????????????
                fixed3 ambient =  0.03f * albedo;//ambient???IBL??????????????????
                fixed3 ibldiffuse = max(half3(0,0,0),ambient.rgb+ambient_contrib);
                return ibldiffuse * albedo *kd;
            }
            //IBL????????????????????????????????????
            // fixed3 IBL_Diffuse_CubeMap(float albedo,fixed3 Normal,fixed Kd)
            // {
            //     fixed3 var_Cubemap = texCUBE(_Cubemap,Normal).rgb;
            //     return var_Cubemap * albedo * Kd;
            // }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex));
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 var_MainTex = tex2D(_MainTex,i.uv);
                fixed var_AO = tex2D(_AO,i.uv).r;
                fixed var_Metallic = tex2D(_MetallicTex,i.uv).r;
                fixed4 var_Normal = tex2D(_NormalTex,i.uv);


                fixed3 Normal = UnpackNormal(var_Normal);//Normal?????????????????????????????????????????????????????????
                Normal.xy *=  _BumpScale;
                Normal.z = sqrt(1-saturate(dot(Normal.xy,Normal.xy)));

                fixed3 LightDir = normalize(i.lightDir);
                fixed3 ViewDir = normalize(i.viewDir);

                fixed NdotL = saturate(dot(Normal,LightDir));//?????????????????????
                fixed NdotV = saturate(dot(Normal,ViewDir));
                fixed3 halfway = normalize(LightDir+ViewDir);
                fixed VdotH = saturate(dot(ViewDir,halfway));
                fixed NdotH = saturate(dot(Normal,halfway));
                fixed LdotH = saturate(dot(LightDir,halfway));
                fixed3 F0 = fixed3(0.04f,0.04f,0.04f);
                F0 = lerp(F0,var_MainTex.rgb,var_Metallic);


                fixed d = D(NdotH,_Roughness);
                fixed g = GeometrySmith(NdotV,NdotL,_Roughness);
                fixed f = F(F0,VdotH);
                
                
                fixed4 BaseCol = BaseColor(var_MainTex,_Tint,NdotH);
                fixed3 Fresnela = FresnelSchlick(_Roughness,F0,VdotH);
                fixed3 kd = Kd(Fresnela,var_Metallic);
                fixed3 FresnelaNV = FresnelSchlick(_Roughness,F0,NdotV);
                fixed3 kd_NV = Kd(FresnelaNV,var_Metallic);
                
                //fixed3 Diffuse = BaseCol * kd;// Cook-Torrance BRDF
                
                //fixed3 Diffuse = BaseCol * DisneyDiffuse(NdotV,NdotL,LdotH,_Roughness); unity?????????Disney?????????????????????
                
                fixed3 Diffuse = BaseCol * Disney(VdotH,NdotL,NdotV,_Roughness);//?????????Disney?????????
                fixed3 Specularcol = Specular(d,g,f,NdotV,NdotL);

                //IBL???LUT?????????????????????N???V?????????????????????
                float2 LUTLerp = float2(lerp(0,0.99,NdotV),lerp(0,0.99,_Roughness));
                fixed4 var_LUT = tex2D(_LUT,LUTLerp);
                
                //IBL???????????????
                //shadeSH9 ????????????
                //?????????Kd?????????NdotV???kd
                //???????????????????????????Kd???VdotH????????????????????????????????????????????????????????????????????????????????????H??????????????????
                //?????????????????????????????????????????????????????????????????????
                fixed3 iblDiffuse = IBL_Diffuse_SH(var_MainTex,Normal,kd_NV) ;
                //IBL??????????????????
                //???????????????????????????????????????
                //???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
                //???????????????????????????????????????????????????????????????????????????Unity????????????
                float mip_roughness = _Roughness * (1.7 - 0.7 * _Roughness);
                float3 reflectVec = reflect(-ViewDir,Normal);
                half mip = mip_roughness * 10 ;//??????????????????
                half4 var_Env = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflectVec,mip);
                fixed3 iblSpcular = DecodeHDR(var_Env,unity_SpecCube0_HDR)*(kd_NV * var_LUT.r + var_LUT.g);
                
                fixed3 inDirectLight = (iblDiffuse + iblSpcular) * var_AO;
                fixed3 directorLight = ( Diffuse  + Specularcol) * NdotL * _Tint.rgb * _LightColor0.rgb;
                
                return fixed4(directorLight + inDirectLight ,1);
            }
            ENDCG
        }
    }
}
