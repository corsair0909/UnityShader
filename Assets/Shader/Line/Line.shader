Shader "Unlit/Line"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",color) = (1,1,1,1)
        _LineWidth("Width",Range(0,1)) = 0.1
    }
    SubShader
    {
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
                float4 screenPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD1; 
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed _LineWidth;

            float Line(float a,float b,float Line_Width,float Edge_tickness)
            {
                float half_line_width = Line_Width * 0.5f;
                return smoothstep(a-half_line_width-Edge_tickness,a-half_line_width,b)
                - smoothstep(a+half_line_width,a+half_line_width+Edge_tickness,b);
            }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.screenPos.xy/i.screenPos.w;
                fixed3 color = lerp(fixed3(0,0,0),_Color,Line(i.uv.x,i.uv.y,_LineWidth,_LineWidth*0.1f));
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
