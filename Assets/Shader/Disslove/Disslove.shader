Shader "Unlit/Disslove"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("NoiseTex",2D) = "Gray"{}
        _Thrshold("Thrshold",range(0,1)) = 0
        _EdgeWidth("Width" , range(0,1)) = 0.1
        _DissloveNode("DissloveNode",vector) = (0,0,0,0)
        _DissloveDir("DissloveDir",vector) = (0,0,0,0)
        _DissloveScale("Scale",range(0,1)) = 0.005
        
        
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 WorldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            fixed _Thrshold;
            fixed _EdgeWidth;
            fixed4 _DissloveNode;
            fixed4 _DissloveDir;
            fixed _DissloveScale;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.WorldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }
            //普通消融
            
            fixed DefaultDisslove(v2f i)
            {
                float var_NoiseTex = tex2D(_NoiseTex,i.uv).r;
                clip(var_NoiseTex - _Thrshold);
                fixed degress = (var_NoiseTex - _Thrshold)/_EdgeWidth;
                fixed4 lineCol = lerp(fixed4(1,0,0,1),fixed4(0,1,0,1),degress);
                return lineCol;
            }
            //定向消融
            //指定参照锚点，求出当前顶点与锚点之间的向量
            //求出向量在指定方向上的投影，并将该投影应用在disslove值的计算上
            void DirDisslove(v2f i)
            {
                float3 dv = i.WorldPos.xyz - _DissloveNode.xyz;
                float offset = dot(dv,normalize(_DissloveDir.xyz));
                float Disslove = tex2D(_NoiseTex,i.uv).r - _Thrshold + offset * _DissloveScale;
                clip(Disslove);
            }
            //向心消融
            void CenterDisslove(v2f i)
            {
                float3 dv = distance(i.WorldPos.xyz,_DissloveNode);
                float Disslove = tex2D(_NoiseTex,i.uv).r;
                Disslove = Disslove + dv * _DissloveScale - _Thrshold;
                clip(Disslove);
            }
            fixed4 frag (v2f i) : SV_Target
            {
                //float4 Linecol = DefaultDisslove(i);
                DirDisslove(i);
                fixed4 Col =  tex2D(_MainTex,i.uv);
                return Col;
            }
            ENDCG
        }
    }
}
