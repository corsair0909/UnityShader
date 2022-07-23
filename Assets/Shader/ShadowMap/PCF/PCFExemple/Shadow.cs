using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Shadow : MonoBehaviour
{
    public Light DirLight;
    public Camera DirLightCamera;
    public Shader DirLightDepthShader;
    [Range(-0.01f, 0.01f)]
    public float ShadowBias = 0.005f;
    [Range(0, 0.5f)]
    public float CutOff = 0.1f;
    [Range(0, 1)]
    public float ShadowStrength = 0.5f;
    public enum ShadowResolution
    {
        Low = 4,
        Middle = 8,
        High = 16,
    }
    public ShadowResolution shadowResolution = ShadowResolution.Middle;
    private ShadowResolution changeShadowResolution = ShadowResolution.Middle;
    void Start()
    {
        ResetCaneraArgs(ref DirLightCamera);//设置相机参数让相机视野覆盖整个场景
        if (!DirLightCamera.targetTexture)
            DirLightCamera.targetTexture = Create2DTexture((int)shadowResolution);
    }
    private void ResetCaneraArgs(ref Camera lightCamera)
    {
        lightCamera.backgroundColor = Color.white;
        lightCamera.clearFlags = CameraClearFlags.SolidColor;
        lightCamera.orthographic = true;
        lightCamera.orthographicSize = 30f;
        lightCamera.nearClipPlane = 0.3f;
        lightCamera.farClipPlane = 200f;
        lightCamera.enabled = false;
        lightCamera.allowMSAA = false;
        lightCamera.allowHDR = false;
        lightCamera.cullingMask = 1 << LayerMask.NameToLayer("Caster");  //设置CullingMask为"Caster"，也就是说只有图层标记为"Caster"的物体才参与深度计算。
    }
    private RenderTexture Create2DTexture(int shadowResolution)
    {
        RenderTextureFormat rtFormat = RenderTextureFormat.Default;
        RenderTexture ShadowMap = new RenderTexture(512 * shadowResolution, 512 * shadowResolution, 24, rtFormat);
        ShadowMap.hideFlags = HideFlags.DontSave;
        Shader.SetGlobalTexture("_gShadowMapTexture", ShadowMap);
        return ShadowMap;
    }
    void Update()
    {
        //运行时调整阴影图分辨率
        if (changeShadowResolution != shadowResolution)
        {
            //释放之前的相机渲染纹理
            var preTex = DirLightCamera.targetTexture;
            if (!preTex)
            {
                preTex.Release();
            }
            //使用新分辨率的纹理
            DirLightCamera.targetTexture = Create2DTexture((int)shadowResolution);
            changeShadowResolution = shadowResolution;
        }
        Shader.SetGlobalFloat("_gShadowBias", ShadowBias);
        Shader.SetGlobalFloat("_clipValue", CutOff);
        Matrix4x4 PMatrix = GL.GetGPUProjectionMatrix(DirLightCamera.projectionMatrix, false);  //处理不同平台投影矩阵的差异性
        Shader.SetGlobalMatrix("_gWorldToShadow", PMatrix * DirLightCamera.worldToCameraMatrix); //当前片段从世界坐标转换到光源相机空间坐标
        Shader.SetGlobalFloat("_gShadowStrength", ShadowStrength);
        DirLightCamera.RenderWithShader(DirLightDepthShader, ""); //将相机使用指定shader渲染相机的屏幕
    }
}
