
#define GLM_FORCE_RADIANS 1

#include <GL/glew.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include <iostream>
#include <fstream>
#include <string>

class custom_exception {
public:
	std::string m;
	custom_exception(const std::string& message):m(message){}
	const char* get_message()const {return m.c_str();}
};

void custom_warning(std::string message)
{
	std::cout << "Warning: " << message << std::endl;
}

struct camera {
	glm::vec3 pos;
	float rotx;
	float roty;
};
camera cameraTransform = {glm::vec3(0, 32, 50), -0.3f, 0};
//camera cameraTransform = {glm::vec3(14, 7, 9), -0.1, PI-0.1};

const float PI = glm::pi<float>();

const int INIT_WINDOW_WIDTH = 720;
const int INIT_WINDOW_HEIGHT = 480;

int curr_screen_width = INIT_WINDOW_WIDTH;
int curr_screen_height = INIT_WINDOW_HEIGHT;

//4 vertices * (2 NDC coordinate per vertex + 3 world coordinates per vertex)
const int vertexDataSize = 4*(2+3);

const float mouseSensitivity = 0.0017f;

bool mouseControllEnabled = SDL_FALSE;
const float baseMovementSpeed = 10.f;
const float fastMovementSpeed = 50.f;
float currentMovementSpeed = baseMovementSpeed;
short forwardMovement = 0;
short leftMovement = 0;

double lastUpdateTime = 0;

SDL_Window* window = NULL;
SDL_GLContext GLcontext;

GLuint fragmentShaderID = 0;
GLuint vertexShaderID = 0;
GLuint programID = 0;
//sh stands for shader. It means that these are variables located in shader programs
GLint sh_cameraTransform = -1;
GLint sh_time = -1;
GLint sh_NDCpos = -1;
GLint sh_vertexWorldPos = -1;
GLuint VBO = 0;
GLuint IBO = 0;

bool loadStringFromFile(const char* filename, std::string& result)
{
	bool succes = false;
	
	std::ifstream file(filename);
	
	if(file.is_open()) {
		char c;
	
		while(file.get(c)) {
			result += c;
		}
		
		if(file.eof()) {
			succes = true;
		}
	}
	
	return succes;
}

bool getProgramInfoLog(GLuint program, std::string& log)
{
	bool succes = false;
	
	if(glIsProgram(program)) {
		int requiredLength = 0;
		glGetProgramiv(program, GL_INFO_LOG_LENGTH, &requiredLength);
		log.resize(requiredLength);
		
		if(0 != requiredLength) {
			glGetProgramInfoLog(program, requiredLength, NULL, (char*)log.data());
		}
		
		succes = true;
	}
	else {
		succes = false;
	}
	
	return succes;
}

bool getShaderInfoLog(GLuint shader, std::string& log)
{
	bool succes = false;
	
	if(glIsShader(shader)) {
		int requiredLength = 0;
		glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &requiredLength);
		log.resize(requiredLength);
		
		if(0 != requiredLength) {
			glGetShaderInfoLog(shader, requiredLength, NULL, (char*)log.data());
		}
		
		succes = true;
	}
	else {
		succes = false;
	}
	
	return succes;
}

void GenerateVertexData(GLfloat outputData[vertexDataSize])
{
	GLfloat vertexData[] = {
		//2d Normalized Device Coordinates
		-1.0f,	-1.0f,
		//3d World Coordinates (first two coordinates will be filled up by the code below)
		0,		0,		-2.0f,
		
		1.0f,	-1.0f,
		0,		0,		-2.0f,
		
		1.0f,	1.0f,
		0,		0,		-2.0f,
		
		-1.0f,	1.0f,
		0,		0,		-2.0f,
	};
	
	float ratioForX;
	float ratioForY;
	
	if(curr_screen_width > curr_screen_height) {
		ratioForX = float(curr_screen_width) / curr_screen_height;
		ratioForY = 1.f;
	}
	else {
		ratioForX = 1.f;
		ratioForY = float(curr_screen_height) / curr_screen_width;
	}
	
	for(int i = 0; i < vertexDataSize; i+=4) {
		vertexData[i+2] = vertexData[i] * ratioForX;
		i+=1;
		vertexData[i+2] = vertexData[i] * ratioForY;
	}
	
	//copy created data to the output
	for(int i = 0; i < vertexDataSize; i+=1) {
		outputData[i] = vertexData[i];
	}
}

