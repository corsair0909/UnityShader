using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class TrackMouse : MonoBehaviour
{
    Material mat;
    Camera camera;
    Vector4 mouse;
    // Start is called before the first frame update
    void Start()
    {
        Renderer render = GetComponent<Renderer>();
        mat = render.material;
        mouse.z = Screen.width;
        mouse.w = Screen.height;
        camera = Camera.main;
    }

    // Update is called once per frame
    void Update()
    {
        RaycastHit hit;
        Ray ray = camera.ScreenPointToRay(Input.mousePosition);
        if(Physics.Raycast(ray,out hit))
        {
            mouse.x = hit.textureCoord.x;
            mouse.y = hit.textureCoord.y;
        }
        mat.SetVector("_mouse",mouse);
    }
}
