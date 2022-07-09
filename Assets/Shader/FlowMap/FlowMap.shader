Shader "Unlit/FlowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FlowMap ("FlowMap", 2D) = "white" {}
        _FlowSpeed("FlowSpeed", range(0.2,3)) = 0.3
        _TimeSpeed("TimeSpeed", range(0.2,5)) = 0.2
           
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            fixed _FlowSpeed;
            fixed _TimeSpeed;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 var_FlowMap = tex2D(_FlowMap,i.uv) * 2.0 - 1.0;
                var_FlowMap *= _FlowSpeed;
                fixed phase0 = frac(_Time.y * _TimeSpeed);
                fixed phase1 = frac(_Time.y * _TimeSpeed + 0.5f);

                float2 TillingUV  = i.uv * _MainTex_ST.xy *_MainTex_ST.zw;
                
                fixed4 col0 = tex2D(_MainTex, TillingUV-var_FlowMap.xy * phase0);
                fixed4 col1 = tex2D(_MainTex, TillingUV-var_FlowMap.xy * phase1);

                fixed t = abs((0.5f-phase0)/0.5f);
                fixed3 finalColor = lerp(col0,col1,t);
                return fixed4(finalColor,1);
            }
            ENDCG
        }
    }
}
