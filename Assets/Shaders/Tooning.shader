Shader "Custom/Tooning"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.4
        _ShadowSoftness ("Shadow Softness", Range(0.01, 0.5)) = 0.1
        _Glossiness ("Glossiness", Range(1.0, 200.0)) = 32
        _SpecularThreshold ("Specular Threshold", Range(0.0, 1.0)) = 0.8
        _SpecularSoftness ("Specular Softness", Range(0.0, 1.0)) = 0.05
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimThreshold ("Rim Threshold", Range(0, 1)) = 0.5
        _RimSoftness ("Rim Softness", Range(0.01, 1.0)) = 0.05
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
                float3 positionWS  : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                half4 _RimColor;
                float _ShadowThreshold;
                float _ShadowSoftness;
                float _Glossiness;
                float _SpecularSoftness;
                float _SpecularThreshold;
                float _RimSoftness;
                float _RimThreshold;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
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
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
                float3 normal = normalize(IN.normalWS); 
                float3 lightDir = normalize(mainLight.direction); 
                float3 halfVec = normalize(viewDir + lightDir);
                float NdotL = saturate(dot(normal, lightDir)); 
                float NdotH = saturate(dot(normal, halfVec));
                float NdotV = saturate(dot(normal, viewDir));
                float shine = pow(NdotH, _Glossiness);
                float fresnel = 1.0 - NdotV;
                float qdot = quantize(NdotL); 
                float toonLight = smoothstep( _ShadowThreshold - _ShadowSoftness, _ShadowThreshold + _ShadowSoftness, qdot );
                float toonShine = smoothstep(_SpecularThreshold - _SpecularSoftness, _SpecularThreshold + _SpecularSoftness, shine);
                float toonFresnel = smoothstep(_RimThreshold - _RimSoftness, _RimThreshold + _RimSoftness, fresnel) * _RimColor * toonLight;
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor; 
                float3 color = (albedo.rgb * toonLight) + toonShine + toonFresnel; 
                return half4(color, albedo.a);
            }
            ENDHLSL
        }
    }
}
