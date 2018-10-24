#version 140

//turn shadows on/off (affects performance quite well)
#define ENABLE_SHADOWS 0
//turn a realistic drunkenness vision on/off
#define DRUNK 0

//index of refraction
//const float IOR_NUM = 1.52f;
const float IOR_NUM = 1.1f;

const float MAX_DISTANCE = 600.0f;

//Shader input, output
in vec3 rayDirFromVer;
flat in vec3 eyePos;
out vec4 outputColor;

uniform float g_time;

////////////////////////
//obejct property bit flags

//bit flags for different material types
#define MAT_DIFFUSE     1
#define MAT_SPECULAR    2
#define MAT_REFLECTIVE  4
#define MAT_REFRACT     8
#define MAT_CHECKER     16
#define MAT_CRAZY       32
#define MAT_BUMPY       64

//additional property bit flags
#define WOBBLY          128

/////////////////////////

/////////////////////////
//light property bit flags
#define LGHT_SPARKLING 1

/////////////////////////

//indentifiers for different object types
#define OBJ_SPHERE  0
#define OBJ_BOX     1

const float EPSILON = 0.006f;
const float PI = 3.14159f;

const float sqrt2 = sqrt(2.f);

///////////////////////////////////////////////
//OBJECTS
///////////////////////////////////////////////

struct Sphere
{
	vec3 pos;
	float r;
	
	int properties;
	
	vec3 diffCol;
	vec3 specCol;
	vec3 reflCol; //(1, 1, 1) means perfect mirror (note that if you want a mirror the diffCol should be (0, 0, 0))
};
struct Box
{
	vec3 min;
	vec3 max;
	
	int properties;
	
	vec3 diffCol;
	vec3 specCol;
	vec3 reflCol;
};
struct Ray
{
	vec3 orig;
	vec3 dir;
};
struct Light
{
	vec3 pos;
	vec3 color;
	
	int properties;
};

float sparkle_transform(float x) {
	float tmp = (cos(cos(x)*4+cos(x*2*sqrt2))+1)*0.5;
	return tmp*tmp;
}

float myrand(const in float seed) {
	return fract(cos(seed * 1414.213562))*2 - 1;
	//return cos(seed * 12345.67);
	//return cos(seed * PI);
	//return cos(PI);
	
	//return -0.5;
}

float randomWave(const in vec3 x, const in vec3 timeSeed) {
	const int randomness = 5;
	float seed = 0;
	float result = 0;
	
	for (int i = 0; i < randomness; i++) {
		result += (cos(x.x*myrand(seed+=1)*7+timeSeed.x*myrand(seed+=1)*2) * cos(x.y*myrand(seed+=1)*7+PI*0.25+timeSeed.y*myrand(seed+=1)*2) * cos(x.z*myrand(seed+=1)*7+PI*0.5+timeSeed.z*myrand(seed+=1)*2)) * myrand(seed+=1);
	}
	
	return pow(result, 2);
}

float sparkle(const in vec3 seed, const in float time) { //0,70710678118654752440084436210485
	
	//return sparkle_transform(seed.x+100+time*1.1) * sparkle_transform(seed.y*2.41421356+time) * sparkle_transform(seed.z*sqrt2+200-time)*5;
	
	return randomWave(seed, vec3(time*2.2, time*1.8, time*2));
}

vec3 custom_transform(const in vec3 seed) {
	return cos(seed + vec3(length(seed))) + sin(seed.zxy*1.41421356);
	//return sin(seed.zyx*1.41421356)*sin(seed.yxz*1.3416408+vec3(length(seed)));
}

Ray wobble(const in Ray ray) {
	Ray result = ray;
	result.dir = normalize(ray.dir + 0.03*custom_transform((ray.dir.yzx*(ray.dir.zxy-vec3(3))*1.2 + vec3(g_time*0.7+2))*3));
	//result.dir = normalize(ray.dir + 0.02*custom_transform((ray.dir + vec3(g_time+1))*3));
	return result;
}

