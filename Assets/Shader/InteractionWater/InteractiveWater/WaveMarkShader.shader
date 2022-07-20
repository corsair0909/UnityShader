Shader "Unlit/WaveMarkShader"
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
            #include "Assets/Shader/MyShaderLabs.cginc"

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
            float4 _WaveParameter;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float dx = i.uv.x - _WaveParameter.x;
                float dy = i.uv.y - _WaveParameter.y;
                float disSqr = dx*dx + dy*dy;
                int hasCol = step(0,_WaveParameter.z - disSqr);//_WaveParameter.z分量等于波浪半径，取得在波浪半径范围内的部分
                float waveValue = DecodeHeight(tex2D(_MainTex,i.uv));
                if (hasCol == 1)
                {
                    waveValue = _WaveParameter.w;//在波浪半径范围内的像素标记为默认波浪高度
                }
                return EncodeHeight(waveValue);
            }
            ENDCG
        }
    }
}
