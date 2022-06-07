Shader "Unlit/Reflect"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
        _SkyBox("SkyBox", Cube) = "white" {}
        _ReflectAmount("Amount",Range(0,1)) = 0
        
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
            #include "Lighting.cginc"
            #include  "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _SkyBox;
            fixed _ReflectAmount;

            struct appdata
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 NDir : TEXCOORD1;
                float4 WorldPos : TEXCOORD2;
                float3 VRDir : TEXCOORD3;
                float2 uv : TEXCOORD4;
                float3 VDir : TEXCOORD5;
            };
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                
                o.NDir = UnityObjectToWorldNormal(v.normal);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                o.VDir = UnityObjectToViewPos(o.WorldPos).xyz;
                o.VRDir = reflect(-o.VDir,o.NDir);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDirWS = normalize(i.NDir);
                float3 vDirWS = normalize(i.VDir);
                float3 lDirWS = normalize(_WorldSpaceLightPos0 - i.WorldPos);

                float4 var_MainTex = tex2D(_MainTex,i.uv);

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float ndotl = saturate(dot(nDirWS,lDirWS));
                float3 diffuse = _LightColor0.rgb * ndotl * var_MainTex.rgb ;

                float3 var_SkyBox = texCUBE(_SkyBox,i.VRDir).rgb;

                
                
                return fixed4((ambient + lerp(diffuse,var_SkyBox,_ReflectAmount)),1);
            }
            ENDCG
        }
    }
}