///////////////////////////////////////////////
//SCENES
///////////////////////////////////////////////

//Standard Ray tracing
/*
Sphere spheres[] = Sphere[](
	Sphere(vec3(-24, 10, 0), 10, MAT_DIFFUSE | MAT_REFLECTIVE, vec3(0.5, 0.1, 0.1), vec3(0), vec3(0.5, 0.4, 0.4)),
	Sphere(vec3(0, 10, -10), 10, MAT_DIFFUSE | MAT_REFLECTIVE, vec3(0.1, 0.5, 0.1), vec3(0), vec3(0.4, 0.5, 0.4)),
	Sphere(vec3(24, 10, 0), 10, MAT_DIFFUSE | MAT_REFLECTIVE, vec3(0.1, 0.1, 0.5), vec3(0), vec3(0.4, 0.4, 0.5))
);

Box boxes[] = Box[](
	Box(vec3(-100, -2, -100), vec3(100, 0, 100), MAT_CHECKER | MAT_REFLECTIVE, vec3(0.5), vec3(0), vec3(0.5))
);

Light lights[] = Light[](
	Light(vec3(0, 50.0, 15), vec3(1.5))
);
//*/

//Glass chair
/*
Sphere spheres[] = Sphere[](
	Sphere(vec3(0, 0, 0), 300, MAT_DIFFUSE, vec3(0.4, 0.5, 0.9), vec3(0), vec3(0.9)),
	Sphere(vec3(20*cos(g_time), 10, 20*sin(g_time)), 10, MAT_CRAZY, vec3(0.3, 0.8, 0.4), vec3(0), vec3(0.9)),
	Sphere(vec3(20*cos(g_time+PI), 10, 20*sin(g_time+PI)), 10, MAT_CRAZY, vec3(0.9, 0.2, 0.2), vec3(0), vec3(0.9))
);

Box boxes[] = Box[](
	Box(vec3(-6, 0, 4), vec3(-4, 8, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
	Box(vec3(4, 0, 4), vec3(6, 8, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
	Box(vec3(4, 0, -6), vec3(6, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
	Box(vec3(-6, 0, -6), vec3(-4, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
	Box(vec3(-6, 8, -4), vec3(6, 10, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
	Box(vec3(-4, 16, -6), vec3(4, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),

	Box(vec3(-200, -2, -200), vec3(200, 0, 200), MAT_CHECKER, vec3(.9), vec3(0), vec3(0.9, 0.95, 0.95))
);

Light lights[] = Light[](
	Light(vec3(0, 100.0, 0), vec3(1.2))
);
//*/

//Box
//*
Sphere spheres[] = Sphere[](
	Sphere(vec3(-70, 20, 80), 50, MAT_DIFFUSE, vec3(0.8, 0.8, 0.1), vec3(0.95), vec3(0.8, 0.8, 1.0)),
	Sphere(vec3(30, 16, 20), 5, MAT_DIFFUSE, vec3(0.3, 0.9, 0.2), vec3(0.95), vec3(0.8, 0.8, 1.0)),
	Sphere(vec3(0, 25, -10), 20, MAT_REFRACT | MAT_SPECULAR | WOBBLY, vec3(0.0), vec3(0.95), vec3(0.2, 0.9, 0.95)),
	Sphere(vec3(47, 11, -50), 11, MAT_REFLECTIVE | MAT_SPECULAR, vec3(0.0), vec3(0.7), vec3(0.4))
);

Box boxes[] = Box[](
	Box(vec3(-25, 0, -48), vec3(-11, 14, -34), MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0), vec3(0)),
	Box(vec3(23, 9, 13), vec3(37, 23, 27), MAT_REFRACT, vec3(0), vec3(0.95), vec3(0.9, 0.95, 0.94)),
	Box(vec3(-70, 0, -90), vec3(70, 60, 100), MAT_CHECKER, vec3(0.6), vec3(0.95), vec3(0.9))
);