//throws exeption
void Init()
{
	if(SDL_Init(SDL_INIT_VIDEO) < 0) {
		throw custom_exception((std::string("Can not init SDL: ") + SDL_GetError()));
	}
	
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	
	window = SDL_CreateWindow("GL raytracer", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, INIT_WINDOW_WIDTH, INIT_WINDOW_HEIGHT, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_SHOWN);
	if(NULL == window) {
		throw custom_exception((std::string("Can not create window: ") + SDL_GetError()));
	}
	
	GLcontext = SDL_GL_CreateContext(window);
	if(NULL == GLcontext) {
		throw custom_exception((std::string("Can not create OpenGL context: ") + SDL_GetError()));
	}
	
	GLenum error_code = glewInit();
	if(GLEW_OK != error_code) {
		throw custom_exception((std::string("Can not init GLEW: ") + (const char*)glewGetErrorString(error_code)));
	}
	
	//Turn on Vsync with late swap tearing, if supported
	if(SDL_GL_SetSwapInterval(-1) < 0) {
		custom_warning(std::string("Can not turn Vsync ON with late swap tearing. Using immediate updates (Vsync OFF) instead.\n") + SDL_GetError());
		SDL_GL_SetSwapInterval(0);
	}
	
	//note that glClearColor color does not have any effect, because we always draw a quad that completely covers the screen
	//(the background color is determined, by the fragment shader)
	glClearColor( 1.f, 1.f, 1.f, 1.f );
	
	//////////////////////////////////////
	//Set up shaders...
	//////////////////////////////////////
	
	programID = glCreateProgram();
	
	vertexShaderID = glCreateShader(GL_VERTEX_SHADER);
	
	std::string vertexShaderSource;
	const GLchar *vertexShaderToFunction[1];
	const char* vertexShaderFilename = "vertex.glsl";
	if(!loadStringFromFile(vertexShaderFilename, vertexShaderSource)) {
		throw custom_exception(std::string("Can not load file: ") + vertexShaderFilename);
	}
	
	vertexShaderToFunction[0] = vertexShaderSource.c_str();
	
	glShaderSource(vertexShaderID, 1, vertexShaderToFunction, NULL);
	glCompileShader(vertexShaderID);
	
	std::string shaderlog;
	const char* logEndSeparator = "-end of log----------------------------";
	getShaderInfoLog(vertexShaderID, shaderlog);
	std::cout << "Vertex shader log:\n" << shaderlog << std::endl << logEndSeparator << std::endl;
	
	GLint success = GL_FALSE;
	glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, &success);
	if(GL_TRUE != success) {
		throw custom_exception(std::string("Error while compiling vertex shader!"));
	}
	
	glAttachShader(programID, vertexShaderID);
	fragmentShaderID = glCreateShader(GL_FRAGMENT_SHADER);
	
	std::string fragmentShaderSource;
	const GLchar *fragmentShaderToFunction[1];
	const char* fragmentShaderFilename = "fragment.glsl";
	if(!loadStringFromFile(fragmentShaderFilename, fragmentShaderSource)) {
		throw custom_exception(std::string("Can not load file: ") + fragmentShaderFilename);
	}
	
	fragmentShaderToFunction[0] = fragmentShaderSource.c_str();
	glShaderSource(fragmentShaderID, 1, fragmentShaderToFunction, NULL);
	glCompileShader(fragmentShaderID);
	
	getShaderInfoLog(fragmentShaderID, shaderlog);
	std::cout << "Fragment shader log:\n" << shaderlog << std::endl << logEndSeparator << std::endl;
	
	success = GL_FALSE;
	glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, &success);
	if(GL_TRUE != success) {
		throw custom_exception(std::string("Error while compiling fragment shader!"));
	}
	
	glAttachShader(programID, fragmentShaderID);
	glLinkProgram(programID );
	
	success = GL_TRUE;
	glGetProgramiv(programID, GL_LINK_STATUS, &success);
	if(GL_TRUE != success) {
		std::string log;
		getProgramInfoLog(programID, log);
		throw custom_exception(std::string("Error while linking program:\n") + log);
	}
	
	sh_time = glGetUniformLocation(programID, "time");
	if(-1 == sh_time) {
		custom_warning("Can not get uniform location for \"time\"");
	}
	
	sh_cameraTransform = glGetUniformLocation(programID, "cameraTransform");
	if(-1 == sh_cameraTransform) {
		throw custom_exception("Can not get uniform location for \"cameraTransform\"");
	}
	
	sh_NDCpos = glGetAttribLocation(programID, "NDCpos");
	if(-1 == sh_NDCpos) {
		throw custom_exception("Can not get attribute location for \"NDCpos\"");
	}
	
	sh_vertexWorldPos = glGetAttribLocation(programID, "VertexWorldPos");
	if(-1 == sh_vertexWorldPos) {
		throw custom_exception("Can not get attribute location for \"VertexWorldPos\"");
	}
	
	glDetachShader(programID, vertexShaderID);
	glDetachShader(programID, fragmentShaderID);
	glDeleteShader(vertexShaderID);
	glDeleteShader(fragmentShaderID);
	
	GLfloat vertexData[vertexDataSize];
	GenerateVertexData(vertexData);
	
	GLuint indexData[] = { 0, 1, 2, 3 };
	
	glGenBuffers(1, &VBO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, vertexDataSize * sizeof(GLfloat), vertexData, GL_STATIC_DRAW);
	
	glVertexAttribPointer(sh_NDCpos, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), NULL );
	glVertexAttribPointer(sh_vertexWorldPos, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (void*)(2*sizeof(GLfloat)) );
	glEnableVertexAttribArray(sh_NDCpos);
	glEnableVertexAttribArray(sh_vertexWorldPos);
	
	glGenBuffers(1, &IBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4 * sizeof(GLuint), indexData, GL_STATIC_DRAW);
	
	glUseProgram(programID);
}

