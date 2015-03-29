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
I strognly recommend you to download the dependencies from your software manager. For detailed instructions
please go to [How to make it work on linux](https://github.com/ArturKovacs/GL-raytracer/wiki/How-to-make-it-work-on-linux) )

### Movement ###
You can move with w,a,s,d. Holding SHIFT will make you move faster.
Pressing SPACE will capture the mouse.
You can look around with the mouse while it is captured.
Pressing SPACE again releases the mouse.

### Additional tips ###
Feel free to play with fragment.glsl and vertex.glsl:
The core of the raytracer is in fragment.glsl.
However there are some properties that can be changed in vertex.glsl (eg camera field of view).

Change the scene in fragment.glsl by commenting out the current set of spheres, boxes and
lights and uncommenting an other set. (Or even create your own scene!)

You can resize the window but remember: higher resolutions will decrease performance!

If you want a better performace: (in fragment.glsl) it is recommended to set "ENABLE_SHADOWS" to 0,
and to set "maxLightBounces" to a lower value. Also the scene strongly affects performance
(number of objects, number of reflective and refractive objects).
