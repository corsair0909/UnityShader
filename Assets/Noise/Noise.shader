Shader "Unlit/Noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        
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
            fixed _A;
            fixed _B;
            fixed _C;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            //噪音公式
            float NoiseCreat(float2 uv,float seed)
            {
                const float a = 12.9898;
                const float b = 78.233;
                const float c = 43758.543123;
                return frac(sin(dot(uv,float2(a,b))+seed)*c);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = NoiseCreat(i.uv,_Time.y) * fixed4(1,1,1,1);
                return col;
            }
            ENDCG
        }
    }
}
