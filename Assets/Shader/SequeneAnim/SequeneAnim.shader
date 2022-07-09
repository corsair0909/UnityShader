Shader "Unlit/SequeneAnim"
{
    Properties
    {
        _MainTex ("序列帧图", 2D) = "white" {}
        _HorizontalAmount("水平数量",float) = 1//水平方向上有多少个图片
        _VerticalAmount("竖直数量",float) = 1//竖直方向上有多少图片
        _Speed("播放速度",range(0.5,10)) = 1
    }
    SubShader
    {
        Tags { "Quene" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _HorizontalAmount;
            fixed _VerticalAmount;
            fixed _Speed;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //计算行列索引值
                fixed time = floor(_Time.y * _Speed);//计算模拟时间
                fixed Row = floor(time / _HorizontalAmount);
                fixed Column = time - Row * _HorizontalAmount;

                // half2 uv = half2(i.uv.x / _HorizontalAmount,i.uv.y / _VerticalAmount);
                // uv.x += Column/ _HorizontalAmount;
                // uv.y -= Row/_VerticalAmount;

                //uv从下到上逐渐增大，纹理播放顺序从上到下，竖直方向的序列帧动画需要减去
                half2 uv = i.uv + half2(Column,-Row);
                
                //序列帧动画图像包含很多个关键帧图像
                //需要将采样坐标映射到每个关键帧图像的坐标范围内
                //可以理解为缩放了整张序列帧图只显示一张关键帧
                //得到每个子图像的纹理坐标范围
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;
                
                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}
