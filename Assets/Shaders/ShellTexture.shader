Shader "Custom/Shell Texture" {
    Properties {
        _ShellColor ("Color", Color) = (1, 1, 1, 1)
        _Density ("Shell Density", int) = 100
        _ShellNumber ("Shell Number", int) = 16
        _ShellDistance ("Shell Distance", range(0, 1)) = 0.1
        _MinNoiseThreshold ("Minimum Noise Threshold", float) = 0.01
        _MaxNoiseThreshold ("Maximum Noise Threshold", float) = 0.01
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        Cull Off

        Pass {
            CGPROGRAM
            #pragma vertex vertex_program
            #pragma fragment fragment_program
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            float4 _ShellColor;                 // The base color of the shells. Is used by the fragment shader to determine the final value after the lighting calculation.
            int _Density;                       // Value used to generate a random number. Gets multiplied by the uv coordinates to generate more strands per uv pair.
            int _ShellNumber;                   // Final number of shells on the mesh. This is used to calculate the desired height between each shells.
            float _ShellDistance;               // Distance between each shell
            int _ShellIndex;                    // Tells the GPU which shell is being computed.
            float _MinNoiseThreshold, _MaxNoiseThreshold;  // Used to linearly interpolate the result of the hash function.

            // The vertex_data struct collects data per each vertex of the mesh
            // this structure will be read by the vertex shader
            struct vertex_data {
                float4 vertex : POSITION;       // object-space position: the actual vertex coordinates
                float2 uv : TEXCOORD;           // Meh UV coordinates
                float3 normal : NORMAL;         // object-space normal

            };

            // The vertex2fragment struct contains the output of the vertex program, already interpolated
            struct vertex2fragment {
                float4 position : SV_POSITION;  // clip space interpolated position
                float2 uv : TEXCOORD0;          // interpolated uv
                half3 normal : TEXCOORD1;       // world space normal

            };

            // This hash function is available at https://www.shadertoy.com/view/llGSzw,
            // under the MIT License
            float hash11( uint n ) {
                // integer hash copied from Hugo Elias
                n = (n << 13U) ^ n;
                n = n * (n * n * 15731U + 789221U) + 1376312589U;
                return float( n & uint(0x7fffffffU))/float(0x7fffffff);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // The vertex program operates on the data read from each vertex of the mesh
            // and outputs a vertex2fragment struct
            // The vertex shader runs once per vertex
            vertex2fragment vertex_program(vertex_data v) {
                // i stands for interpolator, and is just typical nomenclature. 'o' is also used sometimes, for 'output'
                vertex2fragment i;


                float shellHeight = float(_ShellIndex)/float(_ShellNumber);     // Normalize the shell height, so that it varies from [0f to 1f]
                float displacement = shellHeight * _ShellDistance;              // Determine the offset of each shell, normalizing the result such that the last shell is at the full distance.
                v.vertex.xyz += v.normal * displacement;                        // displaces the vertex alongside the normal, using the previously calculated displacement amount.

                // This takes the vertex coordinate (which is object space), and applies a transformation to move it like so:
                // object space -> world space -> view space -> clip space.
                // It is equivalent to mul(UNITY_MATRIX_MVP, v.vertex).
                // This is mandatory, as the rasterizer only understands clip space.
                i.position = UnityObjectToClipPos(v.vertex);
                // We don't need to manipulate anything here, just passing along the data.;
                i.uv = v.uv;

                // Normals, lighting vectors etc would also be computed here.
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.normal = normalize(i.normal);

                return i;
            }

            // The fragment shader runs once per pixel
            // the inputs are already interpolated
            // and it always outputs the pixel color
            // SV_Target means the target is the output render target color

            float4 fragment_program(vertex2fragment i) : SV_Target {
                float2 local_uv = i.uv * _Density;  // multiply the uv coordinates by the density parameters, which allow the surface to have more strands in it.


                float ndotl = DotClamped(i.normal, _WorldSpaceLightPos0);  // lambertian diffuse is the dot product between the normal and the light direction.

                uint2 seed_uv = local_uv;

                uint seed = seed_uv.x + 100 * seed_uv.y + 100 * 10;  // organizes the uv in a grid

                float height = float(_ShellIndex)/float(_ShellNumber);

                float random = lerp(_MinNoiseThreshold, _MaxNoiseThreshold, hash11(seed));  // Interpolates the result of the hash into controllable parameters, making it possible to customize the look

                if (random < height) {
                    discard;
                }

                float ambientOcclusion = 1;  // By multiplying the pixel color by its height value, a dead-simple ambient occlusion can be faked.
                // float ambientOcclusion = height;  // By multiplying the pixel color by its height value, a dead-simple ambient occlusion can be faked.
                return _ShellColor * ndotl *  ambientOcclusion;  // Shade the pixel based on the lighting calculation and the (fake) ambient occlusion factor.

            }
            ENDCG
        }
    }
}