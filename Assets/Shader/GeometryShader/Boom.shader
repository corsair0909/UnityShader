Shader "Unlit/Boom"
{
    Properties 
    { 
        _MainTex ("Texture", 2D) = "white" {} 
        _InitSpeed ("InitSpeed",float) = 0.5
        _ContinueTime ("Frequency",float) = 0.1
        _Acceleration ("InvWaveLength",float) = 0.2
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

            float _InitSpeed;
            float _ContinueTime; 
            float _Acceleration;
            
            v2g vert (appdata v) 
            { 
                v2g o; 
                o.vertex =v.vertex; 
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
                return o; 
            } 
            //-------静态制定单个调用的最大顶点个数 
            [maxvertexcount(1)] 
            void geom(triangle v2g input[3],inout PointStream<g2f> outStream){ 
                g2f o = (g2f)0; 
                float3 s = (input[0].vertex - input[1].vertex).xyz;
                float3 t = (input[0].vertex - input[2].vertex).xyz;
                float3 normal = normalize(cross(s,t));
                o.Normal = UnityObjectToWorldNormal(normal);
                float3 centerPos = ((input[0].vertex+input[1].vertex+input[2].vertex)/3.0f).xyz;
                float2 centeUV = (input[0].uv+input[1].uv+input[2].uv)/3.0f;
                o.uv = centeUV;
                float time = _Time.y % _ContinueTime;
                centerPos += normal * (_InitSpeed *time+0.5 *_Acceleration*pow(time,2));
                o.vertex = UnityObjectToClipPos(centerPos);
                outStream.Append(o);
                //outStream.RestartStrip();
            } 

            
             
            fixed4 frag (g2f i) : SV_Target 
            { 
                // sample the texture 
                fixed4 col = tex2D(_MainTex, i.uv); 
				return col;
            } 
            ENDCG 
        } 
    } 
}
