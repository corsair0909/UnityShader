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
    [Range(0, 0.999f)]
    public float waveHeight = 0.999f;
    
    //renderTexture参数
    private int renderTextureResolution = 512;
    private RenderTexture _waterWaveMarkTexture;//碰撞位置标记tex
    private RenderTexture _waterWaveTransmitTexture;//传播标记tex
    private RenderTexture _prevWaveMarkTexture;//渲染tex

    private Material _MarkMat;//碰撞位置mat
    private Material _TransmitMat;//传播位置mat

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

        //_MarkMat = new Material(Shader.Find());
        //_TransmitMat = new Material(Shader.Find());
        
        
    }

    private void OnPreRender()
    {
        WaterWaveHitPos();
    }

    private Vector2 hitPos = new Vector2(0, 0);

    void WaterWaveHitPos()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit = new RaycastHit();
            bool result = Physics.Raycast(ray.origin, ray.direction, out hit);//返回射线碰撞结果
            if (result)
            {
                //碰撞点默认在世界空间，需要变换到本地空间才能进行顶点动画
                Vector4 waterPlanePos =waterPlane.worldToLocalMatrix *new Vector4(hit.point.x, hit.point.y, hit.point.z,1);
                //缩放到【0-1区间】
                float dx = (waterPlanePos.x / waterPlaneWidth) + 0.5f;
                float dy = (waterPlanePos.y / waterPlaneWidth) + 0.5f;
                
                hitPos.Set(dx,dy);
                _waveParameter.Set(dx,dy,waveRandius*waveRandius,waveHeight);
            }
        }
    }
}
