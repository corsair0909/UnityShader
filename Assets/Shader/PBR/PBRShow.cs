using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PBRShow : MonoBehaviour
{
    public Transform PBRItem;

    public float Speed;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        PBRItem.Rotate(Vector3.up,Time.deltaTime *Speed,Space.World);
    }
}
