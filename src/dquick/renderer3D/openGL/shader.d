module dquick.renderer3D.openGL.shader;

import dquick.renderer3D.generic;
import dquick.renderer3D.iShader;
import dquick.renderer3D.openGL.util;
import dquick.utils.resourceManager;

import dquick.utils.utils;

import derelict.opengl3.gl;

import std.string;
import std.stdio;
import std.file;

import core.runtime;

import dquick.buildSettings;

static if (renderer == RendererMode.OpenGL)
final class Shader : IShader, IResource
{
	mixin ResourceBase;

public:
	this()
	{
	}
	
	~this()
	{
		debug destructorAssert(mVertexShader == mBadId, "Shader.release method wasn't called.", mTrace);
	}
	
	/// Take a filePath of which correspond to the fragment and vertex shaders files without extention (extentions are "frag" and "vert")
	/// Shader will be compiled and linked
	void	load(string filePath, Variant[] options)
	{
		debug mTrace = defaultTraceHandler(null);

		release();

		if (options == null)
		{
			mVertexShaderSource = cast(string)read(filePath ~ ".vert");
			mFragmentShaderSource = cast(string)read(filePath ~ ".frag");

/*			if (mVertexShaderSource.length == 0 || mFragmentShaderSource.length == 0)
				throw new Exception(format("Can't find shader files : %s or %s", filePath ~ ".vert", filePath ~ ".frag"));*/
		}
		else
		{
			assert(options.length == 2);
			assert(options[0].type() == typeid(string));
			assert(options[1].type() == typeid(string));

			mVertexShaderSource = options[0].get!string;
			mFragmentShaderSource = options[1].get!string;
		}

		compileAndLink();

		mWeight = 0;
		mFilePath = filePath;
	}

	IShaderProgram	getProgram()
	{
		return new ShaderProgram(mShaderProgram);
	}

	void	release()
	{
		if (mVertexShader != mBadId)
		{
			checkgl!glDeleteShader(mVertexShader);
			mVertexShader = mBadId;
		}
		if (mFragmentShader != mBadId)
		{
			checkgl!glDeleteShader(mFragmentShader);
			mFragmentShader = mBadId;
		}
		if (mShaderProgram != mBadId)
		{
			checkgl!glDeleteProgram(mShaderProgram);
			mShaderProgram = mBadId;
		}
	}

private:
	uint	loadAndCompileShader(GLenum type, string source)
	{
		GLint	length;

		length = cast(GLint)source.length;

		GLuint shader = checkgl!glCreateShader(type);
		
		auto	ssp = source.ptr;
		checkgl!glShaderSource(shader, 1, &ssp, &length);
		
		checkgl!glCompileShader(shader);
		
		GLint status;
		checkgl!glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
		
		if (status == GL_FALSE)
		{
			GLint logLength;
			checkgl!glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
			
			if (logLength > 0)
			{
				ubyte[]	log;

				log.length = logLength;
				checkgl!glGetShaderInfoLog(shader, logLength, &logLength, cast(GLchar*)log.ptr);
				
				writefln("\n%s", cast(string)log);
			}
			throw new Exception(format("Failed to compile shader: %s", filePath));
		}
		
		return shader;
	}
	
	void	compileAndLink()
	{
		scope(failure) release();

		mShaderProgram = checkgl!glCreateProgram();

		mVertexShader = loadAndCompileShader(GL_VERTEX_SHADER, mVertexShaderSource);
		if (mVertexShader == 0)
		{
			throw new Exception("Error while compiling vertex shader");
		}		

		mFragmentShader = loadAndCompileShader(GL_FRAGMENT_SHADER, mFragmentShaderSource);
		if (mFragmentShader == 0)
		{
			throw new Exception("Error while compiling fragment shader");
		}

		checkgl!glAttachShader(mShaderProgram, mVertexShader);
		checkgl!glAttachShader(mShaderProgram, mFragmentShader);

		linkProgram();
	}

	void	linkProgram()
	{
		checkgl!glLinkProgram(mShaderProgram);
		
		GLint status;
		checkgl!glGetProgramiv(mShaderProgram, GL_LINK_STATUS, &status);
		if (status == GL_FALSE)
		{
			debug	// Retrieve the log
			{
				//checkgl!glValidateProgram(mShaderProgram);
				GLint	logLength;
				checkgl!glGetProgramiv(mShaderProgram, GL_INFO_LOG_LENGTH, &logLength);
				if (logLength > 0)
				{
					GLchar[]	log = new char[](logLength);

					glGetProgramInfoLog(mShaderProgram, logLength, &logLength, log.ptr);
					if (logLength > 0)	// It seems GL_INFO_LOG_LENGTH can return 1 instead of 0
						writeln("Shader log :\n" ~ log);
				}
			}
			throw new Exception("Failed to link program");
		}
	}
	
	static const GLuint	mBadId = 0;

	GLuint	mFragmentShader = mBadId;
	GLuint	mVertexShader = mBadId;
	GLuint	mShaderProgram = mBadId;
	
	string	mFragmentShaderSource;
	string	mVertexShaderSource;

	debug Throwable.TraceInfo	mTrace;
}

static if (renderer == RendererMode.OpenGL)
final class ShaderProgram : IShaderProgram
{
public:
	this(GLuint programId)
	{
		mProgram = programId;
	}

	void	setParameter(string name, ParameterType type, void* values)
	{
		Parameter*	parameter;

		parameter = (name in mParameters);
		if (parameter is null)
		{
			Parameter	empty;
			mParameters[name] = empty;

			mParameters[name].id = checkgl!glGetUniformLocation(mProgram, name.toStringz);
			parameter = (name in mParameters);
			parameter.name = name;
		}
		parameter.type = type;
		parameter.values = values;
	}

	void	execute()
	{
		assert(mProgram != 0);

		checkgl!glUseProgram(mProgram);

		// TODO see how to limit the number of types and doing something smarter
		foreach (parameter; mParameters)
		{
			final switch (parameter.type)
			{
				case ParameterType.Int:
					glUniform1i(parameter.id, *(cast(int*)parameter.values));
					break;
				case ParameterType.Float:
					glUniform1f(parameter.id, *(cast(float*)parameter.values));
					break;
				case ParameterType.Float2D:
					glUniform2fv(parameter.id, 1, cast(float*)parameter.values);
					break;
				case ParameterType.Matrix4f:
					glUniformMatrix4fv(parameter.id, 1, false, cast(float*)parameter.values);
					break;
			}
		}
	}

	GLuint	mProgram = badId;

private:
	static const GLuint	badId = 0;

	Parameter[string]	mParameters;
};

private
struct Parameter
{
	string			name;	// For debuging
	GLint			id;
	ParameterType	type;
	void*			values;
}
