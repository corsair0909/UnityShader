Shader "Unlit/Reflect"
{
    Properties
    {
        _SkyBox("SkyBox", Cube) = "white" {}
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

            samplerCUBE _SkyBox;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 NDir : TEXCOORD1;
                float4 WorldPos : TEXCOORD2;
                float3 VRDir : TEXCOORD3;
            };
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.NDir = UnityObjectToWorldNormal(v.normal);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                float3 VDir = UnityObjectToViewPos(o.WorldPos).xyz;
                o.VRDir = reflect(-VDir,o.NDir);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return texCUBE(_SkyBox,i.VRDir);
            }
            ENDCG
        }
    }
}
