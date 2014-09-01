#version 130

in vec3 rayDirFromVer;
in vec3 eyePos;
out vec4 outputColor;

uniform float time;

//bit flags for different material types
#define MAT_DIFFUSE     1
#define MAT_SPECULAR    2
#define MAT_REFLECTIVE  4
#define MAT_REFRACT     8
#define MAT_CHECKER     16
#define MAT_CRAZY       32
#define MAT_BUMPY       64

//indentifiers for different object types
#define OBJ_SPHERE  0
#define OBJ_BOX     1

//turn shadows on/off (effects performance quite well)
#define ENABLE_SHADOWS  1

#define DRUNK           0

const float EPS = 0.006f;
const float PI = 3.14159f;

//index of refraction
const float IOR_NUM = 1.52f;

const float MAX_DISTANCE = 600.0f;

vec3 custom_transform(vec3 seed)
{
    return cos(seed + vec3(length(seed)));
    //return cos(seed + vec3(length(seed), seed.z, 3*sin(seed.x)));
}

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
    
    int material;
    
    vec3 diffCol;
    vec3 specCol;
    vec3 reflCol;
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

///////////////////////////////////
//SCENES
///////////////////////////////////

//Glass chair
/*
sphere Spheres[] = sphere[](
    sphere(vec3(50*cos(time*0.5), 20, -50*sin(time*0.5)), 20, MAT_CRAZY, vec3(1), vec3(0), vec3(0.9)),
    sphere(vec3(0, 0, 0), 300, MAT_DIFFUSE, vec3(0.2, 0.3, 0.9), vec3(0), vec3(0.9)),
    sphere(vec3(20*cos(time), 10, 20*sin(time)), 10, MAT_CHECKER, vec3(0.3, 0.8, 0.4), vec3(0), vec3(0.9)),
    sphere(vec3(20*cos(time+PI), 10, 20*sin(time+PI)), 10, MAT_CHECKER, vec3(0.9, 0.2, 0.2), vec3(0), vec3(0.9))
);

box Boxes[] = box[](
    box(vec3(-6, 0, 4), vec3(-4, 8, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
    box(vec3(4, 0, 4), vec3(6, 8, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
    box(vec3(4, 0, -6), vec3(6, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
    box(vec3(-6, 0, -6), vec3(-4, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
    box(vec3(-6, 8, -4), vec3(6, 10, 6), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),
    box(vec3(-4, 16, -6), vec3(4, 20, -4), MAT_REFRACT, vec3(0), vec3(0.9), vec3(0.9, 0.95, 0.95)),

    box(vec3(-200, -2, -200), vec3(200, 0, 200), MAT_CRAZY, vec3(.9), vec3(0), vec3(0.9, 0.95, 0.95))
);

light Lights[1] = light[1](
    light(vec3(0, 100.0, 0), vec3(1.2))
);
*/

//Mirror room
/*
sphere Spheres[] = sphere[](
    sphere(vec3(2, 2.5, 1), 2.5, MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 1.0)),
    sphere(vec3(-5, 3, -4), 3, MAT_DIFFUSE, vec3(0.8, 0.8, 0.1), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 0.8)),
    sphere(vec3(8, 4, -10), 4, MAT_DIFFUSE, vec3(0.8, 0.1, 0.3), vec3(0.95, 0.95, 0.95), vec3(0.8, 0.8, 0.8))
);

box Boxes[] = box[](
    //box(vec3(-8, 0, -7), vec3(-2, 6, -1), MAT_DIFFUSE, vec3(0.8, 0.8, 0.1), vec3(0.95), vec3(0.9, 0.95, 0.94)),
    //box(vec3(4, 0, -14), vec3(12, 8, -6), MAT_DIFFUSE, vec3(0.8, 0.1, 0.3), vec3(0.95), vec3(0.9, 0.95, 0.94)),
    box(vec3(-35, 0, -70), vec3(35, 50, 70), MAT_REFLECTIVE, vec3(0.1), vec3(0), vec3(0.8))
);

light Lights[1] = light[1](
    light(vec3(9.0, 18.0, -8.0), vec3(1.2, 1.2, 1.2))
);
*/

