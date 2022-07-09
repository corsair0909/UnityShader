Shader "Unlit/FlatShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
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

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 NDirWS : TEXCOORD0;
                float4 WorldPos : TEXCOORD1;
            };

            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                o.NDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //平面着色，让三角形三个顶点的法向量等于三角形的法向量
                //GPU会按照2x2的块处理像素，ddx和ddy得出像素水平和竖直方向相邻像素之间的差
                //根据得到的差构成三角形的两条边，差积计算三角形法线
                float3 Dx = ddx(i.WorldPos);
                float3 Dy = ddy(i.WorldPos);
                i.NDirWS = normalize(cross(Dx,Dy));
                
                float3 Ndir = normalize(i.NDirWS);
                float3 Ldir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotV = saturate(dot(Ndir,-Ldir)) * 0.5f + 0.5f;
                fixed3 diffuse = _LightColor0 * NdotV * _Color.rgb;
                return fixed4(diffuse,_Color.a); 
            }
            ENDCG
        }
    }
}
