Shader "Unlit/ShadowReceiver"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint ("Color",color) = (1,1,1,1)
        _Spec ("SpecColor",color) = (1,1,1,1)
        _Gloss("Gloss",range(30,90)) = 50
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
                float2 uv               : TEXCOORD0;
                float4 vertex           : SV_POSITION;
                float3 NDirWS           : TEXCOORD1;
                float4 WorldPos         : TEXCOORD2;
                float4 DepthTexcoord    : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Tint;
            half4 _Spec;
            fixed _Gloss;
            
            sampler2D _gShadowMapTexture;
            float4 _gShadowMapTexture_TexelSize;
            fixed _ShadowStrange;
            fixed _CutOff;
            fixed4x4 _gWorldToLdirCameraMatrix;
            fixed _ShadowBias;
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.NDirWS = mul(unity_ObjectToWorld,v.normal).xyz;
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);

                //将当前片元从世界空间变换到光源空间
                //o.DepthTexcoord = mul(_gWorldToLdirCameraMatrix,o.WorldPos);
                return o;
            }

            float PCFShadow(float depth , float2 uv)
            {
                float shadow = 0;
                for (int i = -1; i <=1; ++i)
                {
                    for (int j = -1; j <= 1; ++j)
                    {
                        half4 Col = tex2D(_gShadowMapTexture,uv+float2(i,j) * _gShadowMapTexture_TexelSize.xy);
                        fixed sampleDepth = DecodeFloatRGBA(Col);
                        shadow += (sampleDepth+_ShadowBias) < depth ? 1-_ShadowStrange:1;
                    }
                }
                return shadow/=9;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {

                float4 ShadowPos = mul(_gWorldToLdirCameraMatrix,i.WorldPos);
                ShadowPos.xyz = ShadowPos.xyz / ShadowPos.w;
                float3 Pos = ShadowPos * 0.5 + 0.5;
                
                fixed shadow = PCFShadow(ShadowPos.z,Pos.xy);
                return shadow;
            }
            ENDCG
        }
    }
}