const vec3 blueGlow = vec3(0.1, 0.6, 0.8);

Light lights[] = Light[](
	Light(vec3(0, 25, -10), blueGlow, LGHT_SPARKLING),
	Light(vec3(0.0, 45, 10.0), vec3(0.5, 0.5, 0.5)+blueGlow*0.5, 0)
);
//*/

//Snowman
/*
Sphere spheres[] = Sphere[](
	Sphere(vec3(0, 6, 0), 6.0, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9)),
	Sphere(vec3(0, 15, 0), 4.2, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9)),
	Sphere(vec3(0, 21, 0), 2.5, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9))
);

Box boxes[] = Box[](
	Box(vec3(-200, -2, -200), vec3(200, 0, 200), MAT_DIFFUSE, vec3(.9), vec3(0), vec3(0.2)),
	Box(vec3(-8, 0, -8), vec3(8, 25, 8), MAT_REFRACT | MAT_BUMPY, vec3(0), vec3(0), vec3(0.9, 0.95, 0.95))
);

Light lights[] = Light[](
	Light(vec3(400, 200, 400), vec3(0.7, 0.85, 1))
);
//*/

///////////////////////////////////////////////
//CODE
///////////////////////////////////////////////

float closestBoxIntersection(const in Ray theRay, const in Box theBox) {
	//dists are the distances between the Ray origin and the different planes on the Ray
	//dists[0].x is one of the x plane's distance. dists[1].x is the other's.
	vec3 dists[2];
	
	vec3 oneOverDir = vec3(1) / theRay.dir;
	
	dists[0] = (theBox.min - theRay.orig) * oneOverDir;
	dists[1] = (theBox.max - theRay.orig) * oneOverDir;
	
	float tmin = max(max(min(dists[0].x, dists[1].x), min(dists[0].y, dists[1].y)), min(dists[0].z, dists[1].z));
	float tmax = min(min(max(dists[0].x, dists[1].x), max(dists[0].y, dists[1].y)), max(dists[0].z, dists[1].z));
	
	if(tmin > tmax) return -1.f;
	
	//if we are inside or facing away
	if(tmin < 0) return tmax;
	
	return tmin;
}

//returns the closest intersections distance from the Ray origin on the Ray (if Ray.dir is a normailzed vector)
//...or if no intersection, returns a negative value
float closestSphereIntersection(const in Ray theRay, const in Sphere theSphere) {
	// 0 = a*(t^2) + b*t + c where t is the distance from the Ray origin on the Ray
	
	//if the Ray is facing "away" from the Sphere
	//if(dot(theRay.dir, normalize(theSphere.pos-theRay.orig)) < 0) return -1.f;
	
	float a = dot(theRay.dir, theRay.dir);
	float b = 2.f * dot(theRay.orig - theSphere.pos, theRay.dir);
	float c = -(theSphere.r*theSphere.r) + dot(theRay.orig - theSphere.pos, theRay.orig - theSphere.pos);
	
	//discriminant
	float D = b*b - 4.0f*a*c;
	
	//if no intersection
	if(D < 0.f) {
		return -1.f;
	}
	
	float t1 = (-b+sqrt(D))/(2.0f*a);
	float t2 = (-b-sqrt(D))/(2.0f*a);
	if(t1 > 0.0f && t2 > 0.0f) {
		return min(t1, t2);
	}
	
	return max(t1, t2);
}

