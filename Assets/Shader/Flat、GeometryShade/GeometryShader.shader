Shader "Unlit/GeometryShader"
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
            #pragma target 4.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry gemo

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            //mac电脑GPU不支持几何着色器
            //正常的传递数据
            [maxvertexcount(3)]
            void gemo (triangle appdata input[3],inout TriangleStream<g2f> outStream)
            {
                
                for (int i = 0; i < 3; ++i)
                {
                    g2f o;
                    o.uv = input[i].uv;
                    o.vertex = input[i].vertex;
                    outStream.Append(o);
                }
                //每输出足够组成指定的图元后
                //都需要RestartStrip一次再继续组成下一图元
                outStream.RestartStrip();
            }

            fixed4 frag (g2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex,i.uv);
                return col;
            }
            ENDCG
        }
    }
}
