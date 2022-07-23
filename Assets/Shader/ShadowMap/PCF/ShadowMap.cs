using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowMap : MonoBehaviour
{

    public Camera LdirCamera;

    public Light LDirLight;

    public Shader DepthShader;

    [Range(0.001f, 1)] public float ShadowStrange;

    [Range(0, 1)] public float CutOff;

    [Range(0, 1)] public float ShadowBias;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
