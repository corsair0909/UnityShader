using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthNormalTexture : MonoBehaviour
{
    [SerializeField]
    DepthTextureMode _mode;
    private void OnValidate()
    {
        SetCameraDepthTextureMode();
    }

    private void Awake()
    {
        SetCameraDepthTextureMode();
    }

    private void SetCameraDepthTextureMode()
    {
        GetComponent<Camera>().depthTextureMode = _mode;
    }
}
