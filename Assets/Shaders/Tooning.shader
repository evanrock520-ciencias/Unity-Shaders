Shader "Custom/Tooning"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.4
        _ShadowSoftness ("Shadow Softness", Range(0.01, 0.5)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _ShadowThreshold;
                float _ShadowSoftness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            float quantize(float dot)
            {
                if (dot < 0.35)
                    return 0.1;

                if (dot < 0.65)
                    return 0.5;
                
                return 1.0;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight(); 
                float3 normal = normalize(IN.normalWS); 
                float3 lightDir = normalize(mainLight.direction); 
                float NdotL = saturate(dot(normal, lightDir)); 
                float qdot = quantize(NdotL); 
                float toonLight = smoothstep( _ShadowThreshold - _ShadowSoftness, _ShadowThreshold + _ShadowSoftness, qdot ); 
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor; 
                float3 color = albedo.rgb * toonLight; 
                return half4(color, albedo.a);
            }
            ENDHLSL
        }
    }
}
