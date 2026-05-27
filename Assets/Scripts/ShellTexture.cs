/* This script is used to control the appearance of the 
 * ShellTexture shader file. It is heavily inspired by
 * Jasper Flick's catlikecoking basics tutorials 
 */
using UnityEngine;

public class ShellShader : MonoBehaviour {
    [SerializeField]
    Mesh shellMesh;

    [SerializeField]
    Material shellMaterial;

    [SerializeField]
    Color shellColor = Color.greenYellow;

    [SerializeField]
    int shellNumber = 2;

    [SerializeField]
    int shellDensity = 100;

    [SerializeField, Range(0f, 1f)]
    float shellDistance = 0.5f;

    [SerializeField, Range(0f, 1f)]
    float minNoiseThreshold = 0.01f;

    private GameObject[] shells;

    // Shader properties
    private static readonly int
        shellColorId = Shader.PropertyToID("_ShellColor"),
        shellDensityId = Shader.PropertyToID("_Density"),
        shellNumberId = Shader.PropertyToID("_ShellNumber"),
        shellDistanceId = Shader.PropertyToID("_ShellDistance"),
        shellMinNoiseId = Shader.PropertyToID("_MinNoiseThreshold");

    void OnEnable() {
        shells = new GameObject[shellNumber];

        // iterate through the shells and create game objects
        for (int i = 0; i < shellNumber; ++i) {
            shells[i] = new GameObject("Shell " + i.ToString());
            shells[i].AddComponent<MeshFilter>();
            shells[i].AddComponent<MeshRenderer>();

            shells[i].GetComponent<MeshFilter>().mesh = shellMesh;
            shells[i].GetComponent<MeshRenderer>().material = shellMaterial;
            shells[i].transform.SetParent(this.transform, false);

            // Set all the parameters needed by the shader
            var shellRenderer = shells[i].GetComponent<MeshRenderer>().material;
            shellRenderer.SetVector(shellColorId, shellColor);
            shellRenderer.SetInt(shellDensityId, shellDensity);
            shellRenderer.SetInt(shellNumberId, shellNumber);
            shellRenderer.SetFloat(shellDistanceId, shellDistance);
            shellRenderer.SetInt("_ShellIndex", i);
            shellRenderer.SetFloat(shellMinNoiseId, minNoiseThreshold);


        }
    }

    void OnDisable() {
        for (int i = 0; i < shellNumber; ++i) {
            Destroy(shells[i]);
        }
    }


    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start() {

    }

    // Update is called once per frame
    void Update() {

    }
}
