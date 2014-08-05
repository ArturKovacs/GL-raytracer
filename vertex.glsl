#version 130
in vec2 NDCpos;
in vec3 VertexWorldPos;
out vec3 WorldPosFromVer;
flat out vec3 eyePos;
uniform mat4 cameraTransform;

void main()
{
	WorldPosFromVer = (cameraTransform * vec4(VertexWorldPos.xyz, 1)).xyz;
	eyePos = (cameraTransform * vec4(0, 0, 0, 1)).xyz;
	gl_Position = vec4( NDCpos, 0, 1 );
}
