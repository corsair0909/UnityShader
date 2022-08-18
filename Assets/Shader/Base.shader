Shader "Unlit/Base"
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
                
                fixed3 halfDir = normalize(viewDir+LightDir);
                fixed NdotL =  saturate(dot(LightDir,worldNormal));
                fixed NdotH = saturate(dot(halfDir,worldNormal));

                  fixed4 var_MainTex = tex2D(_MainTex,i.uv);
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Tint.rgb;
                fixed3 diffuse = _LightColor0.xyz * _Tint.rgb * NdotL * var_MainTex.rgb;
                fixed3 specualr = _LightColor0.xyz * pow(NdotH,_Gloss) * _Spec.rgb;

                
                return fixed4(ambient+diffuse+specualr,1.0);
            }
            ENDCG
        }
    }
}
