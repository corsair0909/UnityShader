Shader "Unlit/StencilCircle"
{
    Properties
    {
        _MainTex ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry+2"}
        Stencil
        { 
            Ref 1
            Comp Equal //蒙版必须总是通过
        }

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
            };

            struct v2f
            {

                float4 vertex : SV_POSITION;
            };
            
            float4 _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _MainTex;
            }
            ENDCG
        }
    }
}
