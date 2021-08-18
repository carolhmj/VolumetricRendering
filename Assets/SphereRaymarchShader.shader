// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/SphereRaymarchShader"
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

            bool sphereHit (float3 p)
            {
                return distance(p,_Centre.xyz) < _Radius;
            }

            bool raymarchHit (float3 position, float3 direction)
            {
                for (int i = 0; i < STEPS; i++)
                {
                    if ( sphereHit(position) )
                        return true;
                    position += direction * STEP_SIZE;
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
