Shader "Unlit/PBR"
{
    Properties
    {
        _Tint ("LightColor",color) = (1,1,1,1)
        _MainTex ("Albedo", 2D) = "white" {}
        _NormalTex ("Normal",2D) = "white"{}
        _AO ("AO",2D) = "white"{} 
        _MetallicTex ("Metallic",2D) = "white"{}
        _LUT ("LUT",2D) = "white"{}
        _Roughness ("Roughness",range(0,2)) = 0.2
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
                //金属度决定镜面反射项Ks，漫反射项 = 1-Ks（能量守恒）
                //1-菲涅尔项 为了能量守恒
                 return (1 - Flast) * (1 - Metallic);
            }
            
            //法线分布函数
            fixed D (fixed NdotH,fixed roughness)
            {
                fixed alpha2 = roughness * roughness;
                fixed NdotH2 = pow(NdotH,2);
                fixed denom = UNITY_PI * pow((NdotH2*(alpha2-1)+1),2);
                denom = max(denom, 0.0000001); //防止分母为0
                return alpha2/denom;
            }
            //几何分布函数
            fixed G (fixed NdotV,fixed roughness)
            {
                fixed K = pow(roughness+1,2)/8;
                fixed denom = NdotV*(1-K)+1;
                return NdotV/denom;
            }
            fixed GeometrySmith(fixed NdotV,fixed NdotL,fixed roughness )
            {
                //同时考虑到观察方向和光照方向的几何分布，
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

            fixed3 IBL_Diffuse(float albedo,fixed3 Normal, float kd)
            {
                fixed3 ambient_contrib = ShadeSH9(float4(Normal,1));//球谐函数计算的光照
                fixed3 ambient =  albedo;
                fixed3 ibldiffuse = max(half3(0,0,0),ambient.rgb+ambient_contrib);
                return ibldiffuse * albedo *kd;
                
            }
            
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


                fixed3 Normal = UnpackNormal(var_Normal);//Normal变量还在切线空间下，需要映射之后才能用
                Normal.xy *=  _BumpScale;
                Normal.z = sqrt(1-saturate(dot(Normal.xy,Normal.xy)));

                fixed3 LightDir = normalize(i.lightDir);
                fixed3 ViewDir = normalize(i.viewDir);

                fixed NdotL = saturate(dot(Normal,LightDir));//切线空间下运算
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
                
                //fixed3 Diffuse = BaseCol * kd;// Cook-Torrance BRDF
                
                //fixed3 Diffuse = BaseCol * DisneyDiffuse(NdotV,NdotL,LdotH,_Roughness); unity内置的Disney漫反射计算公式
                
                fixed3 Diffuse = BaseCol * Disney(VdotH,NdotL,NdotV,_Roughness);//自定义Disney漫反射


                
                fixed3 Specularcol = Specular(d,g,f,NdotV,NdotL);

                //IBL，LUT图的采样取决于N、V的点积和粗糙度
                float2 LUTLerp = float2(lerp(0,0.99,NdotV),lerp(0,0.99,_Roughness));
                fixed4 var_LUT = tex2D(_LUT,LUTLerp);
                
                //IBL漫反射部分
                //shadeSH9 函数计算
                fixed3 iblDiffuse = IBL_Diffuse(var_MainTex,Normal,kd);
                //IBL镜面反射部分
                //可以理解为对天空盒进行采样
                //我们使用一个环境贴图级数来对环境贴图采样，粗糙度越大反射则越模糊，对应的环境贴图级数越高。
                //下面的式子表示级数和粗糙度并非线性关系，转换公式在Unity中有定义
                float mip_roughness = _Roughness * (1.7 - 0.7 * _Roughness);
                float3 reflectVec = reflect(-ViewDir,Normal);
                half mip = mip_roughness * 6;//环境贴图级数
                half4 var_Env = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflectVec,mip);
                fixed3 iblSpcular = DecodeHDR(var_Env,unity_SpecCube0_HDR)*(Fresnela * var_LUT.r + var_LUT.g);

                fixed3 inDirectLight = (iblDiffuse + iblSpcular) * var_AO;
                
                fixed3 directorLight = ( Diffuse  + Specularcol) * NdotL * _Tint.rgb;


                
                return fixed4(directorLight +inDirectLight ,1);
            }
            ENDCG
        }
    }
}
