Shader "Custom/SphereSDFShader"
{
    Properties
    {
        _Centre("Sphere Center", Vector) = (0,0,0,0)
        _Radius("Sphere Radius", Range(0.1, 1)) = 0.5
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

            #define STEPS 64
            #define STEP_SIZE 0.01
            #define MIN_DISTANCE 0.001

            float sphereDistance (float3 p)
            {
                return distance(p,_Centre) - _Radius;
            }

            bool raymarchHit (float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    float d = sphereDistance(position);
                    if (  d < MIN_DISTANCE )
                        return true;
                    position += direction * d;
                }
                return false;
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

                if (raymarchHit(worldPosition, viewDirection)) {
                    return fixed4(1,0,0,1);
                } else {
                    return fixed4(1,1,1,1);
                }
            }
            ENDCG
        }
    }
}