//Box
/*
sphere Spheres[] = sphere[](
    sphere(vec3(-20, 8, 10), 8, MAT_DIFFUSE, vec3(0.8, 0.8, 0.1), vec3(0.95), vec3(0.8, 0.8, 1.0)),
    sphere(vec3(10, 16, 5), 5, MAT_DIFFUSE, vec3(0.3, 0.9, 0.2), vec3(0.95), vec3(0.8, 0.8, 1.0)),
    sphere(vec3(-12, 16, -10), 10, MAT_REFRACT, vec3(0.0), vec3(0.95), vec3(0.9, 0.95, 0.94)),
    sphere(vec3(15, 11, -32), 11, MAT_REFLECTIVE, vec3(0.0), vec3(0.95), vec3(0.9))
);

box Boxes[] = box[](
    box(vec3(-25, 0, -48), vec3(-11, 14, -34), MAT_DIFFUSE, vec3(0.1, 0.2, 0.9), vec3(0), vec3(0)),
    box(vec3(3, 9, -2), vec3(17, 23, 12), MAT_REFRACT, vec3(0), vec3(0.95), vec3(0.9, 0.95, 0.94)),
    box(vec3(-35, 0, -70), vec3(35, 50, 70), MAT_CHECKER, vec3(0.6), vec3(0.95), vec3(0.9))
);

light Lights[1] = light[1](
    light(vec3(0.0, 45, 10.0), vec3(1.2, 1.2, 1.2))
);
*/

//Snowman

sphere Spheres[] = sphere[](
    sphere(vec3(0, 6, 0), 6.0, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9)),
    sphere(vec3(0, 15, 0), 4.2, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9)),
    sphere(vec3(0, 21, 0), 2.5, MAT_DIFFUSE, vec3(1), vec3(0), vec3(0.9))
);

box Boxes[] = box[](
    box(vec3(-200, -2, -200), vec3(200, 0, 200), MAT_DIFFUSE, vec3(.9), vec3(0), vec3(0.2)),
    box(vec3(-8, 0, -8), vec3(8, 25, 8), MAT_REFRACT | MAT_BUMPY, vec3(0), vec3(0), vec3(0.9, 0.95, 0.95))
);

light Lights[] = light[](
    light(vec3(40, 40, 40), vec3(0.7, 0.85, 1))
);


///////////////////////////////////
//CODE
///////////////////////////////////

float closestBoxIntersection(ray theRay, box theBox)
{
    //dists are the distances between the ray origin and the different planes on the ray
    //dists[0].x is one of the x plane's distance. dists[1].x is the other's.
    vec3 dists[2];
    
    bool inside = true;
    for(int i = 0; i < 3; i+=1)
    {
        if(theRay.orig[i] < theBox.min[i] || theRay.orig[i] > theBox.max[i])
        {
            inside = false;
        }
    }
    
    for(int i = 0; i < 3; i+=1)
    {
        //if direction is not paralell to the planes
        if(0 != theRay.dir[i])
        {
            dists[0][i] = (theBox.min[i] - theRay.orig[i]) / theRay.dir[i];
            dists[1][i] = (theBox.max[i] - theRay.orig[i]) / theRay.dir[i];
        }
        else
        {
            if(inside)
            {
                dists[0][i] = MAX_DISTANCE;
                dists[1][i] = -MAX_DISTANCE;
            }
            else
            {
                dists[0][i] = MAX_DISTANCE;
                dists[1][i] = MAX_DISTANCE;
            }
        }
    }
    
    //
    float tmin = max(max(min(dists[0].x, dists[1].x), min(dists[0].y, dists[1].y)), min(dists[0].z, dists[1].z));
    float tmax = min(min(max(dists[0].x, dists[1].x), max(dists[0].y, dists[1].y)), max(dists[0].z, dists[1].z));
    
    if(tmin > tmax) return -1;
    
    //if we are inside or facing away
    if(tmin < 0) return tmax;
    
    return tmin;
}

