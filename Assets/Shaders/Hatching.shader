Shader "Custom/Hatching"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}

        _Hatch0("Hatch 0 (Lightest)", 2D) = "white" {}
        _Hatch1("Hatch 1", 2D) = "white" {}
        _Hatch2("Hatch 2", 2D) = "white" {}
        _Hatch3("Hatch 3", 2D) = "white" {}
        _Hatch4("Hatch 4", 2D) = "white" {}
        _Hatch5("Hatch 5 (Darkest)", 2D) = "black" {}
        
        _HatchScale("Hatch Scale", Float) = 1.0
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
                float3 positionWS  : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_Hatch0);
            SAMPLER(sampler_Hatch0);
            TEXTURE2D(_Hatch1);
            SAMPLER(sampler_Hatch1);
            TEXTURE2D(_Hatch2);
            SAMPLER(sampler_Hatch2);
            TEXTURE2D(_Hatch3);
            SAMPLER(sampler_Hatch3);
            TEXTURE2D(_Hatch4);
            SAMPLER(sampler_Hatch4);
            TEXTURE2D(_Hatch5);
            SAMPLER(sampler_Hatch5);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _BaseMap_ST;
                float _HatchScale;
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

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();
                float3 normal = normalize(IN.normalWS); 
                float3 lightDir = normalize(mainLight.direction); 

                float3 diffuse = saturate(dot(normal, lightDir));
                float2 hatchUV = IN.positionHCS.xy * _HatchScale * 0.01;
                float intensity = 1.0 - diffuse;
                float hatchFactor = intensity * 6.0;
                
                half3 hatch0 = SAMPLE_TEXTURE2D(_Hatch0, sampler_Hatch0, hatchUV).rgb;
                half3 hatch1 = SAMPLE_TEXTURE2D(_Hatch1, sampler_Hatch1, hatchUV).rgb;
                half3 hatch2 = SAMPLE_TEXTURE2D(_Hatch2, sampler_Hatch2, hatchUV).rgb;
                half3 hatch3 = SAMPLE_TEXTURE2D(_Hatch3, sampler_Hatch3, hatchUV).rgb;
                half3 hatch4 = SAMPLE_TEXTURE2D(_Hatch4, sampler_Hatch4, hatchUV).rgb;
                half3 hatch5 = SAMPLE_TEXTURE2D(_Hatch5, sampler_Hatch5, hatchUV).rgb;

                half3 hatchColor = hatch0;
                hatchColor = lerp(hatchColor, hatch1, smoothstep(0.0, 1.0, hatchFactor));
                hatchColor = lerp(hatchColor, hatch2, smoothstep(1.0, 2.0, hatchFactor));
                hatchColor = lerp(hatchColor, hatch3, smoothstep(2.0, 3.0, hatchFactor));
                hatchColor = lerp(hatchColor, hatch4, smoothstep(3.0, 4.0, hatchFactor));
                hatchColor = lerp(hatchColor, hatch5, smoothstep(4.0, 5.0, hatchFactor));
                
                half3 finalColor = hatchColor * _BaseColor.rgb;
                
                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
