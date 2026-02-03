// input: float3 lens (center), float Rs (Schwarzchild radius), float Rdisk, float ThcDisk, float TMaxDisk
//        float3 raystart, float3 raydir
// output: float3 raydir, float3 color, float alpha

// MaterialExpressionBlackBody(temperature)
// MaterialExpressionNoise(pos, scale, qual, type=2, turbulence, levels, min, max, levscale, 0, 0, repeat)

alpha = 0.0;
color = float3(0.0, 0.0, 0.0);

if(in_Rs <= 0.0)
{
	return raydir;
}

int i=0;
float3 rp = (raystart - lens.xyz) / in_Rs;
float3 rd = raydir;

const bool diskEnabled = Rdisk > 0.0;
const float diskThickness = 0.5 * ThcDisk * 100000.0 / in_Rs;
const float diskRadius = in_Rs * Rdisk / in_Rs;

const float Rs = 1.0;

// raymarch
while(i++ < 100)
{
	float3 v = -rp;
	const float r = length(v);

	if(r < Rs)  // hit event horizon
	{
		color *= alpha;
		alpha = 1.0;
		break;
	}

	float stepSz = 0.25 * r;

	if(diskEnabled)
	{
		if(r*0.75 < diskRadius)  // reduce step size near accretion disk
		{
			float hit1 = (diskThickness + v.z) / rd.z;
			float hit2 = (-diskThickness + v.z) / rd.z;
			if(hit1 > 0.0 && hit2 > 0.0) {
				stepSz = min(stepSz, min(hit1, hit2));
			} else if(hit1 > 0.0 || hit2 > 0.0) {
				stepSz = min(stepSz, abs(hit1-hit2) / 30.0);
			}
		}

		float rPerDR = r / diskRadius;
		float zPerTH = abs(v.z) / diskThickness;

		if(rPerDR < 1.0 && zPerTH < 1.0)  // inside accretion disk
		{
			float T = TMaxDisk / (r / Rs);
			float rns = r / Rs;
			T += MaterialExpressionNoise(float3(rns,rns,rns), 1.0, 1, 2, 0, 3, -500, 500, 2, 0,0,512);
			float alphaAdd = lerp(0.01, 0.0, max(rPerDR, zPerTH)) * (stepSz / (0.3*diskThickness));
			color += MaterialExpressionBlackBody(max(0.0, T));
			alpha += alphaAdd;
			if(alpha > 1.0) break;
		}
	}

	v /= r;  // normalize v
	float phi = (Rs / r) * (stepSz / r);
	phi *= 1.0 - abs(dot(rd, v));

	float3 g = normalize(cross(rd, cross(v, rd)));
	rd = normalize(cos(phi) * rd + sin(phi) * g);
	
	rp += rd * stepSz;
}

alpha = clamp(alpha, 0.0, 1.0);
return rd;
