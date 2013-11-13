module dquick.system.xcb.openglContextXCB;

version (linux)
{
	import derelict.opengl3.wgl;
	import derelict.opengl3.gl;

	import dquick.renderer3D.openGL.renderer;
	import dquick.maths.matrix4x4;
	import dquick.maths.vector2s32;

	class OpenGLContext
	{
	public:
		~this()
		{
			release;
		}

		void	makeCurrent()
		{
		}

		void	swapBuffers()
		{
		}

		void	resize(int width, int height)
		{
			if (height == 0)										// Prevent A Divide By Zero By
				height=1;											// Making Height Equal One

			Renderer.setViewportSize(Vector2s32(width, height));						// Reset The Current Viewport

			Matrix4x4	camera;
			camera = Matrix4x4.orthographic(0.0, width, height, 0.0, -100.0, 100.0);
			Renderer.currentCamera(camera);
		}

		void	release()
		{
		}

	private:
	}
}
