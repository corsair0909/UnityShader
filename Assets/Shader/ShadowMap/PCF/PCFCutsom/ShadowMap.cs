using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowMap : MonoBehaviour
{

    public Camera ldirCamera;

    public Light lDirLight;

    public Shader depthShader;

    private ShadowMapResulotionItem initResulotion = ShadowMapResulotionItem.Mid;
    public ShadowMapResulotionItem newResulotion = ShadowMapResulotionItem.Mid;

    [Range(0.001f, 1)] public float shadowStrange;

    [Range(0, 1)] public float cutOff;

    [Range(0, 1)] public float shadowBias;

    public enum ShadowMapResulotionItem
    {
        Low = 4,
        Mid = 8,
        High = 16
    }

    /// <summary>
    /// 初始化用于渲染深度图的光源方向相机
    /// 只用来渲染深度，什么都不干
    /// </summary>
    private void InitDirLightCamera()
    {
        // GameObject go = new GameObject("DirCamera");
        // Camera lightCam = go.AddComponent<Camera>();
        // ldirCamera.transform.SetParent(lDirLight.transform);
        //设置相机的视角和灯光相同
        // ldirCamera.transform.localPosition = new Vector3(0, 0, 0);
        // ldirCamera.transform.localRotation = new Quaternion(0, 0, 0,0);
        
        ldirCamera.clearFlags = CameraClearFlags.SolidColor;
        
        //背景色设置为白色，表示无限远，为了确保深度对比不出问题
        ldirCamera.backgroundColor = Color.white;
        
        //设置为正交透视，模拟方向光平行且无限远的照射方式
        ldirCamera.orthographic = true;
        
        ldirCamera.nearClipPlane = 0.3f;
        ldirCamera.farClipPlane = 200;
        ldirCamera.allowMSAA = false;
        ldirCamera.allowHDR = false;
        ldirCamera.cullingMask = 1 << LayerMask.NameToLayer("ShadowCaster");
        //ldirCamera = lightCam;
    }
    private RenderTexture creatTexture(int resulotion)
    {
        RenderTextureFormat reFormat = RenderTextureFormat.Default;
        RenderTexture ShadowMap = new RenderTexture(512 * resulotion, 512 * resulotion, 24, reFormat);
        ShadowMap.hideFlags = HideFlags.DontSave;
        Shader.SetGlobalTexture("_gShadowMapTexture",ShadowMap);
        return ShadowMap;
    }
    
    void Start()
    {
        InitDirLightCamera();
        if (!ldirCamera.targetTexture)
        {
            ldirCamera.targetTexture = creatTexture((int)initResulotion);
        }
    }
    
    void Update()
    {
        //Unity中的ShadowMap是一张可以修改分辨率的RenderTexture
        if (newResulotion != initResulotion)
        {
            var per = ldirCamera.targetTexture;
            if (per)
            {
                per.Release();
            }
        
            ldirCamera.targetTexture = creatTexture((int)newResulotion);
            initResulotion = newResulotion;
        }
        Shader.SetGlobalFloat("_ShadowStrange",shadowStrange);
        Shader.SetGlobalFloat("_ShadowBias",shadowBias);
        Shader.SetGlobalFloat("_CutOff",cutOff);
        
        //GL.GetGPUProjectionMatrix用于处理不同平台投影矩阵的差异
        //设置片段从世界空间变换到光源位置相机的投影空间矩阵
        Matrix4x4 projectMat = GL.GetGPUProjectionMatrix(ldirCamera.projectionMatrix, false);
        Shader.SetGlobalMatrix("_gWorldToLdirCameraMatrix",projectMat * ldirCamera.worldToCameraMatrix);
        
        //使用深度shader渲染深度图
        ldirCamera.RenderWithShader(depthShader,"");
    }
}
