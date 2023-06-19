#version 410 core

// define the maximum depth for ray recursion
const int maxDepth = 5;

// define the epsilon value for shadow ray origin offset
const float epsilon = 0.001;

// define the number of samples for indirect lighting
const int numSamples = 16;

// define the maximum distance for ray intersection
const float MAX_DISTANCE = 100.0;

// define the maximum depth for ray recursion
const int MAX_DEPTH = 5;

// define screen resolution
uniform vec2 resolution = vec2(1920 * 0.6, 1080 * 0.6);

// structure for holding intersection information
struct IntersectResult {
    bool hit;
    vec3 position;
    vec3 normal;
};

// light struct
struct Light {
    vec3 position;  // Light position
    vec3 color;     // Light color
    float intensity;    // Light intensity
};

// material struct
struct Material {
    vec3 color;         // surface color
    vec3 specularColor; // specular color
    float roughness;    // surface roughness
    float reflection;   // reflection coefficient
    float refraction;   // refraction coefficient
    float ior;          // index of refraction
};

// sphere struct
struct Sphere {
    vec3 center;        // sphere center position
    float radius;       // sphere radius
    Material material;  // sphere material
};

// scene data
const int numSpheres = 3;
const int numLights = 3;
Sphere spheres[numSpheres];
Light lights[numLights];

// camera settings
vec3 cameraPosition = vec3(0.0, 0.0, -5.0);
vec3 cameraTarget = vec3(0.0, 0.0, 0.0);
vec3 cameraUp = vec3(0.0, 1.0, 0.0);
vec3 cameraRight = vec3(1.0, 0.0, 0.0);

// scene setup function
void setupScene() {
    // define sphere 1: Red
    spheres[0].center = vec3(-2.0, 0.0, 0.0);
    spheres[0].radius = 1.0;
    spheres[0].material.color = vec3(1.0, 0.0, 0.0);
    spheres[0].material.specularColor = vec3(1.0, 1.0, 1.0);
    spheres[0].material.roughness = 32.0;
    spheres[0].material.reflection = 0.5;
    spheres[0].material.refraction = 0.0;
    spheres[0].material.ior = 1.0;

    // define sphere 2: Blue
    spheres[1].center = vec3(0.0, 0.0, 0.0);
    spheres[1].radius = 1.0;
    spheres[1].material.color = vec3(0.0, 0.0, 1.0);
    spheres[1].material.specularColor = vec3(1.0, 1.0, 1.0);
    spheres[1].material.roughness = 16.0;
    spheres[1].material.reflection = 0.0;
    spheres[1].material.refraction = 0.5;
    spheres[1].material.ior = 1.5;

    // define sphere 3: Yellow
    spheres[2].center = vec3(2.0, 0.0, 0.0);
    spheres[2].radius = 1.0;
    spheres[2].material.color = vec3(1.0, 1.0, 0.0);
    spheres[2].material.specularColor = vec3(1.0, 1.0, 1.0);
    spheres[2].material.roughness = 8.0;
    spheres[2].material.reflection = 0.8;
    spheres[2].material.refraction = 0.0;
    spheres[2].material.ior = 1.0;

    // define light 1: Red
    lights[0].position = vec3(-5.0, 5.0, -5.0);
    lights[0].color = vec3(1.0, 0.0, 0.0);
    lights[0].intensity = 0.8;

    // define light 2: Blue
    lights[1].position = vec3(0.0, 5.0, -5.0);
    lights[1].color = vec3(0.0, 0.0, 1.0);
    lights[1].intensity = 0.6;

    // define light 3: Yellow
    lights[2].position = vec3(5.0, 5.0, -5.0);
    lights[2].color = vec3(1.0, 1.0, 0.0);
    lights[2].intensity = 0.6;
}

// ray-sphere intersection function
bool intersectRaySphere(vec3 origin, vec3 direction, vec3 sphereCenter, float sphereRadius, out float t) {
    vec3 oc = origin - sphereCenter;
    float a = dot(direction, direction);
    float b = 2.0 * dot(oc, direction);
    float c = dot(oc, oc) - sphereRadius * sphereRadius;
    float discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        t = MAX_DISTANCE;
        return false;
    }
    float sqrtDiscriminant = sqrt(discriminant);
    float t0 = (-b - sqrtDiscriminant) / (2.0 * a);
    float t1 = (-b + sqrtDiscriminant) / (2.0 * a);
    if (t0 > 0.0 && t0 < t1) {
        t = t0;
        return true;
    }
    if (t1 > 0.0) {
        t = t1;
        return true;
    }
    t = MAX_DISTANCE;
    return false;
}

