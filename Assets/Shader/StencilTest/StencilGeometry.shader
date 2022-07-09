Shader "Unlit/Stencil Geometry"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
        _Tint ("MainColor",Color) = (1,1,1,1)
        _ID ("ID",float) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _CompareFuntion ("funtion",int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)]
        _Op ("StencilOp",int) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry+2"}
        Stencil
        { 
            Ref [_ID]
            Comp [_CompareFuntion] //蒙版必须总是通过
        }
        
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase  
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            half4 _Tint;
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 NdirWS : TEXCOORD1;
                SHADOW_COORDS(2)
            };
            

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.NdirWS = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 LdirWS = _WorldSpaceLightPos0.xyz;
                float3 NdirWS = normalize(i.NdirWS);
                float NdotL = saturate(dot(NdirWS,LdirWS)) * 0.5f + 0.5f;

                float3 var_MainTex =  tex2D(_MainTex,i.uv) * _Tint;
                fixed shadow = SHADOW_ATTENUATION(i);
                float3 diffuse = _LightColor0.rgb * var_MainTex * NdotL * shadow;
                
                return fixed4(diffuse,1);
            }
            ENDCG
        }
    }
}
