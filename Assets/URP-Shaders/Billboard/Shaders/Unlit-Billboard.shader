// URP-Unlit-Billboard Shader by @gam0022 (MIT Licence)
// https://gam0022.net//blog/2021/12/23/unity-urp-billboard-shader/
Shader "Universal Render Pipeline/Unlit-Billboard"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "IgnoreProjector" = "True" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS: SV_POSITION;
                float2 uv: TEXCOORD0;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Cutoff;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // 回転行列を生成してビルボード処理をします
                float3 yup = float3(0.0, 1.0, 0.0);
                float3 up = mul((float3x3)unity_ObjectToWorld, yup);

                float3 worldPos = unity_ObjectToWorld._m03_m13_m23;
                float3 toCamera = _WorldSpaceCameraPos - worldPos;
                float3 right = normalize(cross(toCamera, up));
                float3 forward = normalize(cross(up, right));

                float4x4 mat = {
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                };
                mat._m00_m10_m20 = right;
                mat._m01_m11_m21 = up;
                mat._m02_m12_m22 = forward;
                mat._m03_m13_m23 = worldPos;
                
                /*
                // このようにも書けるが、転置が必要
                float4x4 mat = {
                    right, 0,
                    up, 0,
                    forward, 0,
                    worldPos, 1,
                };
                mat = transpose(mat);
                */

                float4 vertex = float4(IN.positionOS.xyz, 1);
                vertex = mul(mat, vertex);
                OUT.positionHCS = mul(UNITY_MATRIX_VP, vertex);

                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN): SV_Target
            {
                half4 base = tex2D(_BaseMap, IN.uv);
                clip(base.a - _Cutoff);
                return base * _BaseColor;
            }
            ENDHLSL

        }
    }
}