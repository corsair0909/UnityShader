Shader "Unlit/Stencil Mask"
{
    Properties
    {
        _ID ("ID",float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _CompareFuntion ("funtion",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]
        _Op ("StencilOp",int) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry+1"}
        
        ColorMask 0 
        ZWrite Off
        Stencil
        { 
            Ref [_ID]
            Comp [_CompareFuntion] //蒙版必须总是通过
            Pass [_Op] //蒙版区域像素的模版值替换为 _ID
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
