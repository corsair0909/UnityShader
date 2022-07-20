Shader "Unlit/Base"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexMask("TexMask",2D) = "Black"{}
        _Tint ("Color",color) = (1,1,1,1)
        _Spec ("SpecColor",color) = (1,1,1,1)
        _Gloss("Gloss",range(30,90)) = 50
        
        [Space(10)]
        [Header(RoleColor)]
        _InnerCloth("InnerCloth", Color) = (0,0,0,0)
		_OuterChlothes("OuterChlothes", Color) = (0,0,0,0)
        _Hair("Hair", Color) = (0,0,0,0)
        
        [Space(10)]
        [Header(Disslove)]
        _NoiseTex("NoiseTex",2D) = "Gray"{}
        _Thrshold("Thrshold",range(0,3)) = 0
        _EdgeWidth("Width" , range(0,1)) = 0.1
        _DissloveNode("DissloveNode",vector) = (0,0,0,0)
        _DissloveDir("DissloveDir",vector) = (0,0,0,0)
        _DissloveScale("Scale",range(0,1)) = 0.005
        [HDR]_EdgeColor("EdgeColor",color) = (1,1,1,1)
        

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float2 uv      : TEXCOORD0;
                float4 vertex  : SV_POSITION;
                float3 NDirWS  : TEXCOORD1;
                float3 TDirWS  : TEXCOORD2;
                float3 BTDirWS : TEXCOORD3;
                float4 WorldPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half4 _Tint;
            half4 _Spec;
            half4 _EdgeColor;
            half4 _InnerCloth,_OuterChlothes,_Hair;

            fixed _Gloss;

            sampler2D _NoiseTex;
            sampler2D _MainTexMask;
            fixed _Thrshold;
            fixed _EdgeWidth;
            fixed4 _DissloveNode;
            fixed4 _DissloveDir;
            fixed _DissloveScale;

            float DirDisslove(v2f i)
            {

                float Disslove = tex2D(_NoiseTex,i.uv).r;
                return Disslove;
            }
            
            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.NDirWS = mul(unity_ObjectToWorld,v.normal).xyz;
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {


                fixed3 worldNormal = normalize(i.NDirWS);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.WorldPos));
                
                fixed3 halfDir = normalize(viewDir+LightDir);
                fixed NdotL =  saturate(dot(LightDir,worldNormal));
                fixed NdotH = saturate(dot(halfDir,worldNormal));

                fixed4 var_MainTex = tex2D(_MainTex,i.uv);
                fixed4 var_MaskTex = tex2D(_MainTexMask,i.uv);
                fixed4 mask1 = (var_MaskTex.r).xxxx;
                fixed4 mask2 = (var_MaskTex.g).xxxx;
                fixed4 mask3 = (var_MaskTex.b).xxxx;

                //用遮罩图的三个通道混合里面、外面的衣服和头发
                float4 blendOpDest22 = ( min( mask1 , _OuterChlothes ) + min( mask2 , _InnerCloth ) + min( mask3 , _Hair ) );
			    float4 lerpResult4 = lerp( var_MainTex , ( ( saturate( ( var_MainTex * blendOpDest22 ) )) * 2.0 ) , ( var_MaskTex.r + var_MaskTex.g + var_MaskTex.b ));
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Tint.rgb;
                fixed3 diffuse = _LightColor0.xyz * _Tint.rgb * NdotL * lerpResult4.rgb;
                fixed3 specualr = _LightColor0.xyz * pow(NdotH,_Gloss) * _Spec.rgb;
                
                float dissVal = DirDisslove(i);
                float3 dv = i.WorldPos.xyz - _DissloveNode.xyz;
                float offset = dot(dv,normalize(_DissloveDir.xyz));
                float thrshold = _Thrshold + offset * _DissloveScale;

                clip(dissVal - thrshold);
                if (dissVal-thrshold < _EdgeWidth)
                {
                    return _EdgeColor;
                }
              
                return fixed4(ambient+diffuse+specualr,1.0);
            }
            ENDCG
        }
    }
}
