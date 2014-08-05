#version 130
in vec3 WorldPosFromVer;
in vec3 eyePos;
out vec4 outputColor;

uniform float time;

//identifiers for different material types
#define MAT_DIFFUSE	0
#define MAT_SPECULAR	1
#define MAT_REFLECTIVE	2
#define MAT_REFRACT	3

//turn shadows on/off
#define ENABLE_SHADOWS	1

//index of refraction
//const float IOR_NUM = 1.51f;
const float IOR_NUM = 1.1f;

struct sphere
{
	vec3 pos;
	float r;
	
	int material;
	
	vec3 diffCol;
	vec3 specCol;
	vec3 reflCol; //(1, 1, 1) means perfect mirror (note that if you want a mirror the diffCol should be (0, 0, 0))
};
struct box
{
	vec3 min;
	vec3 max;
};
struct ray
{
	vec3 orig;
	vec3 dir;
};
struct light
{
	vec3 pos;
	vec3 color;
};

const float MAX_DISTANCE = 500.0f;

///////////////////////////////////
//SCENES
///////////////////////////////////

//scene 1
/*
const sphere Spheres[] = sphere[](
	sphere(vec3(7.0, 5.0, -13.0), 5.0, MAT_REFLECTIVE, vec3(0.2, 0.1, 0.1), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.4, 0.4)),
	sphere(vec3(-7.0, 5.0, -13.0), 5.0, MAT_REFLECTIVE, vec3(0.1, 0.2, 0.1), vec3(0.95, 0.95, 0.95), vec3(0.4, 0.8, 0.4)),
	sphere(vec3(0.0, 5.0, -29.0), 5.0, MAT_REFLECTIVE, vec3(0.1, 0.1, 0.2), vec3(0.95, 0.95, 0.95), vec3(0.4, 0.4, 0.8)),
	sphere(vec3(0.0, 2.0, -20.0), 2.0, MAT_SPECULAR, vec3(0.1, 0.1, 0.6), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
	sphere(vec3(0.0, -3000.0, -10.0), 3000.0, MAT_DIFFUSE, vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0), vec3(0))
);
light Lights[1] = light[1](
	light(vec3(cos(time/1.7f)*16.0, 18.0, sin(time/1.3f)*18.0), vec3(1.5, 1.5, 1.5))
);
*/

/*
//mirror room
const sphere Spheres[] = sphere[](
	sphere(vec3(0, -3000, 0), 3000, MAT_DIFFUSE, vec3(0.6, 0.1, 0.1), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.5, 0.5)),
	sphere(vec3(3030, 30, 0), 3000, MAT_REFLECTIVE, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 3035, 0), 3000, MAT_REFLECTIVE, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(-3030, 30, 0), 3000, MAT_REFLECTIVE, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 30, -3070), 3000, MAT_DIFFUSE, vec3(0.7, 0.7, 0.7), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 30, 3070), 3000, MAT_DIFFUSE, vec3(0.2, 0.7, 0.2), vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0)),
	sphere(vec3(2, 2.5, 1), 2.5, MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
	sphere(vec3(-2, 3, -3), 3, MAT_REFRACT, vec3(0.0, 0.0, 0.0), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 0.8))
);

light Lights[1] = light[1](
	light(vec3((time/time)*9.0, 18.0, -8.0), vec3(1.5, 1.5, 1.5))
);
*/

