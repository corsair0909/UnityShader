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
                float2 uv       : TEXCOORD0;
                float4 vertex   : SV_POSITION;
                float3 VDirTS  : TEXCOORD1;
                float3 LdirTS   : TEXCOORD2;
                float3 NdirWS   : TEXCOORD3;
                float3 TdirWS   : TEXCOORD4;
                float3 BTdirWS  : TEXCOORD5;
                float4 WorldPos : TEXCOORD6;
           
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
                
                //可以少算一个TBN矩阵
                 TANGENT_SPACE_ROTATION;
                // o.NdirWS = normalize(UnityObjectToWorldNormal(v.normal));
                // o.TdirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,1)*v.tangent.w).xyz);
                // o.BTdirWS = normalize(cross(o.NdirWS,o.TdirWS));
                 o.VDirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                 o.LdirTS = mul(rotation,ObjSpaceLightDir(v.vertex));
                return o;
            }

            //普通视差映射
            fixed2 ApplyParallax(float3 Vdir,fixed Scale,float2 uv)
            {
                fixed Height =  tex2D(_Height,uv);
                Height -= 0.5f;//低点不懂高点增高，减去一个值抵消这种影响
                //标准着色器为了防止极端观察角度导致的失真会增加一个偏移量
                float2 offset = Vdir.xy/(Vdir.z+0.42) * Height * Scale;
                return offset;
            }
            fixed2 StepParallax(float2 uv,float3 vdir,fixed scale)
            {
                fixed numLayer = 20;
                fixed LayerDepth = 1/numLayer;
                fixed CurrentLayerDepth = 0.0f;
                fixed2 CurrentTexcoord  = vdir.xy / vdir.z * scale;
                fixed2 Step = CurrentTexcoord/numLayer;
                float2 currentUV = uv;
                fixed CurrentMapDepth = tex2D(_Height,currentUV).r;
                for (int i = 0; i < numLayer; i++)
                {
                    if (CurrentLayerDepth>CurrentMapDepth)
                    {
                        return CurrentTexcoord;
                    }
                    CurrentTexcoord += Step;
                    //从原本uv进行偏移
                    CurrentMapDepth = tex2D(_Height,currentUV+CurrentTexcoord).r;
                    CurrentLayerDepth+=LayerDepth;
                }
                return CurrentTexcoord;
            }
            fixed2 RelieParallax(float3 vdir,fixed scale,float2 uv)
            {
                fixed numLayer = 20;
                fixed LayerDepth = 1/numLayer;
                fixed CurrentLayerDepth = 0.0f;
                fixed2 CurrentTexcoord  = vdir.xy / vdir.z * scale;
                
                fixed LayerUVL = length(CurrentTexcoord);
                
                fixed2 Step = CurrentTexcoord/numLayer;
                fixed CurrentMapDepth = tex2D(_Height,CurrentTexcoord).r;
                for (int i = 0; i < numLayer; i++)
                {
                    if (CurrentLayerDepth>CurrentMapDepth)
                    {
                        break;
                    }
                    CurrentTexcoord += Step;
                    CurrentMapDepth = tex2D(_Height,uv+CurrentTexcoord).r;
                    CurrentLayerDepth+=LayerDepth;
                }

                //浮雕映射部分
                //T1 = 表面下方的第一个点
                //从表面下方第一个点到视线交点之间二分查找
                float2 T1 = uv + CurrentTexcoord;
                float2 T0 = T1 - Step;

                //优化方法，来自catlikecode
                // fixed PervHeight = tex2D(_Height,T1).r;
                // fixed Height = tex2D(_Height,T0).r;
                // fixed Pervdepth = CurrentLayerDepth - LayerDepth;
                // fixed depth1 = Pervdepth-PervHeight;
                // fixed depth2 = Height - CurrentLayerDepth;
                // float t = depth1 / (depth1+depth2);
                // return lerp(T1,T0,t);
                
                for (int j = 0;j<20;j++)
                {
                    float2 P0 = (T0 + T1) / 2;
                
                    float P0Height = tex2D(_Height, P0).r;
                
                    float P0LayerHeight = length(P0) / LayerUVL;
                
                    if (P0Height < P0LayerHeight)
                    {
                        T0 = P0;
                
                    }
                    else
                    {
                        T1= P0;
                    }
                
                }
                
                return (T0 + T1) / 2 - uv;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                //float3x3 TBN = float3x3(i.TdirWS,i.BTdirWS,i.NdirWS);
                
                fixed3 LdirTS = normalize(i.LdirTS);
                fixed3 VdirTS = normalize(i.VDirTS);
                fixed3 HdirTS = normalize(LdirTS+VdirTS);
                
                // fixed2 offset = StepParallax(i.uv,VdirTS,_ParallaxFactor);
                // i.uv += offset;
                // fixed2 offset = StepParallax(VdirTS,_ParallaxFactor);
                // i.uv += offset;
                fixed2 offset = RelieParallax(VdirTS,_ParallaxFactor,i.uv);
                i.uv += offset;
                fixed3 Var_Normal = UnpackNormalWithScale(tex2D(_NormalTex,i.uv),_BumpScale);
                fixed Var_AO = tex2D(_AO,i.uv).r *_AOFactor;
                fixed Var_Roughness = tex2D(_Roughness,i.uv).r * _RoughnessFactor;
                fixed4 col = tex2D(_MainTex, i.uv);

                //fixed3 NdirWS = mul(Var_Normal,TBN);


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
