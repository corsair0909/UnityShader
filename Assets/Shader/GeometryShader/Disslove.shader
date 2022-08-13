Shader "Unlit/Disslove"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainCol ("MainCol",Color) = (1,1,1,1)

        _DissloveThrshold ("Thrshold",float) = 0.1
        _ColorWidth ("ColorFactor",float) = 0.2

        [HDR]_BoxCol ("BoxCol",Color) = (1,1,1,1)
        [HDR]_LineColor ("LineColor",color) = (1,1,1,1)
        _BoxAlpha ("BoxAlpha",range(0,1)) = 1
        _BoxSacle ("BoxScale",float) = 1
        
        

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
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 NdirWS : TEXCOORD1;
                float4 objPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4 _MainCol;
            half4 _BoxCol;
            half4 _LineColor;

            fixed _ColorWidth;
            fixed _DissloveThrshold;
            fixed _BoxAlpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.NdirWS = UnityObjectToWorldNormal(v.normal);
                o.objPos = v.vertex; // 根据自身坐标的Y轴进行剔除
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float factor = _DissloveThrshold - i.objPos.y;
                clip(factor);

                fixed4 col = tex2D(_MainTex, i.uv) * _MainCol;
                float3 LdirWS = normalize(_WorldSpaceLightPos0.xyz);
                float3 NdirWS = normalize(i.NdirWS);
                float NdotL = saturate(dot(NdirWS,LdirWS)) * 0.5f+0.5f;
                float3 diffuseCol = col.rgb * NdotL *_LightColor0.rgb;
                float3 FianlCol = factor<_ColorWidth?_LineColor:diffuseCol;
                return float4(FianlCol,1);

            }
            ENDCG
        }
        Pass
        {
            Tags{"RenderType"="Transparent" "Queue" = "Transparent"}
            Blend SrcAlpha OneMinusSrcAlpha
            Cull off

            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                // float3 normal : NORMAL;
            };
            struct v2g
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            half4 _BoxCol;
            fixed _ColorWidth;
            fixed _DissloveThrshold;
            fixed _BoxAlpha;
            fixed _BoxSacle;

            v2g vert (appdata v)
            {
                v2g o;
                o.uv = v.uv;
                o.vertex = v. vertex;
                return o;
            }

            void ADD_POINT(float3 p1,g2f g,inout TriangleStream<g2f> outStream)
            {
                g.vertex = UnityObjectToClipPos(p1);
                outStream.Append(g);
            }

            void ADD_tRI(float3 p1,float3 p2,float3 p3,g2f g, inout TriangleStream<g2f> outStream)
            {
                ADD_POINT(p1,g,outStream);
                ADD_POINT(p2,g,outStream);
                ADD_POINT(p3,g,outStream);
                outStream.RestartStrip();
            }
            
            [maxvertexcount(36)]
            void geom(triangle v2g input[3], inout TriangleStream<g2f> outStream)
            {
                g2f o;
                float3 centerPos = (input[0].vertex.xyz + input[1].vertex.xyz+input[2].vertex.xyz)/3;
                float2 centerUV = (input[0].uv + input[1].uv+input[2].uv)/3;
                float factor = _DissloveThrshold - centerPos.y;
                if(factor < _ColorWidth)
                {
                    float3 s = input[0].vertex.xyz - input[1].vertex.xyz;
                    float3 t = input[0].vertex.xyz - input[2].vertex.xyz;
                    float3 normalFace = normalize(cross(s,t));


                    centerPos += normalFace * clamp(-0.5f+centerPos.y + _Time.y * 0.2f,0,5);
                     o.uv = centerUV;
                    float scale = _BoxSacle;
                    float4 V0 = float4(1,1,1,1) * scale +float4(centerPos,0);//右前上
                    float4 V1 = float4(1,-1,1,1) * scale + float4(centerPos,0);//右前下
                    float4 V2 = float4(1,1,-1,1) * scale + float4(centerPos,0);//右后上
                    float4 V3 = float4(1,-1,-1,1) * scale + float4(centerPos,0);//右后下
                    float4 V4 = float4(-1,1,1,1) * scale + float4(centerPos,0);//左前上
                    float4 V5 = float4(-1,-1,1,1) * scale + float4(centerPos,0);//左前下
                    float4 V6 = float4(-1,-1,-1,1) * scale + float4(centerPos,0);//左后下
                    float4 V7 = float4(-1,1,-1,1) * scale + float4(centerPos,0);//左后上

                    //右
                    ADD_tRI(V0,V1,V2,o,outStream);
                    ADD_tRI(V1,V2,V3,o,outStream);
                    //前
                    ADD_tRI(V1,V2,V4,o,outStream);
                    ADD_tRI(V2,V4,V5,o,outStream);
                    //左
                    ADD_tRI(V4,V5,V6,o,outStream);
                    ADD_tRI(V4,V6,V7,o,outStream);
                    //后
                    ADD_tRI(V6,V7,V2,o,outStream);
                    ADD_tRI(V6,V2,V3,o,outStream);
                    //顶
                    ADD_tRI(V2,V7,V0,o,outStream);
                    ADD_tRI(V6,V0,V4,o,outStream);
                    //底
                    ADD_tRI(V3,V6,V1,o,outStream);
                    ADD_tRI(V6,V1,V5,o,outStream);
                }
               
                
            }

            float4 frag (g2f i) : SV_Target
            {
                float4 fianlCol = _BoxCol;
                fianlCol.a = clamp(1-(_Time.y * 0.2),0,1);
                return fianlCol;
            }
            ENDCG
        }
    }
}
