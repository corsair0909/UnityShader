Shader "Unlit/Geometry1"
{
    Properties 
    { 
        _MainTex ("Texture", 2D) = "white" {} 
        _Length ("lENGTH",float) = 0.5
        _Frequency ("Frequency",float) = 0.1
        _InvWaveLength ("InvWaveLength",float) = 0.2
        _Tessellation ("Tessellation",float) = 1
    } 
    SubShader 
    { 
        Tags { "RenderType"="Opaque" } 
        LOD 100 
 
        Pass 
        { 
            Cull off
            CGPROGRAM 
            #pragma vertex vert 
            //-------声明几何着色器 
            #pragma geometry geom 
            #pragma fragment frag 
      			 
            #include "UnityCG.cginc" 
            #pragma target 4.6
 
            struct appdata 
            { 
                float4 vertex : POSITION; 
                float2 uv : TEXCOORD0; 
            }; 
            //-------顶点向几何阶段传递数据 
            struct v2g{ 
                float4 vertex:SV_POSITION; 
                float2 uv:TEXCOORD0; 
            }; 

            struct g2f
            {
                float4 vertex : SV_POSITION; 
                float2 uv : TEXCOORD0; 
                float3 Normal : TEXCOORD1;
            };
 
            sampler2D _MainTex; 
            float4 _MainTex_ST; 

            float _Length;
            float _Frequency; 
            float _InvWaveLength;
            float _Tessellation;
            
            v2g vert (appdata v) 
            { 
                v2g o; 
                float4 offset = float4(0,0,0,0);
                float sinx = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength+v.vertex.y+v.vertex.z * _InvWaveLength);
                offset.y = sinx;
                offset.x = sin(_Frequency*_Time.y+v.vertex.x);
                offset.z = sin(_Frequency*_Time.y+v.vertex.z);
                o.vertex =v.vertex+offset; 
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
                return o; 
            } 
            void ADD_point(float3 p0,g2f o, inout TriangleStream<g2f> outStream)
            {
                // 新生成的顶点也需要转换到裁剪空间下
                o.vertex = UnityObjectToClipPos(p0);
                outStream.Append(o);
            }
            void ADD_Tri(float3 p0,float3 p1,float3 p2,g2f g,inout TriangleStream<g2f> outStream)
            {
                ADD_point(p0,g,outStream);
                ADD_point(p1,g,outStream);
                ADD_point(p2,g,outStream);
                outStream.RestartStrip();
            } 
            //-------静态制定单个调用的最大顶点个数 
            [maxvertexcount(9)] 
            void geom(triangle v2g input[3],inout TriangleStream<g2f> outStream){ 
                g2f o=(g2f)0; 

                float3 s = (input[0].vertex - input[1].vertex).xyz;
                float3 t = (input[0].vertex - input[2].vertex).xyz;
                float3 normal = normalize(cross(s,t));
                o.Normal = UnityObjectToWorldNormal(normal);
                float3 centerPos = ((input[0].vertex+input[1].vertex+input[2].vertex)/3.0f).xyz;
                float2 centeUV = (input[0].uv+input[1].uv+input[2].uv)/3.0f;
                o.uv = centeUV;
                centerPos += normal * _Length;
                ADD_Tri(input[0].vertex.xyz,centerPos,input[1].vertex.xyz,o,outStream);
                ADD_Tri(input[0].vertex.xyz,centerPos,input[2].vertex.xyz,o,outStream);
                ADD_Tri(input[1].vertex.xyz,centerPos,input[2].vertex.xyz,o,outStream);
            } 

            
             
            fixed4 frag (g2f i) : SV_Target 
            { 
                // sample the texture 
                fixed4 col = tex2D(_MainTex, i.uv); 

                half3 lDirWs = _WorldSpaceLightPos0.xyz;
				half3 nDirWs = normalize(i.Normal);
				half nDotL = max(0,dot(lDirWs,nDirWs));
				return nDotL;
            } 
            ENDCG 
        } 
    } 
}
