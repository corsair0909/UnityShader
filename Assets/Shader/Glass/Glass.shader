Shader "Unlit/Glass"
{
    Properties
    {
        _Color("Color",Color) = (0,0,0,0)
        _Skybox("Skybox",Cube) = "white"{}
        _Fresnel("FresnelPow",range(0,1))=0
        _eta("RefractEta",range(0,1)) = 0
        _FresnelScale ("Scale", Range(0, 10)) = .5
        _FresnelBias ("Bias", Range(0, 10)) = .5
        
    }
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            fixed _Fresnel;
            samplerCUBE _Skybox;
            fixed _eta;
            fixed _FresnelScale;
            fixed _FresnelBias;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 Normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldView : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldView = mul(unity_ObjectToWorld,v.vertex).xyz - _WorldSpaceCameraPos;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.Normal));
                return o;
            }

            fixed Fresnel(float3 V,float3 N,float F0)
            {
                float fresnel = max(0, min(1, _FresnelBias * pow(1.0 - dot(V, N), F0)));
                //float fresnel = F0 + (1.0f-F0)*pow(1-dot(V,N),F0);
                //float fresnel = pow(1-max(0,dot(V,N)),F0);
                return fresnel;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float3 reflectDir = reflect(i.worldView,i.worldNormal);
                float3 refractDir = refract(i.worldView,i.worldNormal,_eta);

                float4 reflectCol = texCUBE(_Skybox,reflectDir);
                float4 refractCol = texCUBE(_Skybox,refractDir);

                float fresnel = Fresnel(i.worldView,i.worldNormal,_Fresnel);

                float4 Col = lerp(refractCol,reflectCol,fresnel);
                Col.rgb *= _Color.rgb;
                Col.a = _Color.a;
                return Col;
            }
            ENDCG
        }
    }
}
