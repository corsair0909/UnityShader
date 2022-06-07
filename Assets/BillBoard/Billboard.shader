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

            v2f vert (appdata v)
            {
                v2f o;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 center = (0,0,0);
                float3 ViewPos = normalize(mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)));
                float3 normalDir = ViewPos-center;
                normalDir.y *= _VerticalBillboard;
                normalDir = normalize(normalDir);
                float3 upDir = abs(normalDir.y)>0.999? float3(0,0,1):float3(0,1,0);
                float3 rightDir = normalize(cross(upDir,normalDir));
                upDir = normalize(cross(rightDir,normalDir));
                float3 centerOffset = v.vertex.xyz - center;
                float3 newPos = center + centerOffset.x * rightDir + centerOffset.y * upDir + centerOffset.z * normalDir;
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
