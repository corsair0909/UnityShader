Shader "Unlit/Vertex"
{
    Properties
    {
        _Radius ("radius", float) = 0.5
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };
            float _Radius;

            v2f vert (appdata_base v)
            {
                v2f o;
                float detal = (_SinTime.w + 1.0)/2.0;
                float4 s = float4(normalize(v.vertex.xyz) * _Radius * 0.01,v.vertex.w);
                float4 pos = lerp(v.vertex,s,detal);
                o.vertex = UnityObjectToClipPos(pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
