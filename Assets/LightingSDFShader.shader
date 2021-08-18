Shader "Custom/LightingSDFShader"
{
    Properties
    {
        _Centre("Sphere Center", Vector) = (0,0,0,0)
        _Radius("Sphere Radius", Range(0.1, 1)) = 0.5
        _Color("Color", Color) = (0,1,0,1)
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Centre;
            float _Radius;
            float4 _Color;

            #define STEPS 64
            #define STEP_SIZE 0.01
            #define MIN_DISTANCE 0.001

            float map (float3 p)
            {
                return distance(p,_Centre) - _Radius;
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
