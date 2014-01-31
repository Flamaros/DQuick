module dquick.renderer2D.openGL.rectangle;

import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.texture;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.shaderProgram;
import dquick.renderer3D.openGL.VBO;
import dquick.renderer3D.openGL.util;
import dquick.renderer3D.openGL.mesh;

import dquick.maths.color;
import dquick.maths.vector2f32;
import dquick.maths.vector2s32;

import dquick.utils.utils;

import derelict.opengl3.gl;

import std.stdio;
import std.variant;

// TODO Add the possibility to update colors and texcoords

struct Rectangle
{
public:

	~this()
	{
		debug destructorAssert(mMesh.indexes is null, "Rectangle.destruct method wasn't called.", mTrace);
	}

	bool	setTexture(string filePath)
	{
		create();
		mMesh.setTexture(filePath);

		if (!mUserSize)
			mSize = Vector2f32(mMesh.texture.size().x, mMesh.texture.size().y);
		updateMesh();	// update mesh to the texture size if no user size was specified
		return true;
	}

	void	setSize(Vector2f32 newSize)
	{
		mSize = newSize;
		mUserSize = true;
		mMeshIsDirty = true;
	}

	Vector2f32	size()
	{
		return mSize;
	}

	@property void	width(float width) {setSize(Vector2f32(width, size().y));}
	@property float	width() {return mSize.x;}
	@property void	height(float height) {setSize(Vector2f32(size().x, height));}
	@property float	height() {return mSize.y;}

	void	draw()
	{
		if(mMeshIsDirty)
			updateMesh();
		mMesh.draw();
	}

	@property Vector2s32	textureSize()
	{
		if (mMesh.texture is null)
			return Vector2s32(0, 0);
		return mMesh.texture.size;
	}

	void	destruct()
	{
		mMesh.destruct();
	}

private:
	void	create()	// Safe to call it if mesh is already created
	{
		if (mMesh.indexes)
			return;

		debug mTrace = defaultTraceHandler(null);

		mMesh.construct();

		Variant[] options;
		options ~= Variant(import("rectangle.vert"));
		options ~= Variant(import("rectangle.frag"));
		mShader = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Shader("rectangle", options);
		mShaderProgram.program = mShader.getProgram();
		mMesh.setShader(mShader);
		mMesh.setShaderProgram(mShaderProgram);

		mMesh.indexes.setArray(cast(GLuint[])[0, 1, 2, 1, 3, 2], cast(GLenum)GL_STATIC_DRAW);

		mMesh.geometry.setArray(geometryArray(), cast(GLenum)GL_DYNAMIC_DRAW);

		mMeshIsDirty = false;
	}

	void	updateMesh()
	{
		create();	// TODO find a way to avoid update just after creation

		mMesh.geometry.updateArray(geometryArray());
		
		mMeshIsDirty = false;
	}

	GLfloat[]	geometryArray()
	{
		return cast(GLfloat[])[
			0.0f,		0.0f,		0.0f,	1.0f, 1.0f, 1.0f, 1.0f,		0.0f, 0.0f,		
			mSize.x,	0.0f,		0.0f,	1.0f, 1.0f, 1.0f, 1.0f,		1.0f, 0.0f,		
			0.0f,		mSize.y,	0.0f,	1.0f, 1.0f, 1.0f, 1.0f,		0.0f, 1.0f,		
			mSize.x,	mSize.y,	0.0f,	1.0f, 1.0f, 1.0f, 1.0f,		1.0f, 1.0f];
	}

	bool			mUserSize;
	Vector2f32		mSize;
	Mesh			mMesh;
	bool			mMeshIsDirty; // indicates that mesh has to be rebuilt in next draw() call.
	Shader			mShader;
	ShaderProgram	mShaderProgram;

	debug Throwable.TraceInfo	mTrace;
}
