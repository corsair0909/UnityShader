using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterPointPos : MonoBehaviour
{
    //水面
    public Transform waterPlane;
    public float waterPlaneWidth;
    public float waterPlaenHeight;
    
    //波浪参数
    public float waveRandius = 1.0f;
    public float waveSpeed = 1.0f;
    public float waveViscosity = 1.0f; //粘度
    public float waveAtten = 0.99f; //衰减
    public float waveHeight = 0.999f;
    
    //renderTexture参数
    private int renderTextureResolution = 128;
    private RenderTexture _waterWaveMarkTexture;//碰撞位置标记tex
    private RenderTexture _waterWaveTransmitTexture;//传播标记tex
    private RenderTexture _prevWaveMarkTexture;//上一帧波浪传递位置tex

    public Material _MarkMat;//碰撞位置mat
    public Material _TransmitMat;//传播位置mat
    
    public UnityEngine.UI.RawImage WaveMarkDebugImg;
    public UnityEngine.UI.RawImage WaveTransmitDebugImg;
    public UnityEngine.UI.RawImage PrevWaveTransmitDebugImg;

    private Vector4 _waveParameter;

    private void Awake()
    {
        _waterWaveMarkTexture = new RenderTexture(renderTextureResolution, renderTextureResolution, 0,
            RenderTextureFormat.Default);
        _waterWaveMarkTexture.name = "MarkPosTexture";
        
        _waterWaveTransmitTexture = new RenderTexture(renderTextureResolution, renderTextureResolution, 0,
            RenderTextureFormat.Default);
        _waterWaveTransmitTexture.name = "TransmitPosTexture";
        
        _prevWaveMarkTexture = new RenderTexture(renderTextureResolution, renderTextureResolution, 0,
            RenderTextureFormat.Default);
        _prevWaveMarkTexture.name = "PrevMarkTexture";
        
        //传递波浪碰撞位置和波浪高度
        Shader.SetGlobalTexture("_WaveResult", _waterWaveMarkTexture);
        Shader.SetGlobalFloat("_WaveHeight", waveHeight);

        _MarkMat = new Material(Shader.Find("Unlit/WaveMarkShader"));
        _TransmitMat = new Material(Shader.Find("Unlit/WaveTransmitShader"));
        
        WaveMarkDebugImg.texture = _waterWaveMarkTexture;
        WaveTransmitDebugImg.texture = _waterWaveTransmitTexture;
        PrevWaveTransmitDebugImg.texture = _prevWaveMarkTexture;

        
        InitWaveTransmitParameter();
    }

    private void OnPreRender()
    {
        WaterWaveHitPos();
        MarkPos();
        TransmitPos();
    }

    private Vector2 hitPos = new Vector2(0, 0);
    private bool isMakr;
    /// <summary>
    /// 计算交互点
    /// </summary>
    void WaterWaveHitPos()
    {
        if (Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit = new RaycastHit();
            bool result = Physics.Raycast(ray.origin, ray.direction, out hit);//返回射线碰撞结果
            //Debug.Log(hit.collider.gameObject.name);
            if (result)
            {
                //碰撞点默认在世界空间，需要变换到本地空间才能进行顶点动画
                Vector3 waterPlanePos =waterPlane.worldToLocalMatrix *new Vector4(hit.point.x, hit.point.y, hit.point.z,1);
                //Debug.Log(waterPlanePos);
                //缩放到【0-1区间】
                float dx = (waterPlanePos.x / waterPlaneWidth) + 0.5f;
                float dy = (waterPlanePos.z / waterPlaenHeight) + 0.5f;
                
                hitPos.Set(dx,dy);//TODO 多余的设置
                _waveParameter.Set(dx,dy,waveRandius*waveRandius,waveHeight);
            }

            isMakr = true;
        }
    }


    private Vector4 TransmitParameter = new Vector4(0, 0, 0, 0);
    void InitWaveTransmitParameter()
    {
        //波传递公式
        //c : 波速
        //u : 粘度
        //d ：递进距离
        //t ：时间
        // (4 - 8 * c^2 * t^2 / d^2) / (u * t + 2)  当前波值
        // +(u * t - 2) / (u * t + 2)  上一次波值
        // + (2 * c^2 * t^2 / d ^2) / (u * t + 2) 四周波值
        //波的下次一次传递 z(i,j,k+1) 为 当前波值+上一次波值+周围波值

        float Step = 1.0f / renderTextureResolution;

        float t = Time.fixedDeltaTime;
        
        //最大递进距离
        float maxWaveStepVisosity = Step / (2 * t) * (Mathf.Sqrt(waveViscosity * t + 2));
        
        //float Viscosity2 = waveViscosity * waveViscosity;
        float CurSpeed = waveSpeed * maxWaveStepVisosity;
        float Speed2 = CurSpeed * CurSpeed;
        float Step2 = Step * Step;

        float ut = waveViscosity * t;
        float utAdd2 = ut + 2;
        float utMins2 = ut - 2;
        float curSqrt = Speed2 * t * t / Step2;

        float curWave = (4 - 8) * curSqrt / utAdd2;
        float lastWave = utAdd2 / utMins2;
        float aroundWave = 2 * curSqrt / utAdd2;
        TransmitParameter.Set(curWave,lastWave,aroundWave,Step);
        Debug.Log(TransmitParameter);
    }
    
    /// <summary>
    /// 传递交互点
    /// </summary>
    void MarkPos()
    {
        _MarkMat.SetVector("_WaveParameter",_waveParameter);
        Graphics.Blit(_waterWaveTransmitTexture,_waterWaveMarkTexture,_MarkMat);
    }

    void TransmitPos()
    {
        _TransmitMat.SetVector("_TransmitParameter",TransmitParameter);
        _TransmitMat.SetFloat("_WaveAtten",waveAtten);
        _TransmitMat.SetTexture("_PrevMarkTexture",_prevWaveMarkTexture);
        RenderTexture rt = RenderTexture.GetTemporary(renderTextureResolution,renderTextureResolution);
        
        Graphics.Blit(_waterWaveMarkTexture,rt,_TransmitMat);
        Graphics.Blit(_waterWaveMarkTexture,_prevWaveMarkTexture);
        
        Graphics.Blit(rt,_waterWaveMarkTexture);//rt中保存了上一帧传递过的位置，传回到mark纹理为了记录上一帧的传递位置到_prevWaveMarkTexture
        Graphics.Blit(rt,_waterWaveTransmitTexture);//记录传递位置
        RenderTexture.ReleaseTemporary(rt);
    }
    
}
