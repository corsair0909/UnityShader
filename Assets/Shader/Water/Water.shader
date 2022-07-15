Shader "Unlit/Water"
{
    Properties
    {
        _Color ("Color",color) = (1,1,1,1)
        
        [Space(10)]
        
        [Header(Texture)]
        [Space(5)]
        _MainTex ("MainTex", 2D) = "white" {}
        _FlowMap ("FlowMap", 2D) = "white" {}
        _NormalMap("Derivative",2D) = "White"{}
        
        [Space(5)]
        [Header(LightParameter)]
        [Space(5)]
        _NormalScale("NormalScale",range(0,4)) = 0.5
        _Gloss("Gloss",range(30,90)) = 70
        
        [Space(15)]
        [Header(FlowParameter)]
        [Space(5)]
        _FlowStrange ("FlowStrange",range(0,3)) = 0.2
        _FlowSpeed ("FlowSpeed",range(0,5)) = 0.2
        _FlowOffset ("FlowOffset",range(0,5)) = 0.2
        _Jump1("JumpA",range(0,0.25)) = 0
        _Jump2("JumpB",range(0,0.25)) = 0
        _Tiling("Tiling",float) = 0
        
        [Space(15)]
        [Header(WaveParameter)]
        //_Amplitude("Amplitude(波振幅)",float) = 0.45
//        _WaveLength("WaveLength(波长)",float) = 0
        _WaveSpeed("WaveSpeed(波速度)",float) = 1
//        _Steepness("Steepness",range(0,1)) = 0.5
//        _WaveDirection("WaveDir(2D)",vector) = (1,0,0,0)
        
        _WaveA("WaveA(dir,steepness,wavelength)",vector) = (1,1,0.5,50)
        _WaveB("WaveB",vector) = (0,1,0.25,20)
        _WaveC("WaveC",vector) = (1,1.3,0.25,18)
        
        [Space(15)]
        [Header(AlphaParameter)]
        _WaterAlpha("WaterAlpha",range(0,1)) = 1
        _WaterDepth("WaterDepth",range(0,100)) = 20
        [Space(5)]
        [Header(FogParameter)]
        [HDR]_FogColor("FogColor",color) = (1,1,1,1)
        _FogDensity("FogDensity",range(0,1)) = 0
        
        [Header(RefractStranger)]
        _RefractPower("RefractPower",range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        LOD 100
        
        GrabPass {"_WaterBackground"}

        Pass
        {
            //Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "Assets/Shader/MyShaderLabs.cginc"

            struct appdata
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
                float3 LdirTS : TEXCOORD1;
                float3 VdirTS : TEXCOORD2;
                float4 ScreenPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowMap;
            sampler2D _NormalMap;
            
            fixed _FlowStrange,_FlowSpeed,_FlowOffset;
            fixed _Jump1,_Jump2;
            fixed _Tiling;
            fixed _NormalScale,_Gloss;

            fixed _WaveSpeed;//_Amplitude,_WaveLength,_Steepness;
            //fixed4 _WaveDirection;
            fixed4 _WaveA,_WaveB,_WaveC;

            fixed _WaterAlpha,_WaterDepth;


            half4 _Color;

            float3 WaveValue(float4 wave,float3 vertex)
            {
                //float3 Wave;

                float length = wave.w;
                float steepness = wave.z;
                //正弦波总长度为2PI，2PI/波长 = 波数
                float waveNum = 2 * UNITY_PI / length;
                
                float a = steepness/waveNum;//防循环

                float2 dir = normalize(wave.xy);
                
                
                float f = waveNum*(dot(dir,vertex.xz) - _WaveSpeed*_Time.y);//波数 * （顶点加上偏移量（正负方向））
                
                return float3(dir.x*(a*cos(f)),
                                a*sin(f),
                                dir.y * (a*cos(f)));
            }
            
            
            v2f vert (appdata v)
            {
                v2f o;

                float4 WaveVertex = v.vertex;
                float4 wave = WaveVertex;
                //叠加波形
                wave.xyz += WaveValue(_WaveA,wave);
                wave.xyz +=WaveValue(_WaveB,wave);
                wave.xyz +=WaveValue(_WaveC,wave);
                WaveVertex = wave;
                //将顶点动画计算过的顶点变换到裁剪空间下
                o.vertex = UnityObjectToClipPos(WaveVertex);

                o.ScreenPos = ComputeScreenPos(o.vertex);
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                TANGENT_SPACE_ROTATION;
                o.LdirTS = mul(rotation,ObjSpaceLightDir(v.vertex));
                o.VdirTS = mul(rotation,ObjSpaceViewDir(v.vertex));
                return o;
            }


            float3 FlowUVW(float2 uv,float2 offset,float tiling,float2 jump,float time,bool flow)
            {
                //jump部分没看懂
                
                float LoopOffset = flow? 0.5:0;//函数偏移半个周期
                float pregress = frac(time+LoopOffset);//将两次偏移错开半个周期，否则，取小数部分，否则会出现bug
                float3 UVW;//带有权重的返回值，W分量保存权重

                UVW.xy = uv - offset * (pregress+_FlowOffset);//uv偏移计算
                //缩放uv
                UVW.xy *= tiling;
                //每秒循环两次，采样结果也错开半个周期
                UVW.xy +=LoopOffset;
                //构造相差半个周期的权重，W(1) = W(0) = 0 ，W(1/2) = W(1/2) = 1 ，
                UVW.z = 1-abs(1-2*pregress);
                return UVW;
            }

            // float3 UnpackDerivativeMap(float4 var_DerivativeMap)
            // {
            //     float3 rgb = var_DerivativeMap.agb;
            //     rgb.xy *= 2 - 1;
            //     return rgb;
            // }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 LdirTS = normalize(i.LdirTS);
                float3 VdirTS = normalize(i.VdirTS);
                
                float2 var_FlowMap = tex2D(_FlowMap,i.uv).rg * 2 - 1 ;
                var_FlowMap *= _FlowStrange;
                
                float noise  = tex2D(_FlowMap,i.uv).a;//A通道中保存噪声
                float time = _Time.y * _FlowSpeed + noise;

                float2 jump = float2(_Jump1,_Jump2);

                //FlowMap UV 计算，flowmap的每个像素保存着一个移动方向，
                //z分量保存当前权重值，权重值根据flow函数W(1) = W(0) = 0 ，W(1/2) = W(1/2) = 1计算
                float3 uv1 = FlowUVW(i.uv,var_FlowMap,_Tiling,jump,time,true);
                float3 uv2 = FlowUVW(i.uv,var_FlowMap,_Tiling,jump,time,false);
                
                //解码法线贴图
                half3 var_Normal1 = UnpackNormalWithScale(tex2D(_NormalMap,uv1.xy),_NormalScale) * uv1.z;
                half3 var_Normal2 = UnpackNormalWithScale(tex2D(_NormalMap,uv2.xy),_NormalScale) * uv2.z;
                half3 NDir = normalize(var_Normal1+var_Normal2);

                //光照计算部分
                fixed NdotL = saturate(dot(NDir,LdirTS)) * 0.5f + 0.5f;
                fixed3 halfWay = normalize(VdirTS+LdirTS);
                fixed NdotH = saturate(dot(NDir,halfWay));
                
                half4 var_MainTex1 = tex2D(_MainTex,uv1.xy) * uv1.z;
                half4 var_MainTex2 = tex2D(_MainTex,uv2.xy) * uv2.z;

                //叠加计算结果
                fixed3 diffuse = (var_MainTex1.rgb+var_MainTex2.rgb)  * NdotL;
                fixed3 specular = _LightColor0.rgb * pow(NdotH,_Gloss);
                fixed3 emissive = ColorBlowWater(i.ScreenPos,NDir) * (1-_Color.a);
                fixed3 finalColor = (diffuse+specular+emissive) *  _Color.rgb;
                return fixed4(finalColor,_Color.a);
            }
            ENDCG
        }
    }
}
