GL raytracer
------------

GL raytracer is a small project that aims to achieve realtime raytracing.

This software depends on:
- SDL2 ( http://libsdl.org/index.php )
- glew ( http://glew.sourceforge.net )
- glm ( http://glm.g-truc.net )
- OpenGL 3.1 ( http://www.opengl.org ) (should be installed by default)

Latest binary download available on the github [releases](https://github.com/ArturKovacs/GL-raytracer/releases) page.
(Binary is for windows only. If you are learning linux, and want to build on a linux distribution,
i strognly recommend you to download the dependencies from your software manager. For detailed instructions
please go to [How to make it work on linux](https://github.com/ArturKovacs/GL-raytracer/wiki/How-to-make-it-work-on-linux) )

MOVEMENT:
You can move with w,a,s,d. Holding SHIFT will make you move faster.
If you press SPACE, your mouse will be tracked and you can look around.
Pressing SPACE again releases the mouse.

Feel free to play with fragment.glsl and vertex.glsl:
The core of the raytracer is in fragment.glsl.
However there are some properties that can be changed in vertex.glsl (eg camera field of view).

TIP: Change the scene in fragment.glsl by commenting out the current sphere and
light set and uncommenting an other set. (Or even create your own scene!)

You can resize the window but remember: higher resolutions will decrease performance!

If you want a better performace: (in fragment.glsl) it is recommended to set "ENABLE_SHADOWS" to 0,
and to set "maxLightBounces" to a lower value. Also the scene strongly effects performance
(number of objects, number of reflective and refractive objects).