void Cleanup()
{
	glDeleteProgram(programID);
	
	SDL_DestroyWindow(window);
	window = NULL;
	
	SDL_Quit();
}

void handleKeys(const SDL_KeyboardEvent& keyevent)
{
	switch(keyevent.keysym.sym) {
		case SDLK_SPACE:
			if(SDL_KEYDOWN == keyevent.type) {
				mouseControllEnabled = !mouseControllEnabled;
				SDL_SetRelativeMouseMode((SDL_bool)mouseControllEnabled);
			}
			break;
			
		case 'a':
			if(SDL_KEYDOWN == keyevent.type) leftMovement = 1;
			else if(1 == leftMovement) leftMovement = 0;
			break;
			
		case 'd':
			if(SDL_KEYDOWN == keyevent.type) leftMovement = -1;
			else if(-1 == leftMovement) leftMovement = 0;
			break;
			
		case 'w':
			if(SDL_KEYDOWN == keyevent.type) forwardMovement = 1;
			else if(1 == forwardMovement) forwardMovement = 0;
			break;
			
		case 's':
			if(SDL_KEYDOWN == keyevent.type) forwardMovement = -1;
			else if(-1 == forwardMovement) forwardMovement = 0;
			break;
			
		case SDLK_LSHIFT:
		case SDLK_RSHIFT:
			currentMovementSpeed = (SDL_KEYDOWN == keyevent.type) ? fastMovementSpeed : baseMovementSpeed;
			break;
			
		default:
			break;
	}
}

