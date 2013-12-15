module dquick.system.guiApplication;

import dquick.utils.resourceManager;

import derelict.opengl3.gl;
import derelict.lua.lua;

import std.stdio;

interface IGuiApplication
{
	static IGuiApplication	instance();

	void	setApplicationArguments(string[] args);

	void	setApplicationDisplayName(string name);
	string	applicationDisplayName();

	int		execute();
	void	quit();
}

class GuiApplicationBase
{
public:
	void	setApplicationArguments(string[] args)
	{
		assert(mInitialized == false);
		mInitialized = true;
	}

	void	setApplicationDisplayName(string name) {mApplicationDisplayName = name;}
	string	applicationDisplayName() {return mApplicationDisplayName;}

protected:
	string	mApplicationDisplayName = "DQuick - Application";
	bool	mInitialized = false;
}

version (Windows)
{
	public import dquick.system.win32.guiApplicationWin32;
}
version (Posix)
{
	public import dquick.system.sdl.guiApplicationSDL;
}

static this()
{
	writeln("dquick.system.guiApplication : static this()");
	DerelictGL.load();
	DerelictLua.load();
}

static ~this()
{
	writeln("dquick.system.guiApplication : static ~this()");
	DerelictLua.unload();
	DerelictGL.unload();
}
