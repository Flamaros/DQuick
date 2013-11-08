module dquick.renderer3D.openGL.material;

import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.texture;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.util;
import dquick.renderer3D.openGL.renderer;

import dquick.maths.color;

import derelict.opengl3.gl;

import std.stdio;

/// It's not considered like a resource, it's not necessary as texture are already shared
/// Using a structure allow customization
struct Material
{
public:
	~this()
	{
		destroy();
	}

	bool	setTexture(string filePath)
	{
		mTexture = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Texture(filePath);
		return true;
	}

private:
	void	destroy()
	{
		dquick.renderer3D.openGL.renderer.resourceManager.releaseResource(mTexture);
		mTexture = null;
		.destroy(mShader);
	}

	static const GLuint		mBadId = 0;

	Texture					mTexture;
	Shader					mShader;
	GLint					mColorAttribute;
	GLint					mTexcoordAttribute;
}
