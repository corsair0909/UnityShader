using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DOF2 : MonoBehaviour
{
    public Shader shader;

    public Material mat;

    [Range(1, 4)] public int dowmSample;

    [Range(0, 1)] public float blurSmooth;

    [Range(1, 10)] public int loop;

    public float forceDistance;

    public Camera _camera;

    public float Near;
    public float Far;
    
    private void OnEnable()
    {
        //_camera = Camera.main;
        _camera.depthTextureMode |= DepthTextureMode.Depth;  

        mat = new Material(shader);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (mat)
        {
            forceDistance = Mathf.Clamp(forceDistance, _camera.nearClipPlane, _camera.farClipPlane);
        
            RenderTexture temp1 = RenderTexture.GetTemporary(Screen.width/dowmSample,Screen.height/dowmSample,0);
            RenderTexture temp2 = RenderTexture.GetTemporary(Screen.width/dowmSample,Screen.height/dowmSample,0);
            Graphics.Blit(src,temp1,mat,0);
            for (int i = 0; i < loop; i++)
            {
                mat.SetVector("_Offsets",new Vector4(0,blurSmooth+i*0.5f,0,0));
                Graphics.Blit(temp1,temp2,mat,0);
                RenderTexture.ReleaseTemporary(temp1);
                temp1 = temp2;
                temp2 = RenderTexture.GetTemporary(Screen.width/dowmSample,Screen.height/dowmSample,0);
                mat.SetVector("_Offsets",new Vector4(blurSmooth+i*0.5f,0,0,0));
                Graphics.Blit(temp1,temp2,mat,0);
                RenderTexture.ReleaseTemporary(temp1);
                temp1 = temp2;
            }
            mat.SetTexture("_BlurTex",temp2);
            mat.SetFloat("_forceDistance",FocalDistance01(forceDistance));
            mat.SetFloat("_farScale",Far);
            mat.SetFloat("_nearScale",Near);
            
            Graphics.Blit(src,dest,mat,1);  
            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }
        else
        {
            Graphics.Blit(src,dest);
        }

    }
    private float FocalDistance01(float distance)  
    {  
        return _camera.WorldToViewportPoint((distance - _camera.nearClipPlane) * _camera.transform.forward 
                                            + _camera.transform.position).z / (_camera.farClipPlane - _camera.nearClipPlane);  
    }  
}