bool traceRay(inout Ray thisRay, out vec3 color, inout vec3 colorIntensity) {
	float IOR_curr = 1.0f/IOR_NUM;
	float closest = MAX_DISTANCE-2;
	int closestObjID = -1;
	int closestObjType;
	float current;
	for(int i = 0; i < spheres.length(); i+=1) {
		if(bool(spheres[i].properties & WOBBLY)){
			current = closestSphereIntersection(wobble(thisRay), spheres[i]);
		}
		else{
			current = closestSphereIntersection(thisRay, spheres[i]);
		}
		if(current > 0.0f && current < closest) {
			closest = current;
			closestObjID = i;
			closestObjType = OBJ_SPHERE;
		}
	}
	
	for(int i = 0; i < boxes.length(); i+=1) {
		if(bool(boxes[i].properties & WOBBLY)){
			current = closestBoxIntersection(wobble(thisRay), boxes[i]);
		}
		else{
			current = closestBoxIntersection(thisRay, boxes[i]);
		}
		if(current > 0.0f && current < closest) {
			closest = current;
			closestObjID = i;
			closestObjType = OBJ_BOX;
		}
	}
	
	//if the Ray hit any object
	if(-1 != closestObjID) {
		//find exact point
		vec3 point;

		//calculate normal and get other properties
		vec3 normal;
		int properties;
		vec3 diffCol;
		vec3 specCol;
		vec3 reflCol;
		switch(closestObjType) {
		case OBJ_SPHERE:
			point = (bool(spheres[closestObjID].properties & WOBBLY) ? wobble(thisRay).dir : thisRay.dir)*closest + thisRay.orig;
			properties = spheres[closestObjID].properties;
			diffCol = spheres[closestObjID].diffCol;
			specCol = spheres[closestObjID].specCol;
			reflCol = spheres[closestObjID].reflCol;
			normal = normalize(point - spheres[closestObjID].pos);
			break;
		case OBJ_BOX:
			point = (bool(boxes[closestObjID].properties & WOBBLY) ? wobble(thisRay).dir : thisRay.dir)*closest + thisRay.orig;
			properties = boxes[closestObjID].properties;
			diffCol = boxes[closestObjID].diffCol;
			specCol = boxes[closestObjID].specCol;
			reflCol = boxes[closestObjID].reflCol;
			normal = vec3(0, 0, 0);
			if(point.x <= boxes[closestObjID].min.x + EPSILON) normal.x = -1;
			else if(point.x >= boxes[closestObjID].max.x - EPSILON) normal.x = 1;
			else if(point.y <= boxes[closestObjID].min.y + EPSILON) normal.y = -1;
			else if(point.y >= boxes[closestObjID].max.y - EPSILON) normal.y = 1;
			else if(point.z <= boxes[closestObjID].min.z + EPSILON) normal.z = -1;
			else normal.z = 1;
			break;
		default: break;
		}
		
		//if the normal vector is facing away from eye...
		if(dot(thisRay.dir, normal) > 0.f) {
			normal *= -1.f;
			IOR_curr = IOR_NUM;
		}
		
		if(bool(properties & MAT_BUMPY)) {
			normal = normalize(normal + 0.15*custom_transform(point*0.4));
		}
		
		//ambient
		color += colorIntensity * diffCol * 0.15;
		
		//Calculate diffuse, and specular color coming from the object to this pixel.
		//Each Light affects the object indipendently...
		for(int i = 0; i < lights.length(); i+=1) {
			vec3 toLight = normalize(lights[i].pos - point);
			
			//calculate if point is in shadow for the current Light...
			bool notInShadow = true;
			#if (0 != ENABLE_SHADOWS)
			Ray rayToLight = Ray(point, toLight);
			float pointLightDist = distance(lights[i].pos, point);
			for(int j = 0; notInShadow && j < spheres.length(); j+=1) {
				//do not check shadows on self (this is ok for convex objects, but not for concave ones)
				//and refractive materials don't cast shadows
				if(!(j == closestObjID && OBJ_SPHERE == closestObjType) && (0 == (spheres[j].properties & MAT_REFRACT))) {
					float hitDist = closestSphereIntersection(rayToLight, spheres[j]);
					
					//only check positive direction (also if hitDist is very close to 0 that probably means that
					//the Ray hits the object itself so we need to choose a slightly bigger value: EPSILON &&
					//the object that we hit should be between the Light and the surface point. Otherwise its not blocking the Light
					if(EPSILON < hitDist && pointLightDist > hitDist) {
						//its in shadow
						notInShadow = false;
					}
				}
			}
			for(int j = 0; notInShadow && j < boxes.length(); j+=1) {
				if(!(j == closestObjID && OBJ_BOX == closestObjType) && (0 == (boxes[j].properties & MAT_REFRACT))) {
					float hitDist = closestBoxIntersection(rayToLight, boxes[j]);
					if(EPSILON < hitDist && pointLightDist > hitDist) {
						notInShadow = false;
					}
				}
			}
			#endif //ENABLE_SHADOWS
			//...now check
			if(notInShadow) {
				//if not in shadow, add up all the different colors that come from the different
				//material properties of this object. (for the current Light)
				if(bool(properties & (MAT_DIFFUSE | MAT_CHECKER))) {
					vec3 diffRadiance = colorIntensity * lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
					float isSparkling = int((lights[i].properties & LGHT_SPARKLING) != 0);
					color += diffRadiance*(abs(isSparkling*sparkle(toLight*6,g_time))+vec3(1-isSparkling));
				}
				if(bool(properties & MAT_SPECULAR)) {
					//                        \/  to eye  \/
					vec3 halfway = normalize((-1*thisRay.dir) + toLight);
					color += colorIntensity * lights[i].color * specCol * pow(max(0.0f, dot(halfway, normal)), 150);
				}
				if(bool(properties & MAT_CHECKER)) {
					//choose a value that has a lower chance to meet the side of a Box
					//(if a boxs side is on the edge its going to have a noisy texture caused by the floating point incorrections)
					const float checker_size = 5.3;
					const float checker_edge = checker_size*0.5;
					if(mod(point.x, checker_size) < checker_edge ^^ mod(point.z, checker_size) < checker_edge) { 
						color -= colorIntensity * lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
					}
				}
				if(bool(properties & MAT_CRAZY)) {
					color += abs(custom_transform(point*0.2)*0.9) * colorIntensity * lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
				}
			}
		}
		//finished calculating illumination that comes directly from the lights
		
		//now check if we have to trace a reflected, or a refracted Light Ray
		if(bool(properties & MAT_REFLECTIVE)) {
			//the color that comes from the reflected direction, should be modulated by this object's color
			colorIntensity *= reflCol;
			
			//the new Ray that should be traced. Note that we have to put the new Ray's origin
			//a little bit away from the surface to prevent it from hitting its origin
			thisRay = Ray(point + (EPSILON * reflect(thisRay.dir, normal)), reflect(thisRay.dir, normal));
			
			return true;
		}
		else if(bool(properties & MAT_REFRACT)) {
			//same things as above
			colorIntensity *= reflCol;
			
			Ray newRay = Ray(point + (EPSILON * refract(thisRay.dir, normal, IOR_curr)), refract(thisRay.dir, normal, IOR_curr));
			
			//if its a total internal reflection...
			if(vec3(0) == newRay.dir) {
				thisRay = Ray(point + (EPSILON * reflect(thisRay.dir, normal)), reflect(thisRay.dir, normal));
			}
			else {
				thisRay = newRay;
			}
			
			return true;
		}
		else {
			return false;
		}
	}
	
	return false;
}

///////////////////////////////////////////////
//MAIN
///////////////////////////////////////////////

void main() {
	const int maxLightBounces = 6; //affects performance!
	
	#if (0 == DRUNK)
	Ray thisRay = Ray(eyePos, normalize(rayDirFromVer));
	#else
	Ray thisRay = Ray(eyePos, normalize(rayDirFromVer + 0.1*custom_transform((rayDirFromVer + vec3(g_time*0.3))*3)));
	#endif
	vec3 color = vec3(0, 0, 0);
	vec3 colorIntensity = vec3(1, 1, 1);
	bool rayHit = true;
	for(int i = 0; rayHit && i < maxLightBounces; i+=1) {
		rayHit = traceRay(thisRay, color, colorIntensity);
	}
	
	outputColor = vec4(color, 1);
}

