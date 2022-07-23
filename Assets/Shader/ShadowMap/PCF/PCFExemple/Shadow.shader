Shader "Custom/Receiver"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 shadowCoord : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            uniform float4x4 _gWorldToLightCamera;//当前片段从世界坐标转换到光源相机空间坐标的变换矩阵
            uniform sampler2D _gShadowMapTexture;
            uniform float4 _gShadowMapTexture_TexelSize;
            uniform float _gShadowStrength;
            uniform float _gShadowBias;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float4 worldPos=mul(unity_ObjectToWorld,v.vertex);
                o.shadowCoord=mul(_gWorldToLightCamera,worldPos);//将顶点坐标变换到光源相机空间
                return o;
            }
            //对附近像素多次采样求平均（均值滤波）来实现阴影边缘抗锯齿
            float PCFSample(float depth,float2 uv)
            {
                float shadow=0.0;
                for(int x=-1;x<=1;++x)
                {
                    for(int y=-1;y<=1;++y)
                    {
                        float4 col=tex2D(_gShadowMapTexture,uv+float2(x,y)*_gShadowMapTexture_TexelSize.xy);
                        float sampleDepth=DecodeFloatRGBA(col);
                        shadow+=(sampleDepth+_gShadowBias)<depth?_gShadowStrength : 1 ;
                    }
                }
                return shadow/9;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                //计算当前片段在光源空间的深度
                i.shadowCoord.xy=i.shadowCoord.xy/i.shadowCoord.w;
                float2 uv=i.shadowCoord.xy;
                uv=uv*0.5 + 0.5; //(-1,1) → (0,1)

                float depth = i.shadowCoord.z / i.shadowCoord.w; //当前片段在光源空间的深度
                #if defined(SHADER_TARGET_GLSL)
                    depth = depth*0.5 + 0.5;    //(-1,1) → (0,1)
                #elif defined(UNITY_REVERSED_Z)
                    depth = 1 - depth;      //(1,0) → (0,1)
                #endif

                //将计算的深度与采样阴影贴图得到的深度比较
                //sample depth Texture;
                //float4 col=tex2D(_gShadowMapTexture,uv);
                //float sampleDepth=DecodeFloatRGBA(col);
                //float shadow= sampleDepth<depth?_gShadowStrength : 1 ;

                //soft shadow
                float shadow=PCFSample(depth,uv);
                return shadow;
            }
            ENDCG
        }
    }
}