//returns the closest intersections distance from the ray origin on the ray (if ray.dir is a normailzed vector)
//...or if no intersection, returns a negative value
float closestSphereIntersection(ray theRay, sphere theSphere)
{
    // 0 = a*(t^2) + b*t + c where t is the distance from the ray origin on the ray
    
    float a = dot(theRay.dir, theRay.dir);
    float b = 2.f * dot(theRay.orig - theSphere.pos, theRay.dir);
    float c = -(theSphere.r*theSphere.r) + dot(theRay.orig - theSphere.pos, theRay.orig - theSphere.pos);
    
    //discriminant
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
    float closest = MAX_DISTANCE-2;
    int closestObjID = -1;
    int closestObjType;
    float current;
    for(int i = 0; i < Spheres.length(); i+=1)
    {
        current = closestSphereIntersection(thisRay, Spheres[i]);
        if(current > 0.0f && current < closest)
        {
            closest = current;
            closestObjID = i;
            closestObjType = OBJ_SPHERE;
        }
    }
    
    for(int i = 0; i < Boxes.length(); i+=1)
    {
        current = closestBoxIntersection(thisRay, Boxes[i]);
        if(current > 0.0f && current < closest)
        {
            closest = current;
            closestObjID = i;
            closestObjType = OBJ_BOX;
        }
    }
    
    if(-1 != closestObjID)
    {
        //find exact point
        vec3 point = (thisRay.dir * closest) + thisRay.orig;
        //calculate normal and get other properties
        vec3 normal;
        int material;
        vec3 diffCol;
        vec3 specCol;
        vec3 reflCol;
        switch(closestObjType)
        {
        case OBJ_SPHERE:
            material = Spheres[closestObjID].material;
            diffCol = Spheres[closestObjID].diffCol;
            specCol = Spheres[closestObjID].specCol;
            reflCol = Spheres[closestObjID].reflCol;
            normal = normalize(point - Spheres[closestObjID].pos);
            break;
        case OBJ_BOX:
            material = Boxes[closestObjID].material;
            diffCol = Boxes[closestObjID].diffCol;
            specCol = Boxes[closestObjID].specCol;
            reflCol = Boxes[closestObjID].reflCol;
            normal = vec3(0, 0, 0);
            if(point.x <= Boxes[closestObjID].min.x + EPS) normal.x = -1;
            else if(point.x >= Boxes[closestObjID].max.x - EPS) normal.x = 1;
            else if(point.y <= Boxes[closestObjID].min.y + EPS) normal.y = -1;
            else if(point.y >= Boxes[closestObjID].max.y - EPS) normal.y = 1;
            else if(point.z <= Boxes[closestObjID].min.z + EPS) normal.z = -1;
            else normal.z = 1;
            break;
        default: break;
        }
        
        //if the normal vector is facing away from eye...
        if(dot(thisRay.dir, normal) > 0.f)
        {
            normal *= -1.f;
            IOR_curr = IOR_NUM;
        }
        
        if(material & MAT_BUMPY)
        {
            normal = normalize(normal + 0.1*custom_transform(point));
        }
        
        //ambient
        color += colorIntensity * diffCol * 0.15;
        
        vec3 toLight;
        for(int i = 0; i < Lights.length(); i+=1)
        {
            toLight = normalize(Lights[i].pos - point);
            
            //shadows...
            bool notInShadow = true;
            #if (0 != ENABLE_SHADOWS)
            ray rayToLight = ray(point, toLight);
            float pointLightDist = length(Lights[i].pos - point);
            float hitDist;
            for(int j = 0; notInShadow && j < Spheres.length(); j+=1)
            {
                //do not check shadows on self (this is ok for convex objects, but not for concave ones)
                //and refractive materials don't cast shadows
                if(!(j == closestObjID && OBJ_SPHERE == closestObjType) && (0 == (Spheres[j].material & MAT_REFRACT)))
                {
                    hitDist = closestSphereIntersection(rayToLight, Spheres[j]);
                    //only check positive direction (also if hitDist is very close to 0 that probably means that
                    //the ray hits the object itself so we need to choose a slightly bigger value: EPSILON (EPS)) &&
                    //the object that we hit should be between the light and the surface point. Otherwise its not blocking the light
                    if(EPS < hitDist && pointLightDist > hitDist)
                    {
                        //its in shadow
                        notInShadow = false;
                    }
                }
            }
            for(int j = 0; notInShadow && j < Boxes.length(); j+=1)
            {
                if(!(j == closestObjID && OBJ_BOX == closestObjType) && (0 == (Boxes[j].material & MAT_REFRACT)))
                {
                    hitDist = closestBoxIntersection(rayToLight, Boxes[j]);
                    if(EPS < hitDist && pointLightDist > hitDist)
                    {
                        notInShadow = false;
                    }
                }
            }
            #endif //ENABLE_SHADOWS
            //...now check
            if(notInShadow)
            {
                //                        \/  to eye  \/
                vec3 halfway = normalize((-1*thisRay.dir) + toLight);
                
                if(material & MAT_DIFFUSE)
                {
                    color += colorIntensity * Lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
                }
                if(material & MAT_SPECULAR)
                {
                    color += colorIntensity * Lights[i].color * specCol * pow(max(0.0f, dot(halfway, normal)), 150);
                }
                if(material & MAT_CHECKER)
                {
                    //choose a value that has a lower chance to meet the side of a box
                    //(if a boxs side is on the edge its going to have a noisy texture caused by the floating point incorrections)
                    const float checker_size = 5.3;
                    const float checker_edge = checker_size*0.5;
                    if(mod(point.x, checker_size) < checker_edge ^^ mod(point.z, checker_size) < checker_edge)
                    { 
                        color += colorIntensity * Lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
                    }
                }
                if(material & MAT_CRAZY)
                {
                    color += abs(custom_transform(point*0.2)*0.9) * colorIntensity * Lights[i].color * diffCol * max(0.0f, dot(toLight, normal));
                }
            }
        }
        
        if(material & MAT_REFLECTIVE)
        {
            colorIntensity *= reflCol;
            
            //                     | to guarantee that this ray wont hit its origin
            thisRay = ray(point + (EPS * reflect(thisRay.dir, normal)), reflect(thisRay.dir, normal));
            
            return true;
        }
        else if(material & MAT_REFRACT)
        {
            colorIntensity *= reflCol;
            
            //                        | to guarantee that this ray wont hit its origin
            ray newRay = ray(point + (EPS * refract(thisRay.dir, normal, IOR_curr)), refract(thisRay.dir, normal, IOR_curr));
            
            if(vec3(0) == newRay.dir)
            {
                thisRay = ray(point + (EPS * reflect(thisRay.dir, normal)), reflect(thisRay.dir, normal));
            }
            else
            {
                thisRay = newRay;
            }
            
            return true;
        }
    }
    
    return false;
}

void main()
{
    const int maxReflectionCount = 6; //effects performance!
    
    #if (0 == DRUNK)
    ray thisRay = ray(eyePos, normalize(rayDirFromVer));
    #else
    ray thisRay = ray(eyePos, normalize(rayDirFromVer + 0.1*custom_transform((rayDirFromVer + vec3(time*0.3))*3)));
    #endif
    vec3 color = vec3(0, 0, 0);
    vec3 colorIntensity = vec3(1, 1, 1);
    bool rayHit = true;
    for(int i = 0; rayHit && i < maxReflectionCount; i+=1)
    {
        rayHit = traceRay(thisRay, color, colorIntensity);
    }
    
    outputColor = vec4(color, 1);
}

