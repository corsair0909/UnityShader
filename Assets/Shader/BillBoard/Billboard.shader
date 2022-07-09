Shader "Unlit/Billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VerticalBillboard("Vertical Scale" , float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True" }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
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
            fixed _VerticalBillboard;

            //Billboard 技术的核心在于重新计算三个正交的向量，分别为表面法线，向上方向，向右方向
            //表面法线或向上方向二者有一个是固定的，差积得出向右方向向量
            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //确定锚点，锚点是不变的，根据锚点确定多边形在空间中的位置
                float3 center = (0,0,0);
                float3 ViewPos = normalize(mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)));
                float3 normalDir = ViewPos-center;
                normalDir.y *= _VerticalBillboard;
                normalDir = normalize(normalDir);
                float3 upDir = float3(0,1,0);
                float3 rightDir = normalize(cross(upDir,normalDir));
                upDir = normalize(cross(rightDir,normalDir));
                //顶点到中心点的偏移量
                float3 centerOffset = v.vertex.xyz - center;
                //float3 newPos = center + centerOffset.x * rightDir + centerOffset.y * upDir + centerOffset.z * normalDir;
                float3 newPos = center + mul(centerOffset,float3x3(rightDir,upDir,normalDir));
                o.vertex = UnityObjectToClipPos(float4(newPos,1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