//Cornell box
sphere Spheres[] = sphere[](
	sphere(vec3(0, -3000, 0), 3000, MAT_DIFFUSE, vec3(0.6, 0.6, 0.6), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.5, 0.5)),
	sphere(vec3(3030, 30, 0), 3000, MAT_DIFFUSE, vec3(0.7, 0.0, 0.7), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 3050, 0), 3000, MAT_DIFFUSE, vec3(0.6, 0.6, 0.6), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(-3030, 30, 0), 3000, MAT_DIFFUSE, vec3(0.05, 0.7, 0.3), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 30, -3070), 3000, MAT_DIFFUSE, vec3(0.6, 0.6, 0.6), vec3(0.0, 0.0, 0.0), vec3(0.8, 0.8, 0.8)),
	sphere(vec3(0, 30, 3070), 3000, MAT_DIFFUSE, vec3(0.6, 0.6, 0.6), vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0)),
	sphere(vec3(12, 8, -13), 8, MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
	sphere(vec3(-5, 8, -22), 8, MAT_DIFFUSE, vec3(0.8, 0.8, 0.1), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
	sphere(vec3(12, 8, -13), 8, MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
	sphere(vec3(6, 16, 12), 12, MAT_REFRACT, vec3(0.0, 0.0, 0.0), vec3(0.95, 0.95, 0.95), vec3(0.9, 0.95, 0.94)),
	sphere(vec3(-14, 9, -4), 9, MAT_REFLECTIVE, vec3(0.0, 0.0, 0.0), vec3(0.95, 0.95, 0.95), vec3(0.9, 0.9, 0.9))
);

light Lights[1] = light[1](
	light(vec3((time/time)*0.0, 45, 10.0), vec3(1.2, 1.2, 1.2))
);

float closestBoxIntersection(ray theRay, box theBox)
{
	vec3 maxT;
	vec3 candidatePlanes;
	
	for(int i = 0; i < 3; ++i)
	{
		if(theRay.orig[i] < theBox.min[i])
		{
			
		}
	}
	
	return -1;
}

//returns the closest intersections distance from the ray origin on the ray (if ray.dir is a normailzed vector)
//...or if no intersection, returns a negativ value
float closestIntersection(ray theRay, sphere theSphere)
{
	//if(length((theRay.orig - theSphere.pos) - dot(theRay.orig - theSphere.pos, theRay.dir)*theRay.dir ) > theSphere.r) return -1;

	// 0 = a*(t^2) + b*t + c where t is the distance from the origin on the ray (P = t*ray.dir + ray.orig)
	
	float a = dot(theRay.dir, theRay.dir);
	float b = 2.f * dot(theRay.orig - theSphere.pos, theRay.dir);
	float c = -(theSphere.r*theSphere.r) + dot(theRay.orig - theSphere.pos, theRay.orig - theSphere.pos);
	
	float D = b*b - 4.0f*a*c;
	
	//if no intersection
	if(D < 0.f)
	{
		return -1.f;
	}
	
	float t1 = (-b+sqrt(D))/(2.0f*a);
	float t2 = (-b-sqrt(D))/(2.0f*a);
	if(t1 > 0.0f && t2 > 0.0f)
	{
		return min(t1, t2);
	}
	
	return max(t1, t2);
}

bool traceRay(inout ray thisRay, out vec3 color, inout vec3 colorIntensity)
{
	float IOR_curr = 1.0f/IOR_NUM;
	float closest = MAX_DISTANCE;
	int closestObjID = -1;
	float current;
	for(int i = 0; i < Spheres.length(); ++i)
	{
		current = closestIntersection(thisRay, Spheres[i]);
		if(current > 0.0f && current < closest)
		{
			closest = current;
			closestObjID = i;
		}
	}
	
	if(-1 != closestObjID)
	{
		//ambient
		color += colorIntensity * Spheres[closestObjID].diffCol * 0.2;
		
		//find exact point
		vec3 point = (thisRay.dir * closest) + thisRay.orig;
		vec3 normal = normalize(point - Spheres[closestObjID].pos);
		
		vec3 toLight;
		for(int i = 0; i < Lights.length(); ++i)
		{
			toLight = normalize(Lights[i].pos - point);
			
			//shadows...
			bool notInShadow = true;
			#if (0 != ENABLE_SHADOWS)
			ray rayToLight = ray(point, toLight);
			float pointLightDist = length(Lights[i].pos - point);
			float hitDist;
			for(int j = 0; j < Spheres.length(); ++j)
			{
				//dont check shadows on self (this is ok for convex objects, but not for concave ones)
				if(j == closestObjID) continue;
				
				hitDist = closestIntersection(rayToLight, Spheres[j]);
				//only check positive direction (also if hitDist is very close to 0 that probably means that
				//the ray hits the object itself so we need to choose a slightly bigger value. Here its 0.01) &&
				//the object that we hit should be between the light and the surface point. Otherwise its not blocking the light
				if(0.008f < hitDist && pointLightDist > hitDist)
				{
					//its in shadow
					notInShadow = false;
					//ugly but (maybe) gives better performace
					break;
				}
			}
			#endif //ENABLE_SHADOWS
			//...now check...
			if(notInShadow)
			{
				//             \/ \/   to eye   \/ \/
				vec3 halfway = (-1*thisRay.dir) + toLight;
				halfway = normalize(halfway);
				
				
				switch(Spheres[closestObjID].material)
				{
				case MAT_REFRACT:
					if(dot(-1*thisRay.dir, normal) < 0.f)
					{
						normal *= -1.f;
						IOR_curr = IOR_NUM;
					}
					//continue;
				case MAT_REFLECTIVE:
					//continue;
				case MAT_SPECULAR:
					color += colorIntensity * Lights[i].color * Spheres[closestObjID].specCol * pow(max(0.0f, dot(halfway, normal)), 100);
					//continue;
				case MAT_DIFFUSE:
					color += colorIntensity * Lights[i].color * Spheres[closestObjID].diffCol * max(0.0f, dot(toLight, normal));
					//continue;
				default: break;
				}
				
				/*
				if(Spheres[closestObjID].material == MAT_REFRACT && dot(-1*thisRay.dir, normal) < 0.f)
				{
					normal *= -1.f;
				}
				
				color += colorIntensity * Lights[i].color * ( Spheres[closestObjID].specCol * pow(max(0.0f, dot(halfway, normal)), 100) +
				Spheres[closestObjID].diffCol * max(0.0f, dot(toLight, normal)) );*/
				
			}
		}
		
		if(Spheres[closestObjID].material == MAT_REFLECTIVE)
		{
			colorIntensity *= Spheres[closestObjID].reflCol;
			
			//				| to guarantee that this ray wont hit its origin
			thisRay = ray(point + (0.008f * reflect(thisRay.dir, normal)), reflect(thisRay.dir, normal));
			
			return true;
		}
		else if(Spheres[closestObjID].material == MAT_REFRACT)
		{
			colorIntensity *= Spheres[closestObjID].reflCol;
			
			//				| to guarantee that this ray wont hit its origin
			thisRay = ray(point + (0.008f * refract(thisRay.dir, normal, IOR_curr)), refract(thisRay.dir, normal, IOR_curr));
			
			return true;
		}
	}
	
	return false;
}

void main()
{	
	const int maxReflectionCount = 10;
	
	ray thisRay = ray(eyePos, normalize(WorldPosFromVer-eyePos));
	vec3 color = vec3(0, 0, 0);
	vec3 colorIntensity = vec3(1, 1, 1);
	bool rayHit = true;
	for(int i = 0; rayHit && i < maxReflectionCount; ++i)
	{
		rayHit = traceRay(thisRay, color, colorIntensity);
	}
	
	outputColor = vec4(color, 1);
}
