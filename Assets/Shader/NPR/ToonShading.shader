Shader "Unlit/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint ("Color",color) = (1,1,1,1)
        _Spec ("SpecColor",color) = (1,1,1,1)
        _Gloss("Gloss",range(30,90)) = 50
        
        _LineColor("LineColor",color) = (0,0,0,0)
        _LineWidth("LineWidth",float) = 0.1
        _LineNoiseOffset("LineNoiseOffset",vector) = (0,0,0,0)
        
        _Dividline("divid",float) = 1

    }
    SubShader
    {
        
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4 _Tint;
            half4 _Spec;

            fixed _Gloss;
            fixed _Dividline;
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.NDirWS = mul(unity_ObjectToWorld,v.normal).xyz;
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.NDirWS);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                
                fixed4 var_MainTex = tex2D(_MainTex,i.uv);
                
                fixed3 halfDir = normalize(viewDir+LightDir);
                fixed NdotL =  saturate(dot(LightDir,worldNormal));
                fixed NdotH = saturate(dot(halfDir,worldNormal));
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Tint.rgb;
                fixed3 diffuse = _LightColor0.xyz * _Tint.rgb *var_MainTex.rgb * NdotL;
                // fixed3 specualr = _LightColor0.xyz * pow(NdotH,_Gloss);
               //return fixed4(ambient+diffuse+specualr,1.0);
                return fixed4(diffuse+ambient,1);
            }
            ENDCG
        }
        
        Pass
        {
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
