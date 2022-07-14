Shader "Unlit/Tessellation"
{
    Properties
    {
        _Tessellation ("Tess", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 4.6

            #pragma hull hullShader
            #pragma domain ds
            
            #pragma vertex TessVert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata//顶点输入数据结构体
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 Normal : NORMAL;
                float4 Tangent : TANGENT;
            };
            
            struct TessOutPut//曲面细分着色器输入数据结构体，数据从顶点着色器结构体中传入
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
            
            float _Tessellation;

            //顶点着色器 -> 曲面细分着色器数据结构体 -> 计算patch -> hullshader（细分控制着色器）-> Domainshader（细分计算着色器）（需要一个细分计算函数）
            //-> 变换到Clip空间 -> 片段着色器

            //使用曲面细分着色器时，顶点着色器主要用来进行空间变换，不进行计算
            //PS：不是顶点着色器，只是用来在Domain函数中对新产生的顶点进行空间变换的
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.Normal = v.normal;
                o.Tangent = v.tangent;
                return o;
            }

            
            //开始曲面细分着色器部分
            
            //顶点着色器，将数据从顶点着色器传入到曲面细分着色器数据结构体
            //要产生新的顶点，空间变换在Domain函数中进行
            TessOutPut TessVert(appdata v) 
            {
                TessOutPut o;
                o.normal = v.normal;
                o.tangent = v.tangent;
                o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            //曲面细分参数的计算方法
            //InputPatch 中传入曲面细分数据结构体和图元顶点数]
            //Patch 部分已经在 Lighting.cginc中被定义，直接使用UnityTessellationFactors即可
            UnityTessellationFactors hsconst(InputPatch<TessOutPut,3> patch) // patch计算
            {
                //根据相机到顶点的距离
                UnityTessellationFactors o;
                o.edge[0] = _Tessellation;
                o.edge[1] = _Tessellation;
                o.edge[2] = _Tessellation;
                o.inside = _Tessellation;
                return o;
            }

            [UNITY_domain("tri")]//确定图元
            [UNITY_partitioning("fractional_odd")]//确定细分factor equal_spacing fractional_even_spacing
            [UNITY_outputtopology("triangle_cw")]//确定组装顺序
            [UNITY_patchconstantfunc("hsconst")]//一个patch三个顶点，但三个顶点公用这个函数
            [UNITY_outputcontrolpoints(3)]//输出的控制点数量
            TessOutPut hullShader(InputPatch<TessOutPut,3> patch,uint id : SV_OutputControlPointID)
            {
                return patch[id]; 
            }

            [UNITY_domain("tri")] //该特性确定SV_DOMAINLOCATION，矩形和线都是xy坐标，三角形因其在空间中无法用xy坐标表示，所以需要重心坐标
            v2f ds(UnityTessellationFactors tessFactors,const OutputPatch<TessOutPut,3> patch,float3 bary:SV_DomainLocation)
            {
                appdata v;
                //每个细分顶点都会产生一组重心坐标
                //根据重心坐标重新定位，在转换到clip空间下进行最终渲染
                v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
                v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
                v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
                v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
                v2f o = vert(v);
                return o;
            }
            

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
    }
}
