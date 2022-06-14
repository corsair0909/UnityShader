Shader "Unlit/Disslove"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("NoiseTex",2D) = "Gray"{}
        _Thrshold("Thrshold",range(0,1)) = 0
        _EdgeWidth("Width" , range(0,1)) = 0.1
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
            sampler2D _NoiseTex;
            fixed _Thrshold;
            fixed _EdgeWidth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float var_NoiseTex = tex2D(_NoiseTex,i.uv).r;
                clip(var_NoiseTex - _Thrshold);
                fixed degress = (var_NoiseTex - _Thrshold)/_EdgeWidth;
                fixed4 lineCol = lerp(fixed4(1,0,0,1),fixed4(0,1,0,1),degress);
                float4 Col = tex2D(_MainTex,i.uv);
                float4 FinalCol = lerp(lineCol,Col,degress);
                return FinalCol;
            }
            ENDCG
        }
    }
}
