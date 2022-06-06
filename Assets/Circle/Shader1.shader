Shader "Unlit/Shader1"
{
    Properties
    {
        _ColorA("Color",color) = (1,1,1,1)
        _ColorB("ColorB",color) =(0,0,0,0)
        _Radius("Radius",Range(0,1))=0
        _Ancohr("Ancohr",vector) = (0.15,0.15,0,0)
        _TillCount("TillCount",int) = 1
        _Smooth("Smooth",Range(0,1))=0.08
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
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 position : TEXCOORD1;
            };

            fixed4 _ColorA;
            fixed4 _ColorB;
            fixed _Radius;
            fixed4 _Ancohr;
            fixed _TillCount;
            fixed _Smooth;
            //fixed4 _mouse;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.position = v.vertex;
                o.uv = v.texcoord;

                return o;
            }
            //绘制正方形
            //切记，i.position的原点在正中间，左下角为（-0.5，-0.5，0）ps：不是uv坐标
            float rect(float2 pos,float2 size,float2 center)
            {
                float2 pt = pos - center;//求出一个点的位置
                float2 halfsize = size * 0.5;
                float vert = step(-halfsize.x , pt.x) - step(halfsize.x,pt.x);//负半轴黄色区域step函数=1，正半轴黄色区域step=0
                float hori = step(-halfsize.y,pt.y) - step(halfsize.y,pt.y);
                return hori * vert;
            }
            float rect(float2 pos,float2 anchor,float2 size,float2 center)
            {
                
                float2 pt = pos - center;//求出一个点的位置
                float2 halfsize = size * 0.5;
                float vert = step(-halfsize.x - anchor.x , pt.x) - step(halfsize.x - anchor.x,pt.x);//负半轴黄色区域step函数=1，正半轴黄色区域step=0
                float hori = step(-halfsize.y - anchor.y , pt.y) - step(halfsize.y - anchor.y,pt.y);
                return hori * vert;
            }

            float2x2 getRotateMatrix2D(float theta)
            {
                float c = cos(theta);
                float s = sin(theta);
                return float2x2(c,-s,s,c);
            }
            float2x2 getScaleMatrix2D(float Scale)
            {
                return float2x2(Scale,0,0,Scale);
            }

            float DrawCircle(float2 pt,float2 center,float radius)
            {
                float2 p = pt - center;
                return 1 - step(radius,length(p));
            }
            float DrawCircle(float2 pt,float2 center,float radius,bool soft)
            {
                float2 p = pt - center;
                float edge = (soft) ? _Smooth * _Radius : 0.0f;
                return smoothstep(radius+edge,radius-edge,length(p));
            }
            float DrawCircle(float2 pt,float2 center,float radius,bool soft,float LineWidth)
            {
                float2 p = pt - center;
                float pl = length(p);
                float halfLinewidth = LineWidth/2;

                float edge = (soft) ? _Smooth * _Radius : 0.0f;
                return smoothstep((radius - halfLinewidth)-edge,(radius - halfLinewidth)+edge,pl)
                 - smoothstep((radius+halfLinewidth)-edge,(radius + halfLinewidth)+edge,pl);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //smoothstep函数研究
                // float l = length(i.uv-0.5);
                // float s1 = smoothstep(0.2,0.3,l);
                // float s2 = smoothstep(0.3,0.4,l);
                //return s1-s2;

                //画圈
                //step(x,n)当n>x时，返回1，小于x返回0，
                //取得距离原点距离大于0.25的像素，返回1，1-1=0得到黑色，表现为圆圈之外为黑色
                // float incircle = 1-step(0.25,length(i.position.xy));
                // float3 fcolor = float3(1,1,0)*incircle;
                //return float4(fcolor,1);

                //画正方形
                // float2 pos = i.position.xy;
                // float2 size1 = float2(0.5,0.25);
                // float2 center1 = float2(0.25,0.25);
                // float inRect1 = rect(pos,size1,center1);
                // float2 size2 = float2(0.25,0.5);
                // float2 center2 = float2(0.5,0.5);
                // float inRect2 = rect(pos,size2,center2);
                // float3 color = float3(1,1,0)*inRect1+float3(0,1,0)*inRect2;
                // return float4(color,1);
                
                //跟随鼠标显示
                // float2 pos = i.uv;
                // float inRect = rect(pos,float2(0.1,0.1),_mouse.xy);
                // float3 color = float3(1,1,0) * inRect;
                // return float4(color,1);

                 //圆上一点可表示为（CosA，SinA）A为该点的向量于x正半轴夹角
                 // float2 pos = i.position.xy*2;
                 // float2 center = float2(cos(_Time.y),sin(_Time.y)) * _Radius;
                 // float inRect = rect(pos,float2(0.1,0.1),center);
                 // float3 color = float3(1,1,0) * inRect;
                 // return float4(color,1);

                //平铺
                // float2 center = _Ancohr.zw;
                // //将一个像素乘以TillCount，再取小数部分得到【0-1】大小的空间，把图片分为TillCount个
                // float2 pos = frac(i.uv*_TillCount);
                // float size = _Radius;
                // float2x2 matS = getScaleMatrix2D(sin(_Time.y+1)/3+0.5);
                // float2x2 matR = getRotateMatrix2D(_Time.y);
                // float2x2 combineMat = mul(matR,matS);
                // float2 pt = mul(combineMat,pos-center)+center;
                // float3 color = float3(1,1,0) * rect(pt,_Ancohr.xy,size,center);
                // return float4(color,1);

                float2 pos = i.position.xy * 2;
                float3 color = _ColorA.rgb * DrawCircle(pos,float2(0,0),_Radius,true,0.1);
                return float4(color,1)+_ColorB;
            }
            ENDCG
        }
    }
}
