Shader "Unlit/Test"
{
    Properties
    {
        _WindDistortionMap ("Wind Distortion Map",2D) = "White"{}
        _WindFractor ("WindFractor",vector) = (0.045,0.05,0,0)
        _WindStrength ("WindStrength",float) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;

            fixed _WindFractor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float2 uv = i.uv + _WindDistortionMap_ST.xy+_WindDistortionMap_ST.zw + _WindFractor * _Time.y;
                fixed2 col = tex2D(_WindDistortionMap, uv).rg;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(col,0,1);
            }
            ENDCG
        }
    }
}
