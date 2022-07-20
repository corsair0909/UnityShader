Shader "Unlit/WaveTransmitShader"
{
   Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/Shader/MyShaderLabs.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
			sampler2D _PrevMarkTexture; //上一帧波浪位置标记
			float4 _TransmitParameter;//波浪传递参数
			float _WaveAtten;//波浪衰减
            float2 WaveDir[4] = {float2(1,0),float2(0,1),float2(-1,0),float2(0,-1)};


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                return o;
            }
            
            
            fixed4 frag (v2f i) : SV_Target
            {

				float dx = _TransmitParameter.w;

				float avgWaveHeight = 0;
				for (int s = 0; s < 4; s++)
				{
					avgWaveHeight += DecodeHeight(tex2D(_MainTex, i.uv + WaveDir[s] * dx));
				}

				//(2 * c^2 * t^2 / d ^2) / (u * t + 2)*(z(x + dx, y, t) + z(x - dx, y, t) + z(x, y + dy, t) + z(x, y - dy, t);
				float agWave = _TransmitParameter.z * avgWaveHeight;
				
				// (4 - 8 * c^2 * t^2 / d^2) / (u * t + 2)
				float curWave = _TransmitParameter.x *  DecodeHeight(tex2D(_MainTex, i.uv));
				// (u * t - 2) / (u * t + 2) * z(x,y,z, t - dt) 上一次波浪值 t - dt
				float prevWave = _TransmitParameter.y * DecodeHeight(tex2D(_PrevMarkTexture, i.uv));

				//波衰减
				float waveValue = (curWave + prevWave + agWave) * _WaveAtten;
                return EncodeHeight(waveValue);
            }
            ENDCG
        }
    }
}