void handleMouseMotion(const SDL_MouseMotionEvent& motion)
{
	if(mouseControllEnabled) {
		cameraTransform.roty -= motion.xrel * mouseSensitivity;
		cameraTransform.rotx -= motion.yrel * mouseSensitivity;
		
		cameraTransform.rotx = glm::min(glm::max(cameraTransform.rotx, -PI/2.0f), PI/2.0f);
	}
}

void Update()
{
	const double currTime = SDL_GetTicks() / 1000.0;
	const float deltaTime = currTime - lastUpdateTime;
	lastUpdateTime = currTime;
	
	glm::mat4 rotationMatrix = glm::rotate(glm::mat4(1.0f), cameraTransform.roty, glm::vec3(0.0f, 1.0f, 0.0f));
	rotationMatrix = glm::rotate(rotationMatrix, cameraTransform.rotx, glm::vec3(1.0f, 0.0f, 0.0f));;
	
	glm::vec3 forward = glm::vec3(0.0f, 0.0f, -1.0f);
	forward = glm::vec3(rotationMatrix * glm::vec4(forward, 1.0f));
	
	glm::vec3 left = glm::vec3(-1.0f, 0.0f, 0.0f);
	left = glm::vec3(rotationMatrix * glm::vec4(left, 1.0f));
	
	cameraTransform.pos += forward * float(forwardMovement) * deltaTime * currentMovementSpeed;
	cameraTransform.pos += left * float(leftMovement) * deltaTime * currentMovementSpeed;
	
	glm::mat4 camMatrix = glm::translate(glm::mat4(1.0f), cameraTransform.pos);
	camMatrix = glm::rotate(camMatrix, cameraTransform.roty, glm::vec3(0.0f, 1.0f, 0.0f));
	camMatrix = glm::rotate(camMatrix, cameraTransform.rotx, glm::vec3(1.0f, 0.0f, 0.0f));
	
	//glUseProgram( programID );
	glUniform1f(sh_time, currTime);
	glUniformMatrix4fv(sh_cameraTransform, 1, GL_FALSE, glm::value_ptr(camMatrix));
	//glUseProgram( NULL );
}

void Render()
{
	//everything have been set at the end of the initialization
	//glUseProgram(programID);
	
	//glBindBuffer(GL_ARRAY_BUFFER, VBO);
	//glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IBO);
	glDrawElements(GL_TRIANGLE_FAN, 4, GL_UNSIGNED_INT, NULL);
	
	//glUseProgram(NULL);
}

int main(int argc, char* args[])
{
	try {
		Init();
		
		SDL_Event e;
		bool quit = false;
		while( !quit ) {
			while( SDL_PollEvent( &e ) != 0 ) {
				if(SDL_QUIT == e.type) {
					quit = true;
				}
				else if(SDL_KEYDOWN == e.type || SDL_KEYUP == e.type) {
					handleKeys(e.key);
					
					if(SDLK_ESCAPE == e.key.keysym.sym) {
						quit = true;
					}
				}
				else if(SDL_WINDOWEVENT == e.type) {
					if(SDL_WINDOWEVENT_RESIZED == e.window.event) {
						curr_screen_width = e.window.data1;
						curr_screen_height = e.window.data2;
						
						glViewport(0, 0, curr_screen_width, curr_screen_height);
						
						GLfloat vertexData[vertexDataSize];
						GenerateVertexData(vertexData);
						
						glBindBuffer(GL_ARRAY_BUFFER, VBO);
						glBufferSubData(GL_ARRAY_BUFFER, 0, vertexDataSize * sizeof(GLfloat), vertexData);
					}
				}
				else if(SDL_MOUSEMOTION == e.type) {
					handleMouseMotion(e.motion);
				}
			}
			
			Update();
			Render();
			
			SDL_GL_SwapWindow(window);
		}
		
		Cleanup();
	}
	catch(std::exception& ex) {
		std::cout << "Exception:" << std::endl;
		std::cout << ex.what() << std::endl;
	}
	catch(custom_exception& ex) {
		std::cout << "Exception:" << std::endl;
		std::cout << ex.m << std::endl;
	}
	
	return 0;
}