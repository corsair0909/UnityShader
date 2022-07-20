using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Transport : MonoBehaviour
{
    public Transform Role;
    public Material roleMat;

    public float Speed;
    // Start is called before the first frame update
    void Start()
    {
        //roleMat = Role.GetComponent<Material>();
    }

    private float thrshold;

    private float i;
    // Update is called once per frame
    void Update()
    {
        i = roleMat.GetFloat("_Thrshold");
        i -= Time.fixedDeltaTime * Speed;
        roleMat.SetFloat("_Thrshold",i);
    }
}
