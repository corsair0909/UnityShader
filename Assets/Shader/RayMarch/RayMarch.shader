Shader "Unlit/RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VolumeRadius("Radius",range(0,0.5)) = 0.2
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
            #define MAX_STEP 100
            #define MAX_DIST 100
            #define SURF_DIST 0.001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitpos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _VolumeRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.hitpos = v.vertex;
                return o;
            }

            float GetDist(float3 p)
            {
                float d = length(p) - _VolumeRadius;
                return d;
            }
            //光线步进算法 
            float RayMarching(float3 ro,float3 rd)
            {
                float dO = 0;
                float ds;
                for (int i = 0; i < MAX_STEP; i++)
                {
                    float3 p = ro+dO*rd;//步进点位置 = 原点+每次步进步进距离*步进方向
                    ds = GetDist(p);//单次步进距离
                    dO += ds;
                    if (dO>MAX_DIST||ds<SURF_DIST)
                    {
                        break;
                    }
                }
                return dO;
            }
            //获取法线
            //
            float3 GetNormal(float3 p)
            {
                float2 vec = float2(0.01,0);
                float3 n = GetDist(p) - float3(
                    GetDist(p-vec.xyy),
                    GetDist(p-vec.yxy),
                    GetDist(p-vec.yyx)
                    );
                return normalize(n);
            }
            float GetLight(float3 p)
            {
                float3 Ldir = _WorldSpaceLightPos0 - p;
                float3 Ndir = GetNormal(p);
                float NoL = saturate(dot(Ndir,Ldir))*0.5f+0.5f;
                return NoL;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 ro = i.ro;//射线发射原点
                float3 rd = normalize(i.hitpos - ro);//射线发射方向
                float d = RayMarching(ro,rd);
                fixed4 col = 1;
                if(d<MAX_DIST)
                {
                    float3 p = ro+rd * d;
                    col.rgb = GetLight(p);
                }
                else
                {
                    discard;
                }
                return col;
            }
            ENDCG
        }
    }
}
