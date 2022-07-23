Shader "Custom/Depth"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "AlphaTest" }

        Pass
        {
            Fog{Mode Off}
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord:TEXCOORD0;
            };

            struct v2f
            {
                float2 depth : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 uv:TEXCOORD1;
            };

            sampler2D _MainTex;
	        float4 _MainTex_ST;
		    uniform float _clipValue;//透明度测试时使用的阈值

            v2f vert (appdata v)
            {
                v2f o;
                o.uv= TRANSFORM_TEX(v.texcoord, _MainTex);
                o.pos = UnityObjectToClipPos(v.vertex); //将顶点坐标从模型空间变换到视锥体空间
                o.depth = o.pos.zw; //记录深度信息
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //透明度裁剪，对树叶等的阴影效果有用
                fixed4 alphaCol = tex2D(_MainTex,i.uv);
	            clip(alphaCol.a - _clipValue);

                float depth=i.depth.x / i.depth.y;
                #if defined(SHADER_TARGET_GLSL)
                    depth=depth*0.5 + 0.5;   //(-1,1) → (0,1)
                #elif defined(UNITY_REVERSED_Z)
                    depth=1-depth;  //(1,0)→(0,1)
                #endif
                return EncodeFloatRGBA(depth);
            }
            ENDCG
        }
    }
}