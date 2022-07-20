# ifndef MySHADERLABS
    # define MySHADERLABS

    
//https://zhuanlan.zhihu.com/p/95986273 噪声生成算法来源
float2 hash22(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float2 hash21(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return -1.0 + 2.0 * frac(sin(h) * 43758.5453123);
}

//perlin
float perlin_noise(float2 p) {
    float2 pi = floor(p);
    float2 pf = p - pi;
    float2 w = pf * pf * (3.0 - 2.0 * pf);
    return lerp(lerp(dot(hash22(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
        dot(hash22(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x),
        lerp(dot(hash22(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
            dot(hash22(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x), w.y);
}

sampler2D _CameraDepthTexture,_WaterBackground;
float4 _CameraDepthTexture_TexelSize;
fixed _FogDensity;
half4 _FogColor;
fixed _RefractPower;
float3 ColorBlowWater(float4 ScreenPos,float3 NdirTS)
{
    float2 offset = NdirTS.xy * _RefractPower;
    offset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
    float2 DepthPos = (ScreenPos.xy+offset) / ScreenPos.w;
    #if UNITY_UV_STARTS_AT_TOP
        if (_CameraDepthTexture_TexelSize.y < 0)
        {
            DepthPos.y = 1-DepthPos.y;
        }
    #endif
    
    float BottmDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,DepthPos));
    
    //效果相同 ScreenPos的Z分量是插值出的裁剪空间深度 UNITY_Z_0_FAR_FROM_CLIPSPACE宏将其转换为线性深度
    //float TopDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(ScreenPos.z);
    float DepthDifference = BottmDepth - ScreenPos.w;
    
    if (DepthDifference<0)//水面上的物体uv不发生折射
    {
        DepthPos = ScreenPos.xy/ScreenPos.w;
        #if UNITY_UV_STARTS_AT_TOP
            if (_CameraDepthTexture_TexelSize.y < 0)
            {
                DepthPos.y = 1-DepthPos.y;
            }
        #endif
    }
    //使用没有折射的uv重新采样
    BottmDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,DepthPos));
    DepthDifference = BottmDepth - ScreenPos.w;
    
    float3 background = tex2D(_WaterBackground,DepthPos);
    float fogFactor = exp(-_FogDensity * DepthDifference);
    return lerp(_FogColor,background,fogFactor);
    
    //return DepthDifference/WaterDepth;
}


float4 EncodeHeight(float height) {
    float2 rg = EncodeFloatRG(height > 0 ? height : 0);
    float2 ba = EncodeFloatRG(height <= 0 ? -height : 0);
    return float4(rg, ba);
}

float DecodeHeight(float4 rgba) {
    float h1 = DecodeFloatRG(rgba.rg);
    float h2 = DecodeFloatRG(rgba.ba);

    int c = step(h2, h1);
    return lerp(h2, h1, c);
}


#endif
