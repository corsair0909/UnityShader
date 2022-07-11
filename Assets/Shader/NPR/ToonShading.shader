Shader "Unlit/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("RampTex" ,2D) = "white" {}
        _FaceLightmapTex("FaceLightMap",2D) = "white"{}
        
        [Space(15)]
        _Tint ("LightCol",color) = (1,1,1,1)
        _Threshold("Threshold",float) = 0
        
        [Space(15)]
        _rimMin("RimMin",float) = 0
        _rimMax("RimMax",float) = 0
        _rimSmoothStep("SmoothStep",float) = 0
        _rimColor("RimColor",color) = (1,1,1,1)
        
        [Space(15)]
        _LineColor("LineColor",color) = (0,0,0,0)
        _LineWidth("LineWidth",float) = 0.1
        _LineNoiseOffset("LineNoiseOffset",vector) = (0,0,0,0)
        
        [Space(15)]
        _ClearCoatMult("ClearCoatMult",float) = 0.1
        _ClearCoatCol ("_ClearCoatColor",Color) = (1,1,1,1)
        _ClearCotaGloss("_ClearCotaGloss",range(30,90)) = 50
        
        [Space(15)]
        _LerpMax ("lerp",float) = 0
        _ShadowColor("ShadowColor",color) = (0,0,0,0)
    }
    SubShader
    {
//        Pass
//        {
//            Tags{"LightMode"="ShadowCaster"}
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            #pragma multi_compile_shadowcaster
//            #include "UnityCG.cginc"
//
//            struct v2f
//            {
//                V2F_SHADOW_CASTER;
//            };
//            v2f vert(appdata_base v)
//            {
//                v2f o;
//                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
//                return o;
//            }
//            fixed4 frag(v2f i) : SV_Target
//            {
//                SHADOW_CASTER_FRAGMENT(i);
//            }
//            ENDCG
//        }
        Pass
        {
            Name "Lighting"
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            #pragma shader_feature _Face
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #define SmoothnessAA 0.000002

            struct v2f
            {
                float2 uv      : TEXCOORD0;
                float4 pos  : SV_POSITION;
                float3 NDirWS  : TEXCOORD1;
                float3 TDirWS  : TEXCOORD2;
                float3 BTDirWS : TEXCOORD3;
                float4 WorldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _RampTex;
            sampler2D _FaceLightmapTex;

            half4 _Tint;
            half4 _rimColor;
            half4 _ClearCoatCol;
            half4 _ShadowColor;
            
            fixed _rimMin;
            fixed _rimMax;
            fixed _rimSmoothStep;
            fixed _Threshold;
            fixed _ClearCoatMult;
            fixed _ClearCotaGloss;
            fixed _LerpMax;
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.NDirWS = mul(unity_ObjectToWorld,v.normal).xyz;
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.NDirWS);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                
                fixed4 var_MainTex = tex2D(_MainTex,i.uv) * _Tint;
                
                fixed3 halfDir = normalize(viewDir+LightDir);
                fixed NdotH = saturate(dot(halfDir,worldNormal));
                fixed NdotL =  saturate(dot(LightDir,worldNormal)) * 0.5f+0.5f;
                fixed VdotN = saturate(dot(viewDir,worldNormal));

                //SDF面部阴影计算
                fixed4 var_face1 = tex2D(_FaceLightmapTex,i.uv);
                fixed4 var_face2 = tex2D(_FaceLightmapTex,float2(1-i.uv.x,i.uv.y));
                float2 Left = normalize(mul(unity_ObjectToWorld,float3(1, 0, 0))).xy;	//世界空间角色正左侧方向向量
                float2 Front = normalize(mul(unity_ObjectToWorld,float3(1, 0, 0))).xy;
                float ctrl = 1-clamp(0,1,dot(Front,LightDir)*0.5f+0.5f);
                float ilm = dot(LightDir, Left) > 0 ? var_face1.r : var_face2.r;
                float isSahdow = step(ilm, ctrl);
                fixed bias = smoothstep(0, _LerpMax, abs(ctrl - ilm));//平滑边界，smoothstep的原理和用法可以参考我上一篇文章
                
                
                fixed4 var_RampTex = tex2D(_RampTex,float2(NdotL,0.5f));
                fixed r = 1 - VdotN;
                half rim = smoothstep(_rimMin,_rimMax,r);
                rim = smoothstep(0,_rimSmoothStep,rim);
                fixed4 rimCol = rim * _rimColor;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Tint.rgb;
                fixed3 diffuse =  var_MainTex.rgb * var_RampTex;
                
                if (ctrl > 0.99 || isSahdow == 1)
                {
                    diffuse = lerp(diffuse,diffuse*_ShadowColor.rgb,bias);
                }
                    

                fixed Cota = ((pow(VdotN,_ClearCotaGloss)) > (1 - _Threshold) ? _ClearCoatMult : 0);
                fixed3 clearCoatColor = _ClearCoatCol.rgb * Cota;

                // fixed shadow = SHADOW_ATTENUATION(i);
                
                fixed3 FinalColor = _LightColor0.xyz *(diffuse+clearCoatColor+ambient+rimCol);
                return fixed4(FinalColor,1);

                //return rimCol;

            }
            ENDCG
        }
        
        Pass
        {
            Name "outline"
            Tags{"LightMode"="ForwardBase"}
            Cull Front
            CGPROGRAM
            #pragma vertex outlineVert
            #pragma fragment outlineFrag
            #include "UnityCG.cginc"
            #include "Assets/Shader/MyShaderLabs.cginc"

            half4 _LineColor;
            fixed _LineWidth;
            fixed4 _LineNoiseOffset;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //TODO : 顶点色控制描边颜色/粗细
                float4 vertexColor : COLOR;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 vertexColor : TEXCOORD0;
            };
            v2f outlineVert (a2v v)
            {
                v2f o;
                float4 pos = UnityObjectToClipPos(v.vertex);
                
                //float3 viewNormal = mul(UNITY_MATRIX_IT_MV,v.normal).xyz; 
                //投影变换完成后得到的xy的范围在[-w,w]内。随后管线会将坐标除以w得到[-1,1]（ndc）范围下的坐标，
                //可以理解为如果以参 UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * _OutlineWidth * 0.1 ,1))
                //参与后续计算，结果会被管线除以W分量从而得到不同于指定好的轮廓线宽度，在透视除法之前乘以W分量抵消后续计算的除以W分量的影响
                
                float3 viewNormal = mul(UNITY_MATRIX_IT_MV,v.tangent).xyz;
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal) * pos.w);

                //
                //近裁剪平面右上角变换到投影空间中计算新的宽高比
                float3 nearCilpPanle = mul(unity_CameraInvProjection,float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
                float aspect =abs(nearCilpPanle.y/nearCilpPanle.x);
                //float aspect = _ScreenParams.y/_ScreenParams.x;
                ndcNormal.x *= aspect;

                fixed2 noiseSample = v.uv;
                noiseSample = noiseSample * _LineNoiseOffset.xy+_LineNoiseOffset.zw;
                fixed noiseWidth = perlin_noise(noiseSample);
                noiseWidth *= 2 - 1;

                fixed outlineWidth = _LineWidth+_LineWidth * noiseWidth;
                
                pos.xy += 0.1f * outlineWidth * ndcNormal.xy * v.vertexColor.a;
                o.vertex = pos;
                
                o.vertexColor = v.vertexColor;
                
                return o;
            }
            fixed4 outlineFrag(v2f i): SV_Target
            {
                fixed3 finalColor = _LineColor.rgb * i.vertexColor.rgb;
                return fixed4(finalColor,1.0f);
            }
            ENDCG
        }
    }
}
