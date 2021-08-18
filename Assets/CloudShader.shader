Shader "Custom/CloudShader"
{
    Properties
    {
        _Radius("Radius", Range(0.1,5)) = 0.3
        _StepSize("Step Size", Range(0.001, 0.1)) = 0.005
        _MinDistance("Min Distance", Range(0.0001, 0.01)) = 0.001
        _AbsorptionCoeff("Absorption Coefficient", Range(0.01, 1)) = 0.05 
        _NoiseOctaves("Noise Octaves", Range(2,10)) = 5
        _StartingOpaqueVisibility("Starting Opaque Visibility", Range(0.1, 1.0)) = 1.0
        _LightAttenuation("Light Attenuation", Range(1.0, 5.0)) = 2.0
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
            
            float _Radius;
            float _StepSize;
            float _MinDistance;
            float _AbsorptionCoeff;
            int _NoiseOctaves;
            float _StartingOpaqueVisibility;
            float _LightAttenuation;

            #define STEPS 128

            float fSphere(float3 p, float r) {
                return length(p) - r;
            }

            float fOpUnionRound(float a, float b, float r) {
                float2 u = max(float2(r - a,r - b), float2(0,0));
                return max(r, min (a, b)) - length(u);
            }

            float hash(float3 p) 
            {
                p  = frac( p*0.72824+.1 );
                p *= 28.0;
                return frac( p.x*p.y*p.z*(p.x+p.y+p.z) );
            }

            float noise( in float3 x )
            {
                float3 i = floor(x);
                float3 f = frac(x);
                f = f*f*(3.0-2.0*f);
                
                return lerp(lerp(lerp( hash(i+float3(0,0,0)), 
                                    hash(i+float3(1,0,0)),f.x),
                            lerp( hash(i+float3(0,1,0)), 
                                    hash(i+float3(1,1,0)),f.x),f.y),
                        lerp(lerp( hash(i+float3(0,0,1)), 
                                    hash(i+float3(1,0,1)),f.x),
                            lerp( hash(i+float3(0,1,1)), 
                                    hash(i+float3(1,1,1)),f.x),f.y),f.z);
            }

            float fbm(in float3 x, in float H )
            {    
                float G = exp2(-H);
                float f = 1.0;
                float a = 1.0;
                float t = 0.0;
                for( int i=0; i<_NoiseOctaves; i++ )
                {
                    t += a*noise(f*x);
                    f *= 2.0;
                    a *= G;
                }
                return t;
            }

            float map (float3 p)
            {
                float o1 = fSphere(p+float3(_Radius/2, _Radius/2, _Radius/2), _Radius+fbm(p+float3(_Radius/2, _Radius/2, _Radius/2), 0.1)*0.1);
                float o2 = fSphere(p-float3(_Radius/2, _Radius/2, _Radius/2), _Radius*0.8+fbm(p-float3(_Radius/2, _Radius/2, _Radius/2), 0.2)*0.1);
                
                return fOpUnionRound(o1, o2, _Radius);
            }

            float BeerLambert(float absorptionCoefficient, float distanceTraveled)
            {
                return exp(-absorptionCoefficient * distanceTraveled);
            }

            float GetLightAttenuation(float distanceToLight)
            {
                return 1.0 / pow(distanceToLight, _LightAttenuation);
            }

            fixed4 raymarchHit (float3 position, float3 direction)
            {
                float opaqueVisibility = _StartingOpaqueVisibility;
                float3 opaqueColor = float3(0,0,0);

                float3 volumetricColor = float3(0,0,0);
                float3 volumeAlbedo = float3(0.8, 0.8, 0.8);

                float3 ambientLight = 1.2 * float3(0.03, 0.018, 0.018);

                for (int i = 0; i < STEPS; i++)
                {
                    float density = map(position);
                    if (density < _MinDistance) {
                        float previousOpaqueVisibility = opaqueVisibility;
		                opaqueVisibility *= BeerLambert(_AbsorptionCoeff, _StepSize);
		                float absorptionFromMarch = previousOpaqueVisibility - opaqueVisibility;
                        float lightDistance = length(_WorldSpaceLightPos0.xyz - position);
                        float3 lightColor = _LightColor0.rgb * GetLightAttenuation(lightDistance);
                        volumetricColor += absorptionFromMarch * lightColor * volumeAlbedo;
                        volumetricColor += absorptionFromMarch * ambientLight * volumeAlbedo;
                    }
                    
                    position += direction * _StepSize;
                }
                return float4(clamp(volumetricColor, 0.0f, 1.0f) + opaqueVisibility * opaqueColor, 1.0f);
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
