Shader "Unlit/DOF2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGINCLUDE
          #include "UnityCG.cginc"
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 uv01 : TEXCOORD1;
                float4 uv23 : TEXCOORD2;
                float4 uv45 : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            sampler2D _BlurTex;
            float4 _MainTex_ST;
            float4 _Offsets;
            float4 _MainTex_TexelSize;

            fixed _forceDistance;
            fixed _nearScale;
            fixed _farScale;

            v2f vertBlur (appdata_img v)
            {
                v2f o;
                _Offsets *= _MainTex_TexelSize;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv01 = v.texcoord.xyxy + _Offsets.xyxy * float4(1,1,-1,-1);
                o.uv23 = v.texcoord.xyxy + _Offsets.xyxy * float4(1,1,-1,-1)*2;
                o.uv45 = v.texcoord.xyxy + _Offsets.xyxy * float4(1,1,-1,-1)*3; 
                return o;
            }

            fixed4 fragBlur (v2f i) : SV_Target
            {
                fixed4 color = fixed4(0,0,0,0);
                color += 0.4 * tex2D(_MainTex,i.uv);
                color += 0.15 * tex2D(_MainTex,i.uv01.xy);
                color += 0.15 * tex2D(_MainTex,i.uv01.zw);
                color += 0.1 * tex2D(_MainTex,i.uv23.xy);
                color += 0.1 * tex2D(_MainTex,i.uv23.zw);
                color += 0.05 * tex2D(_MainTex,i.uv45.xy);
                color += 0.05 * tex2D(_MainTex,i.uv45.zw);
                return color;
            }

            struct DOFStruct
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            DOFStruct vertDOF (appdata_img v)
            {
                DOFStruct o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            float4 fragDOF(DOFStruct i) : SV_Target
            {
                float depth = Linear01Depth(SAMPLE_RAW_DEPTH_TEXTURE(_CameraDepthTexture,i.uv));
                float4 sourceTex = tex2D(_MainTex,i.uv);
                float4 blurTex = tex2D(_BlurTex,i.uv);
                //depth小于焦点深度使用清晰图，大于焦点深度使用差值图，其结果为远景模糊
                float4 finalCol = (depth<=_forceDistance)?sourceTex: lerp(sourceTex,blurTex,clamp((depth-_forceDistance)*_farScale,0,1));
                //depth大于焦点深度使用之前的结果，小于焦点深度使用差值图，其结果为近景模糊
                finalCol = (depth>_forceDistance)?finalCol: lerp(sourceTex,blurTex,clamp((_forceDistance-depth)*_nearScale,0,1));
                return finalCol;
            }
        
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlur
            #pragma fragment fragBlur
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vertDOF
            #pragma fragment fragDOF
            ENDCG
        }
    }
}
