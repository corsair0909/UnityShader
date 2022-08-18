using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class DOFCommanderBUffer : MonoBehaviour
{
    private CommandBuffer cmd;

    private Renderer _renderTarget;
    // Start is called before the first frame update
    void Start()
    {
        _renderTarget = GetComponent<Renderer>();
        if (_renderTarget)
        {
            cmd = new CommandBuffer();
            cmd.DrawRenderer(_renderTarget,_renderTarget.sharedMaterial);
            Camera.main.AddCommandBuffer(CameraEvent.AfterImageEffects,cmd);
            _renderTarget.enabled = false;
        }
    }

    private void OnDisable()
    {
        if (_renderTarget)
        {
            //移除事件，清理资源
            Camera.main.RemoveCommandBuffer(CameraEvent.AfterImageEffects, cmd);
            cmd.Clear();
            _renderTarget.enabled = true;
        }
    }
}
