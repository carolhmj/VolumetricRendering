Shader "Custom/SDFSceneShader"
{
    Properties
    {
        _Color("Color", Color) = (0,1,0,1)
        _OuterRadius("Outer Radius", Range(0.1, 2)) = 0.8
        _InnerRadius("Inner Radius", Range(0.1, 2)) = 0.4 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD1;
            };
            
            float4 _Color;
            float _OuterRadius;
            float _InnerRadius;

            #define STEPS 128
            #define STEP_SIZE 0.1
            #define MIN_DISTANCE 0.01

            // Torus in the XZ-plane
            float fTorus(float3 p, float smallRadius, float largeRadius) {
                return length(float2(length(p.xz) - largeRadius, p.y)) - smallRadius;
            }

            void pR(inout float2 p, float a) {
                p = cos(a)*p + sin(a)*float2(p.y, -p.x);
            }

            float fOpUnionRound(float a, float b, float r) {
                float2 u = max(float2(r - a,r - b), float2(0,0));
                return max(r, min (a, b)) - length(u);
            }

            float map (float3 p)
            {
                float o1 = fTorus(p, _InnerRadius, _OuterRadius);
                pR(p.xy, 1.57);
                float o2 = fTorus(p, _InnerRadius, _OuterRadius);
                
                return fOpUnionRound(o1, o2, 0.1);
            }

            fixed4 simpleLambert (fixed3 normal) {
                fixed3 lightDir = _WorldSpaceLightPos0.xyz;    // Light direction
                fixed3 lightCol = _LightColor0.rgb;        // Light color
                fixed NdotL = max(dot(normal, lightDir),0);
                fixed4 c;
                c.rgb = _Color * lightCol * NdotL;
                c.a = 1;
                return c;
            }

            float3 normal (float3 p)
            {
                const float eps = 0.01;
                return normalize(    
                    float3(    
                        map(p + float3(eps, 0, 0)    ) - map(p - float3(eps, 0, 0)),
                        map(p + float3(0, eps, 0)    ) - map(p - float3(0, eps, 0)),
                        map(p + float3(0, 0, eps)    ) - map(p - float3(0, 0, eps))
                    )
                );
            }

            fixed4 renderSurface(float3 p) 
            {
                float3 n = normal(p);
                return simpleLambert(n);
            }

            fixed4 raymarchHit (float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    float d = map(position);
                    if ( d < MIN_DISTANCE )
                        return renderSurface(position);
                    position += direction * d;
                }
                return fixed4(1,1,1,1);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPosition = i.wPos;
                float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);

                return raymarchHit(worldPosition, viewDirection);
            }
            ENDCG
        }
    }
}
