Shader "Unlit/Glass"
{
    Properties
    {
        _Color("Color",Color) = (0,0,0,0)
        _Skybox("Skybox",Cube) = "white"{}
        _Tint("扭曲强度",range(0,1)) = 0
        _BumpMap("法线贴图",2D) = "white"{}
        _ReflectAmount("平衡值",range(0,1)) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue" = "Transparent"}
        Grabpass{"_ReflectionTex"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            fixed _Tint;
            samplerCUBE _Skybox;
            sampler2D _BumpMap;
            fixed _ReflectAmount;
            sampler2D _ReflectionTex;
            fixed _FresnelAmount;
            fixed _eta;
            fixed _FresnelBais;

            struct appdata
            {
                float2 uv       : TEXCOORD0;
                float4 vertex   : POSITION;
                float3 Normal   : NORMAL;
                float4 Tangent  : TANGENT;
            };

            struct v2f
            {
                float4 vertex           : SV_POSITION;
                float3 worldView        : TEXCOORD0;
                float3 worldNormal      : TEXCOORD1;
                float3 worldTangent     : TEXCOORD2;
                float3 WworldBTangent   : TEXCOORD3;
                float2 uv               : TEXCOORD4;
                float4 scrPos           : TEXCOORD5;
            };
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldView = _WorldSpaceCameraPos - mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.Normal));
                o.worldTangent =normalize(mul(unity_ObjectToWorld,float4(v.Tangent.xyz,1)));
                o.WworldBTangent =normalize(cross(o.worldNormal,o.worldTangent.xyz));
                o.uv = v.uv;
                o.scrPos = ComputeScreenPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 NdirTS = UnpackNormal(tex2D(_BumpMap,i.uv));
                float3x3 TBN = float3x3(i.worldTangent,i.WworldBTangent,i.worldNormal);
                float3 NdirWS = mul(TBN,NdirTS);
                float offset = NdirTS * _Tint;//TS空间下的法线进行扭曲
                i.scrPos.xy += offset;
                float4 ReflectionCol = tex2D(_ReflectionTex,i.scrPos.xy/i.scrPos.w);
                float3 reflectDir = reflect(i.worldView,NdirWS);
                float4 CubeCol1 = texCUBE(_Skybox,reflectDir);
                
                float3 col = lerp(ReflectionCol,CubeCol1,_ReflectAmount);
                col.rgb *=_Color.rgb;
                return float4(col,1);
            }
            ENDCG
        }
    }
}