// compute sphere normal at a given surface position
vec3 computeSphereNormal(vec3 surfacePosition, vec3 sphereCenter) {
    return normalize(surfacePosition - sphereCenter);
}

// compute reflection direction
vec3 computeReflectionDirection(vec3 incident, vec3 normal) {
    return reflect(incident, normal);
}

// compute refraction direction using Snell's law
vec3 computeRefractionDirection(vec3 incident, vec3 normal, float ior) {
    float cosTheta = dot(-incident, normal);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
    vec3 refractionDirection = (ior * incident) + ((ior * cosTheta - sinTheta) * normal);
    return normalize(refractionDirection);
}

// calculate Fresnel factor for reflection and refraction
vec3 computeFresnelFactor(vec3 incident, vec3 normal, float ior) {
    float cosTheta = dot(-incident, normal);
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
    float cosPhi = sqrt(1.0 - (1.0 / (ior * ior)) * (1.0 - cosTheta * cosTheta));
    float parallel = ((ior * cosTheta) - cosPhi) / ((ior * cosTheta) + cosPhi);
    float perpendicular = (cosTheta - (ior * cosPhi)) / (cosTheta + (ior * cosPhi));
    return vec3(parallel * parallel, perpendicular * perpendicular, 1.0);
}

// compute lighting at a given point on the surface
vec3 computeLighting(vec3 surfacePosition, vec3 surfaceNormal, Material material) {
    vec3 viewDirection = normalize(cameraPosition - surfacePosition);
    vec3 finalColor = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < numLights; i++) {
        vec3 lightDirection = normalize(lights[i].position - surfacePosition);
        float lightDistance = length(lights[i].position - surfacePosition);
        float attenuation = 1.0 / (1.0 + 0.1 * lightDistance + 0.01 * (lightDistance * lightDistance));
        float diffuse = max(dot(surfaceNormal, lightDirection), 0.0);
        vec3 reflectionDirection = computeReflectionDirection(-lightDirection, surfaceNormal);
        float specular = pow(max(dot(reflectionDirection, viewDirection), 0.0), material.roughness);
        vec3 lightColor = lights[i].color * lights[i].intensity;
        vec3 diffuseColor = material.color * diffuse;
        vec3 specularColor = material.specularColor * specular;
        finalColor += attenuation * (diffuseColor + specularColor) * lightColor;
    }
    return finalColor;
}

// ray tracing function
vec3 rayTracing(vec3 origin, vec3 direction, int depth) {
    if (depth >= MAX_DEPTH) {
        return vec3(0.0, 0.0, 0.0);
    }
    vec3 surfaceColor = vec3(0.0, 0.0, 0.0);
    float t = MAX_DISTANCE;
    int hitSphere = -1;
    for (int i = 0; i < numSpheres; i++) {
        float sphereT;
        if (intersectRaySphere(origin, direction, spheres[i].center, spheres[i].radius, sphereT) && sphereT < t) {
            t = sphereT;
            hitSphere = i;
        }
    }
    if (hitSphere != -1) {
        vec3 surfacePosition = origin + t * direction;
        vec3 surfaceNormal = computeSphereNormal(surfacePosition, spheres[hitSphere].center);
        Material material = spheres[hitSphere].material;
        surfaceColor = computeLighting(surfacePosition, surfaceNormal, material);
        vec3 reflectionDirection = computeReflectionDirection(direction, surfaceNormal);
        vec3 reflectionColor = material.reflection * rayTracing(surfacePosition, reflectionDirection, depth + 1);
        surfaceColor += reflectionColor;
        if (material.refraction > 0.0) {
            vec3 refractionDirection = computeRefractionDirection(direction, surfaceNormal, material.ior);
            vec3 refractionColor = material.refraction * rayTracing(surfacePosition, refractionDirection, depth + 1);
            surfaceColor += refractionColor;
        }
    }
    return surfaceColor;
}

out vec4 fragColor;

// render function
void render() {
    for (int y = 0; y < int(resolution.y); y++) {
        for (int x = 0; x < int(resolution.x); x++) {
            float u = (2.0 * float(x) - resolution.x) / resolution.y;
            float v = (2.0 * float(y) - resolution.y) / resolution.y;
            vec3 direction = normalize(cameraTarget - cameraPosition + u * cameraRight + v * cameraUp);
            vec3 color = rayTracing(cameraPosition, direction, 0);
            // output color to the frame buffer
            fragColor = vec4(color, 1.0);
        }
    }
}