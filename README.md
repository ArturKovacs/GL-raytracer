GL raytracer
------------

GL raytracer is a small project that aims to achieve realtime raytracing.

This software depends on:
- SDL2 ( http://libsdl.org/index.php )
- OpenGL 3.1 ( http://www.opengl.org )
- glu ( http://www.opengl.org/resources/libraries/ )
- glew ( http://glew.sourceforge.net )
- glm ( http://glm.g-truc.net )


MOVEMENT:
You can move with w,a,s,d. Holding SHIFT will make you move faster.
If you press SPACE, your mouse will be tracked and you can look around.
Pressing SPACE again releases the mouse

Feel free to play with fragment.glsl and vertex.glsl:
The core of the raytracer is in fragment.glsl.
However there are some properties that can be changed in vertex.glsl (eg camera field of view)

TIP: Change the scene in fragment.glsl by commenting out the current sphere and
light set and uncommenting an other set. (Or even create your own scene)

You can resize the window but remember: higher resolutions will decrease performance