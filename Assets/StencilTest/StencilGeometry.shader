Shader "Unlit/Stencil1"
{
    Properties
    {
        _ID ("ID",float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _StencilCompare("Comp",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]
        _StencilOp("Operat",int) = 0
    }
    SubShader
    {
        ColorMask 0 
        Stencil
        { 
            Ref [_ID]
            Comp [_StencilCompare]
            Pass [_StencilOp]
        }
        
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
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
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
