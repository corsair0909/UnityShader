Shader "Unlit/HDR LDR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SkyBox ("skybox",Cube) = "white"{}
        _mip ("mip",range(0,10)) = 0.02
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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 Normal : TEXCOORD1;
                float3 ViewDir : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _SkyBox;
            fixed _mip;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.Normal = UnityObjectToWorldNormal(v.normal);
                float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.ViewDir = _WorldSpaceCameraPos.xyz - worldPos.xyz;
                o.lightDir = _WorldSpaceLightPos0.xyz - worldPos.xyz;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDirWS = normalize(i.Normal);
                float3 lDirWS = normalize(i.lightDir);
                float3 vDirWS = normalize(i.ViewDir);

                float ndotl = saturate(dot(nDirWS,lDirWS)) * 0.5f + 0.5;

                float3 Rdir = reflect(-vDirWS,nDirWS);

                
                //fixed mip = _Roughness * 1.7 - 0.7 * _Roughness;
                float3 var_SkyBox = texCUBElod(_SkyBox,float4(Rdir,_mip));
                return float4(var_SkyBox,1);
            }
            ENDCG
        }
    }
}
