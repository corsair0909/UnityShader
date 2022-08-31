Shader "Unlit/QuadCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Cutoff",range(0,1)) = 0
        _Fade ("Fade",range(0,1)) = 0
        _Pos ("Pos",Vector) = (0,0,0,0)
        _TimeScale ("TimeScale",float) = 0
        _Direction ("Direction",float) = 0
        
    }
    SubShader
    {
        CGINCLUDE
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
            fixed _Cutoff;
            fixed _Fade;
            fixed4 _Pos;
            fixed _TimeScale;
            fixed _Direction;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - _Cutoff);
                return col;
            }
        
            struct appdataCloud
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2fCloud
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 Normal : TEXCOORD1;
                float3 ViewDir: TEXCOORD2;
            };
        
            v2fCloud vertCloud (appdataCloud v)
            {
                v2fCloud o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                half3 dis = normalize(_Pos - v.vertex);
                half time = _Time.y * _TimeScale;
                o.vertex.xyz += dis * (sin(time +v.vertex.y) * cos(time * 2 / 3 + v.vertex.y) + 1) * _Direction;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.Normal = UnityObjectToWorldNormal(v.normal);
                fixed4 PosWS = mul(unity_ObjectToWorld,v.vertex);
                o.ViewDir = _WorldSpaceCameraPos - PosWS.xyz;
                return o;
            }

            fixed4 fragCloud (v2fCloud i) : SV_Target
            {
                fixed3 NdirWS = normalize(i.Normal);
                fixed3 VdirWS = normalize(i.ViewDir);
                //不用 Saturate是为了使得模型背面和正面效果一样
                fixed NdotV = abs(dot(NdirWS,VdirWS));
                fixed fade = step(_Fade,NdotV);
                fixed4 col = tex2D(_MainTex, i.uv);
                // UNITY_APPLY_FOG(i.uv,col)
                col.a = col.a*fade + (1-fade)*lerp(0,col.a,((max(0,(NdotV-0.1)))/(_Fade - 0.1)));
                return col;
            }
        ENDCG

        Pass
        {
            Tags{
                "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"
                }
            ZWrite On
            AlphaToMask On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        
        Pass
        {
            Tags{
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
                "IgnoreProjector" = "True"
                }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            AlphaToMask On
            CGPROGRAM
            #pragma vertex vertCloud
            #pragma fragment fragCloud
            ENDCG
        }
    }
}
