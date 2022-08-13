Shader "Unlit/GeometryGrass"
{
    Properties
    {
        _BottomColor ("BottomColor",color) = (1,1,1,1)
        _TopColor ("TopColor",color) = (1,1,1,1)
        
        _BendRotationRandom("BendRotationRandom",range(0,1)) = 0.2
        
        _GrassWidth ("GrassWidth",float) = 0.5
        _WidthRandomFactor ("Width Random Factor",float) = 0.02 
        _GrassHeight ("GrassHeight",float) = 1
        _HeightRandomFactor ("Height Random Factor",float) = 0.02 
        
        _WindDistortionMap ("Wind Distortion Map",2D) = "White"{}
        _WindFractor ("WindFractor",vector) = (0.045,0.05,0,0)
        _WindStrength ("WindStrength",float) = 1
        
        _GrassCount("GrassCount",int) = 1
        
        _BladeForward("BladeForwardAmout",float) = 0.38
        _Curve ("Curve",range(1,4)) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGINCLUDE
         #include "UnityCG.cginc"
         #include "Lighting.cginc"
         #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
				float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                //float2 uv       : TEXCOORD0;
            };

            struct a2t
            {
                float4 vertex : POSITION;
				float3 Ndir   : NORMAL;
                float4 Tdir   : TANGENT;
                //float2 uv       : TEXCOORD0;
            };

            struct tessfactor
            {
                float edge[3] : SV_TessFactor;
                float inside  : SV_InsideTessFactor;
            };

            struct VertexOutput // t2g
            {
                float4 vertex : SV_POSITION;
				float3 Ndir   : TEXCOORD0;
                float4 Tdir   : TEXCOORD1;
                float2 uv     : TEXCOORD2;
            };

            struct geometryOutput // 输出结构体
            {
                float4 pos : SV_POSITION;
                float2 uv     : TEXCOORD0;
                //SHADOW_COORDS(1)
            };

            // sampler2D _MainTex;
            // float4 _MainTex_ST;
            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;

            half4 _BottomColor;
            half4 _TopColor;

            fixed _BendRotationRandom;
            fixed _GrassWidth;
            fixed _WidthRandomFactor;
            fixed _GrassHeight;
            fixed _HeightRandomFactor;
            fixed _WindFractor;
            fixed _WindFrequency;
        
            fixed _WindStrength;
            fixed _GrassCount;
            fixed _BladeForward;
            fixed _Curve;

            //return a number in the 0-1 range,
            //and we will multiply this by two PI to get full gamut of angular value
            float rand(float seed)
            {
                float f = sin(dot(seed,float3(127.1,337.1,256.2)));
                f = -1+2 * frac(f * 43785.5453123);
                return f;
            }
            // 与 C#中的Quaternion.AngleAxis 方法一样，不过返回一个旋转矩阵
            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
	            float c, s;
	            sincos(angle, s, c);

	            float t = 1 - c;
	            float x = axis.x;
	            float y = axis.y;
	            float z = axis.z;

	            return float3x3(
		            t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		            t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		            t * x * z - s * y, t * y * z + s * x, t * z * z + c
		        );
            }

            VertexOutput vert (appdata v)
            {
                VertexOutput o;
                o.vertex =v.vertex;
                o.Ndir = v.normal;
                o.Tdir = v.tangent;
                return o;
            }
            a2t Tessvert (appdata v)
            {
                a2t o;
                o.vertex =v.vertex;
                o.Ndir = v.normal;
                o.Tdir = v.tangent;
                return o;
            }


            tessfactor hullconst(InputPatch<a2t,3> v)
            {
                tessfactor o;
                o.edge[0] = _GrassCount;
                o.edge[1] = _GrassCount;
                o.edge[2] = _GrassCount;
                o.inside = _GrassCount;
                return o;
            }

            [UNITY_domain("tri")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_patchconstantfunc("hullconst")]
            [UNITY_outputcontrolpoints(3)]
            a2t hullProgram(InputPatch<a2t,3> v,uint id : SV_OutputControlPointID)
            {
                return v[id];
            }

            [UNITY_domain("tri")]
            VertexOutput domainProgram(tessfactor tessfactor,const OutputPatch<a2t,3> vi,float3 bary : SV_DomainLocation)
            {
                appdata v;
                VertexOutput o;
                v.vertex = vi[0].vertex * bary.x + vi[1].vertex * bary.y + vi[2].vertex * bary.z;
	            v.tangent = vi[0].Tdir * bary.x + vi[1].Tdir * bary.y + vi[2].Tdir * bary.z;
	            v.normal = vi[0].Ndir * bary.x + vi[1].Ndir * bary.y + vi[2].Ndir * bary.z;
                o = vert(v);
                return o;
            }

            geometryOutput vertexOutPut(float3 p,float2 uv)
            {
                geometryOutput o;
                o.pos = UnityObjectToClipPos(p);
                o.uv = uv;
                //TRANSFER_SHADOW(o);
                return o;
            }

            //triangle float4 input[3] : SV_POSITION 表示一个三角形作为输入

            #define BLADE_SEGMENTS 3 //可以理解为草的层数

            geometryOutput GenerateGrassVertex(float3 vertexPos,float width,float height,float segmentForward,float2 uv,
                float3x3 TransformMatrix)
            {
                float3 tangentPos = float3(width,segmentForward,height);
                float3 LocalPosition = vertexPos + mul(TransformMatrix,tangentPos);
                return vertexOutPut(LocalPosition,uv);
            }
        
            [maxvertexcount(BLADE_SEGMENTS*2+1)]
            void geom (triangle VertexOutput input[3] : SV_POSITION,inout TriangleStream<geometryOutput> outStream)
            {
                //geometryOutput o;
                float3 NdirLS = input[0].Ndir;
                float4 TdirLS = input[0].Tdir;
                float3 BdirLS = - normalize(cross(NdirLS,TdirLS) * TdirLS.w);
                float3x3 TBN = float3x3(TdirLS.xyz,BdirLS,NdirLS);
                //输出顶点的位置 = 输入顶点的位置 + 三角形偏移量
                float3 pos = input[0].vertex.xyz;
                
                //用于控制朝向的矩阵，绕竖直方向轴旋转，切线空间中向上方向为Z分量
                float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos.xxz)* UNITY_TWO_PI,float3(0,0,1));
                //用于在水平方向上控制旋转的矩阵，并不是所有草都是直的
                float3x3 bendRotationMatrix  = AngleAxis3x3(rand(pos.zzx)*UNITY_PI*_BendRotationRandom
                 *0.5,float3(-1,0,0));


                float2 uv = pos.xz * _WindDistortionMap_ST.xy+_WindDistortionMap_ST.zw + _WindFractor * _Time.y;
                float2 windSample =(tex2Dlod(_WindDistortionMap,float4(uv,0,0)).rg * 2 - 1) * _WindStrength;
                float3 wind = normalize(float3(windSample.x,windSample.y,0));
                float3x3 windRotationMatrix = AngleAxis3x3(UNITY_PI * windSample,wind);
                
                //TBN矩阵与旋转矩阵相结合，PS顺序不能错，先旋转在变换到切线空间
                float3x3 transformationMatrix =mul(mul(mul(TBN,windRotationMatrix),facingRotationMatrix),bendRotationMatrix);
                
                float width = (rand(pos.zxy) * 2 - 1) * _WidthRandomFactor + _GrassWidth;
                float Height =(rand(pos.xyz) * 2 - 1) * _HeightRandomFactor + _GrassHeight;

                //让每一次的顶点发生水平偏移使得整体弯曲
                float forward = rand(pos.yyz) * _BladeForward;
                for (int i = 0; i < BLADE_SEGMENTS; i++)
                {
                    // 第1层 h=0 w = width
                    // 第2层 h=Height/3 w = width
                    // 第3层 h=0 w = width
                        float t = i/(float)BLADE_SEGMENTS;
                        float segmentHeight = Height * t;
                        float segmentWidth = width * (1-t);
                        float segmentForward = pow(t,_Curve) * forward;
                    
                        //转到本地空间进行计算,本地空间第三个分量指向外侧
                        outStream.Append(GenerateGrassVertex(pos,segmentWidth,segmentHeight,segmentForward,float2(0,t),transformationMatrix)); 
                        outStream.Append(GenerateGrassVertex(pos,-segmentWidth,segmentHeight,segmentForward,float2(1,t),transformationMatrix)); 

                }
                outStream.Append(GenerateGrassVertex(pos,0,Height,forward,float2(0.5,1),transformationMatrix)); 
            
            }

            fixed4 frag (geometryOutput i) : SV_Target
            {
                //return _BottomColor;
                float4 finalCol = lerp(_BottomColor,_TopColor,i.uv.y);
                // finalCol *= SHADOW_ATTENUATION(i);
                return finalCol;
                
            }
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hullProgram
            #pragma domain domainProgram
            #pragma geometry geom
            #pragma target 4.6
            ENDCG
        }
        
        Pass
        {
            Tags{"LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragShadow
            #pragma hull hullProgram
            #pragma domain domainProgram
            #pragma geometry geom
            #pragma target 4.6
            #pragma multi_compile_shadowcaster

            // struct v2f
            // {
            //     V2F_SHADOW_CASTER;
            // };
            // v2f vert(appdata_base v)
            // {
            //     v2f o;
            //     TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
            //     return o;
            // }

            float4 fragShadow(geometryOutput i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
    }
}
