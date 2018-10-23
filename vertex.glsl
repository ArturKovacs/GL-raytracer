#version 140
in vec2 NDCpos;
in vec3 VertexWorldPos;
out vec3 rayDirFromVer;
flat out vec3 eyePos;
uniform mat4 cameraTransform;

void main()
{
    eyePos = (cameraTransform * vec4(0, 0, 0, 1)).xyz;
    rayDirFromVer = (cameraTransform * vec4(VertexWorldPos.xyz, 1)).xyz - eyePos;
    gl_Position = vec4( NDCpos, 0, 1 );
}
