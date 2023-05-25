#version 410 core

// define the maximum depth for ray recursion
const int maxDepth = 5;

// define the epsilon value for shadow ray origin offset
const float epsilon = 0.001;

// define the number of samples for indirect lighting
const int numSamples = 16;

// define screen resolution
uniform vec2 resolution = vec2(1920 * 0.6, 1920 * 0.6);

// define camera properties
uniform vec3 cameraPosition = vec3(0.0, 0.0, -1.0);
uniform vec3 cameraTarget = vec3(0.0);
uniform vec3 cameraUp = vec3(0.0, 1.0, 0.0);

// structure for holding intersection information
struct IntersectResult {
    bool hit;
    vec3 position;
    vec3 normal;
    // add any additional relevant information here
};

// structure for holding material properties
struct Material {
    vec3 color;
    // add any additional material properties here
};

// scene setup function
void setupScene() {
    // define your scene objects, materials, and light sources here
    // ...

    // set up any necessary data structures or buffers
    // ...
}

// main ray tracing function
vec3 traceRay(vec2 uv) {
    // compute ray origin and direction from uv coordinates
    vec2 deviceCoords = (uv / resolution) * 2 - 1;  // getting the local device coordinates from the resultion in range [-1, 1]
    vec4 rayDirection = vec4(deviceCoords.x, deviceCoords.y, -1.0, 0.0);    // compute the ray direction from the position of each pixel

    // compute the camera's view inverse matrix that converts camera coordinates to world coordinates
    vec3 cameraForward = normalize(cameraTarget - cameraPosition);
    vec3 worldUp = vec3(0.0, 1.0, 0.0);
    vec3 cameraRight = normalize(cross(worldUp, cameraForward));
    
    // create the camera's view matrix to get its inverse
    mat4 cameraViewMatrix = mat4(
        vec4(cameraRight, 0.0),
        vec4(cameraUp, 0.0),
        vec4(-cameraForward, 0.0),
        vec4(cameraPosition, 0.0)
    );

    mat4 cameraViewInverse = inverse(cameraViewMatrix);

    // get normalized ray direction in world space
    rayDirection = cameraViewInverse * rayDirection;  // convert ray direction to world coordinates
    rayDirection = (normalize(rayDirection));

    // perform ray tracing
    // ...

    // return the final color
    return vec3(1.0); // placeholder for now
}

// check for sphere intersection through quadratic method
bool intersectSphere(vec3 rayOrigin, vec3 rayDirection, vec3 sphereCenter, float sphereRadius, out float t) {
    vec3 oc = rayOrigin - sphereCenter;
    float a = dot(rayDirection, rayDirection);
    float b = 2.0 * dot(oc, rayDirection);
    float c = dot(oc, oc) - sphereRadius * sphereRadius;
    float discriminant = b * b - 4.0 * a * c;

    if (discriminant > 0.0) {
        float t0 = (-b - sqrt(discriminant)) / (2.0 * a);
        float t1 = (-b + sqrt(discriminant)) / (2.0 * a);
        if (t0 > 0.0) {
            t = t0;
            return true;
        } else if (t1 > 0.0) {
            t = t1;
            return true;
        }
    }

    return false;
}

// check for triangle intersection through Möller-Trumbore method (adapted from Wikipedia's C++ implementation)
// https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
bool intersectTriangle(vec3 rayOrigin, vec3 rayVector, vec3 vertex0, vec3 vertex1, vec3 vertex2, out vec3 outIntersectionPoint) {
    const float EPSILON = 0.0000001;
    vec3 edge1, edge2, h, s, q;
    float a, f, u, v;
    edge1 = vertex1 - vertex0;
    edge2 = vertex2 - vertex0;
    h = cross(rayVector, edge2);
    a = dot(edge1, h);

    if (abs(a) < EPSILON)
        return false;    // this ray is parallel to this triangle

    f = 1.0 / a;
    s = rayOrigin - vertex0;
    u = f * dot(s, h);

    if (u < 0.0 || u > 1.0)
        return false;

    q = cross(s, edge1);
    v = f * dot(rayVector, q);

    if (v < 0.0 || u + v > 1.0)
        return false;

    // at this stage we can compute t to find out where the intersection point is on the line
    float t = f * dot(edge2, q);

    if (t > EPSILON) { // ray intersection
        outIntersectionPoint = rayOrigin + rayVector * t;
        return true;
    }
    else // this means that there is a line intersection but not a ray intersection
        return false;
}


// scene intersection function
IntersectResult intersectScene(vec3 rayOrigin, vec3 rayDirection) {
    // implement your ray-object intersection tests here
    // ...

    // placeholder implementation for now
    IntersectResult result;
    result.hit = false;
    return result;
}

// shading function
vec3 shade(vec3 surfacePosition, vec3 surfaceNormal, Material material) {
    // implement your shading model here
    // ...

    // placeholder implementation for now
    return material.color;
}

// compute direct lighting from light sources
vec3 computeDirectLighting(vec3 surfacePosition, vec3 surfaceNormal) {
    // compute direct lighting contributions from light sources
    // ...

    // placeholder implementation for now
    return vec3(1.0); // White color
}

// random hemisphere direction function
vec3 randomHemisphereDirection(vec3 surfaceNormal) {
    // generate a random direction within the hemisphere oriented around the surface normal
    // ...

    // placeholder implementation for now
    return normalize(vec3(0.0, 1.0, 0.0)); // Up direction
}

// entry point function
void main() {
    // set up the scene
    setupScene();

    // obtain the UV coordinates for the current fragment
    vec2 uv = gl_FragCoord.xy / resolution; // Adjust resolution as needed

    // trace the ray and obtain the final color
    vec3 finalColor = traceRay(uv);

    // output the final color to the screen
    gl_FragColor = vec4(finalColor, 1.0);
}