Shader "Unlit/Tessellation"
{
 Properties
 {
  _MainTex ("Texture", 2D) = "white" {}
      _Tessellation ("Tess", float) = 1
 }
 SubShader
 {
  Tags { "RenderType"="Opaque" }
  LOD 100
 
  Pass
  {
   CGPROGRAM
   #pragma vertex tessvert
   #pragma fragment frag
   #pragma hull hs
   #pragma domain ds
   #pragma target 4.6
   
   #include "UnityCG.cginc"
   #include "Lighting.cginc"
 
   struct appdata
   {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
   };
 
   struct v2f
   {
    float2 texcoord:TEXCOORD0;
    float4 vertex : SV_POSITION;
    float4 tangent : TANGENT;
     float3 normal : NORMAL;
   };
 
   struct InternalTessInterp_appdata {
     float4 vertex : INTERNALTESSPOS;
     float4 tangent : TANGENT;
     float3 normal : NORMAL;
     float2 texcoord : TEXCOORD0;
   };
 
   sampler2D _MainTex;
   float4 _MainTex_ST;
   fixed _Tessellation;
 
   InternalTessInterp_appdata tessvert (appdata v) {
     InternalTessInterp_appdata o;
     o.vertex = v.vertex;
     o.tangent = v.tangent;
     o.normal = v.normal;
     o.texcoord = v.texcoord;
     return o;
   }
 
 
   v2f vert (appdata v)
   {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
    return o;
   }
 
 
   UnityTessellationFactors hsconst (InputPatch<InternalTessInterp_appdata,3> v) {
     UnityTessellationFactors o;
     o.edge[0] =  _Tessellation;
     o.edge[1] =  _Tessellation;
     o.edge[2] = _Tessellation;
     o.inside = _Tessellation;
     return o;
   }
 
   [UNITY_domain("tri")]
   [UNITY_partitioning("fractional_odd")]
   [UNITY_outputtopology("triangle_cw")]
   [UNITY_patchconstantfunc("hsconst")]
   [UNITY_outputcontrolpoints(3)]
   InternalTessInterp_appdata hs (InputPatch<InternalTessInterp_appdata,3> v, uint id : SV_OutputControlPointID) {
     return v[id];
   }
 
   [UNITY_domain("tri")]
   v2f ds (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, float3 bary : SV_DomainLocation) {
     appdata v;
 
     v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
     v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
     v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
     v.texcoord = vi[0].texcoord*bary.x + vi[1].texcoord*bary.y + vi[2].texcoord*bary.z;
 
     v2f o = vert (v);
     return o;
   }
 
   
   fixed4 frag (v2f i) : SV_Target
   {
    return fixed4(1.0f,1.0f,1.0f,1.0f);
   }
   ENDCG
  }
 }
}