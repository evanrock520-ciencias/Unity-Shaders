Shader "Custom/Silk"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        [Header(Shadows)]
        _ShadowColor ("Shadow Color", Color) = (0.5, 0.5, 0.5, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.4
        _ShadowSoftness ("Shadow Softness", Range(0.01, 0.5)) = 0.1

        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Glossiness ("Glossiness", Range(1.0, 500.0)) = 300
        _SpecularThreshold ("Specular Threshold", Range(0.0, 1.0)) = 0.8
        _SpecularSoftness ("Specular Softness", Range(0.0, 1.0)) = 0.05
        _AnisoOffset ("Aniso Position", Range(-1, 1)) = 0.0
            
        [Header(Rim Light)]
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimThreshold ("Rim Threshold", Range(0, 1)) = 0.5
        _RimSoftness ("Rim Softness", Range(0.01, 1.0)) = 0.05

        [Header(Toon Map)]
        _ToonSteps ("Toon Steps", Range(1, 10)) = 3
        _ToonSmoothness ("Toon Smothness", Range(0.01, 1.0)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_shadowcaster

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
            };

            Varyings ShadowPassVertex(Attributes IN) {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                
                OUT.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _MainLightPosition.xyz));
                return OUT;
            }

            half4 ShadowPassFragment(Varyings IN) : SV_Target {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthVertex
            #pragma fragment DepthFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 positionOS : POSITION;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
            };

            Varyings DepthVertex(Attributes IN) {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 DepthFragment(Varyings IN) : SV_Target {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD4;
                float2 uv : TEXCOORD0;
                float3 positionWS  : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                half4 _RimColor;
                float4 _ShadowColor;
                float _ShadowThreshold;
                float _ShadowSoftness;
                half4 _SpecularColor;
                float _Glossiness;
                float _SpecularSoftness;
                float _SpecularThreshold;
                float _AnisoOffset;
                float _RimSoftness;
                float _RimThreshold;
                float _ToonSteps;
                float _ToonSmoothness;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            float ToonStep(float value, float steps, float smothness)
            {
                float v = value * steps;
                float i = floor(v);
                float f = smoothstep(0.5 - smothness, 0.5 + smothness, frac(v));

                return (i + f) / steps;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight(IN.shadowCoord); 
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
                float3 normal = normalize(IN.normalWS); 
                float3 tangent = normalize(IN.tangentWS);
                float3 lightDir = normalize(mainLight.direction); 
                float3 halfVec = normalize(viewDir + lightDir);
                
                float NdotL = saturate(dot(normal, lightDir)); 
                float NdotH = saturate(dot(normal, halfVec));
                float NdotV = saturate(dot(normal, viewDir));

                float lightIntensity = NdotL * mainLight.shadowAttenuation; 
                float toonLight = ToonStep(lightIntensity, _ToonSteps, _ToonSmoothness);

                float TdotH = dot(tangent, halfVec);
                TdotH += _AnisoOffset;

                float anisoDist = sqrt(1.0 - (TdotH * TdotH)); 
                anisoDist = max(0, anisoDist);

                float shine = pow(anisoDist, _Glossiness);
                float toonShine = smoothstep(_SpecularThreshold - _SpecularSoftness, _SpecularThreshold + _SpecularSoftness, shine) * toonLight;

                float fresnel = 1.0 - NdotV;
                float3 toonFresnel = smoothstep(_RimThreshold - _RimSoftness, _RimThreshold + _RimSoftness, fresnel) * _RimColor.rgb * toonLight;

                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor; 
                
                float3 diffuseColor = lerp(albedo.rgb * _ShadowColor.rgb, albedo.rgb, toonLight);
                float3 finalColor = diffuseColor + (toonShine * _SpecularColor.rgb) + toonFresnel; 

                return half4(finalColor, albedo.a);
            }

            ENDHLSL
        }
    }
}
