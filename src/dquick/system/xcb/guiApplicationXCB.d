module dquick.system.xcb.guiApplicationXCB;

import derelict.lua.lua;

version (linux)
{
	import dquick.system.guiApplication;
	import dquick.item.declarativeItem;
	import dquick.item.graphicItem;
	import dquick.system.window;
	import dquick.maths.vector2s32;
	import dquick.item.imageItem;
	import dquick.item.textItem;
	import dquick.item.borderImageItem;
	import dquick.item.mouseAreaItem;
	import dquick.item.scrollViewItem;
	import dquick.script.dmlEngine;

	import std.path;
	import std.stdio;
	import std.stdint;

	pragma(lib, "X11");
	pragma(lib, "X11-xcb");
	pragma(lib, "xcb");

	import dquick.system.xcb.openglContextXCB;
	import deimos.X11.Xlib;
	import deimos.X11.Xlib_xcb;
	import deimos.XCB.xcb;
	import deimos.XCB.xproto;

	// TODO remove : normally in openglContextXXB.d
	import derelict.opengl3.glx;

	class GuiApplication : IGuiApplication
	{
	public:
		static this()
		{
			DerelictGL.load();
			DerelictLua.load();

			/* Open Xlib Display */ 
			mDisplay = XOpenDisplay(null);
			if (!mDisplay)
				throw new Exception("Can't open display");

			mDefaultScreen = DefaultScreen(mDisplay);
			
			/* Get the XCB connection from the display */
			mConnection = XGetXCBConnection(mDisplay);
			scope(failure) XCloseDisplay(mDisplay);
			if (!mConnection)
				throw new Exception("Can't get xcb connection from display");

			/* Acquire event queue ownership */
			XSetEventQueueOwner(mDisplay, XEventQueueOwner.XCBOwnsEventQueue);
			
			/* Find XCB screen */
			mScreen = null;
			xcb_screen_iterator_t	screen_iter =xcb_setup_roots_iterator(xcb_get_setup(mConnection));
			for (int screen_num = mDefaultScreen; screen_iter.rem && screen_num > 0; --screen_num, xcb_screen_next(&screen_iter))
			{
			}
			mScreen = screen_iter.data;
		}
		
		static ~this()
		{
			/* Cleanup */
			XCloseDisplay(mDisplay);

			DerelictLua.unload();
			DerelictGL.unload();
		}
		
		static GuiApplication	instance()
		{
			if (mInstance is null)
				mInstance = new GuiApplication;
			return mInstance;
		}

		void	setApplicationArguments(string[] args)
		{
			assert(mInitialized == false);

			mApplicationDirectory = dirName(args[0]) ~ dirSeparator;

			mInitialized = true;
		}

		void	setApplicationDisplayName(string name) {mApplicationDisplayName = name;}
		string	applicationDisplayName() {return mApplicationDisplayName;}

		string	directoryPath() {return mApplicationDirectory;}	/// Return the path of this application

		int	execute()
		{
			while (!mQuit)
			{
				/* Wait for event */
				xcb_generic_event_t *event = xcb_wait_for_event(mConnection);
				if (!event)
				{
					writefln("i/o error in xcb_wait_for_event");
					return -1;
				}
				
				switch (event.response_type & ~0x80)
				{
					case XCB_KEY_PRESS:
						/* Quit on key press */
						mQuit = true;
						break;
					case XCB_EXPOSE:
						/* Handle expose event, draw and swap buffers */
						if (!mQuit)
							foreach (Window window; mWindows)
							{
								window.onPaint();
//								glXSwapBuffers(display, drawable);
							}
						break;
					default:
						break;
				}
				free(event);
			}
			return 0;
		}

		void	quit()
		{
			mQuit = true;
		}

		//==========================================================================
		//==========================================================================

	private:
		this() {}

/*		static void	registerWindow(Window window, HWND windowHandle)
		{
			mWindows[windowHandle] = window;
		}*/

		static GuiApplication		mInstance;
		static bool					mQuit = false;

		static string				mApplicationDisplayName = "DQuick - Application";
		static string				mApplicationDirectory = ".";
		static bool					mInitialized = false;

		static xcb_connection_t*	mConnection;
		static Display*				mDisplay;
		static int					mDefaultScreen;
		static xcb_screen_t*		mScreen;

		static Window[xcb_window_t]	mWindows;
	}

	//==========================================================================
	//==========================================================================

	class Window : IWindow
	{
		this()
		{
			mWindowId = mWindowsCounter++;
			mScriptContext = new DMLEngine;
			mScriptContext.create();
			mScriptContext.addItemType!(DeclarativeItem, "Item")();
			mScriptContext.addItemType!(GraphicItem, "GraphicItem")();
			mScriptContext.addItemType!(ImageItem, "Image")();
			mScriptContext.addItemType!(TextItem, "Text")();
			mScriptContext.addItemType!(BorderImageItem, "BorderImage")();
			mScriptContext.addItemType!(MouseAreaItem, "MouseArea")();
			mScriptContext.addItemType!(ScrollViewItem, "ScrollView")();
		}

		~this()
		{
			destroy();
		}

		bool	create()
		{
			/* Initialize window and OpenGL context, run main loop and deinitialize */
			int visualID = 0;
			
			/* Query framebuffer configurations */
			GLXFBConfig*	fb_configs = null;
			int				num_fb_configs = 0;
			
			fb_configs = glXGetFBConfigs(GuiApplication.mDisplay, GuiApplication.mDefaultScreen, &num_fb_configs);
			if (!fb_configs || num_fb_configs == 0)
			{
				writefln("glXGetFBConfigs failed");
				return false;
			}
			
			/* Select first framebuffer config and query visualID */
			GLXFBConfig	fb_config = fb_configs[0];
			glXGetFBConfigAttrib(GuiApplication.mDisplay, fb_config, GLX_VISUAL_ID , &visualID);
			
			/* Create OpenGL context */
			context = glXCreateNewContext(GuiApplication.mDisplay, fb_config, GLX_RGBA_TYPE, null, True);
			if (!context)
			{
				writefln("glXCreateNewContext failed");
				return false;
			}
			
			/* Create XID's for colormap and window */
			xcb_colormap_t	colormap = xcb_generate_id(GuiApplication.mConnection);

			mWindow = xcb_generate_id(GuiApplication.mConnection);
			
			/* Create colormap */
			xcb_create_colormap(GuiApplication.mConnection, xcb_colormap_alloc_t.XCB_COLORMAP_ALLOC_NONE, colormap, GuiApplication.mScreen.root, visualID);
			
			/* Create window */
			uint32_t	eventmask = xcb_event_mask_t.XCB_EVENT_MASK_EXPOSURE | xcb_event_mask_t.XCB_EVENT_MASK_KEY_PRESS;
			uint32_t	valuelist[] = [eventmask, colormap, 0];
			uint32_t	valuemask = xcb_cw_t.XCB_CW_EVENT_MASK | xcb_cw_t.XCB_CW_COLORMAP;
			
			xcb_create_window(GuiApplication.mConnection, XCB_COPY_FROM_PARENT, mWindow, GuiApplication.mScreen.root,
			                  0, 0,
			                  150, 150,
			                  0, cast(ushort)xcb_window_class_t.XCB_WINDOW_CLASS_INPUT_OUTPUT, visualID, valuemask, valuelist.ptr);

			// NOTE: window must be mapped before glXMakeContextCurrent
			xcb_map_window(GuiApplication.mConnection, mWindow); 
			
			/* Create GLX Window */
			GLXDrawable	drawable = 0;
			
			mGLXWindow = glXCreateWindow(GuiApplication.mDisplay, fb_config, mWindow, null);
			
			if (!mWindow)
			{
				xcb_destroy_window(GuiApplication.mConnection, mWindow);
				glXDestroyContext(GuiApplication.mDisplay, context);
				
				writefln("glXDestroyContext failed");
				return false;
			}
			
			drawable = mGLXWindow;
			
			/* make OpenGL context current */
			if (!glXMakeContextCurrent(GuiApplication.mDisplay, drawable, drawable, context))
			{
				xcb_destroy_window(GuiApplication.mConnection, mWindow);
				glXDestroyContext(GuiApplication.mDisplay, context);

				writefln("glXMakeContextCurrent failed");
				return false;
			}

			/* run main loop */
//			int	retval = main_loop(display, connection, mWindow, drawable);
			
			return true;
		}

		void	show()
		{
		}

		void	destroy()
		{
			.destroy(mScriptContext);
			.destroy(mContext);
			mContext = null;

			/* Cleanup */
			glXDestroyWindow(GuiApplication.mDisplay, mGLXWindow);
			xcb_destroy_window(GuiApplication.mConnection, mWindow);
			glXDestroyContext(GuiApplication.mDisplay, context);

/*			DestroyWindow(mhWnd);
			if (mWindowId == 0)
				GuiApplication.instance.quit();*/
		}

		/// Window will take size of this item
		void	setMainItem(GraphicItem item)
		{
			mRootItem = item;
		}

		/// Window will take size of this item
		void	setMainItem(string filePath)
		{
			mScriptContext.executeFile(filePath);

			mRootItem = cast(GraphicItem)mScriptContext.rootItem();
			assert(mRootItem);

			mRootItem.setSize(Vector2f32(size()));
		}

		GraphicItem	mainItem() {return mRootItem;}

		void		setPosition(Vector2s32 newPosition)
		{
			// TODO
			if (fullScreen()/* || maximized()*/)	// Will put corrupted values
				return;

			mPosition = newPosition;	// Utilise pour la creation de la fenetre

/*			if (!mhWnd)
				return;

			RECT	rcWindow;
			GetWindowRect(mhWnd, &rcWindow);	// Retourne des valeurs valides
			mPosition = Vector2s32(rcWindow.left, rcWindow.top);*/

			// Rien d'autre a faire car Windows deplace directement la fenetre
		}
		Vector2s32	position() {return mPosition;}

		void	setSize(Vector2s32 newSize)
		{
			mSize = newSize;

			if (mRootItem)
				mRootItem.setSize(Vector2f32(newSize));

			// Resizing Window
/*			RECT	rcClient, rcWindow;
			POINT	ptDiff;

			GetClientRect(mhWnd, &rcClient);
			GetWindowRect(mhWnd, &rcWindow);
			ptDiff.x = (rcWindow.right - rcWindow.left) - rcClient.right;
			ptDiff.y = (rcWindow.bottom - rcWindow.top) - rcClient.bottom;
			MoveWindow(mhWnd, rcWindow.left, rcWindow.top, mSize.x + ptDiff.x, mSize.y + ptDiff.y, true);*/
			// --

			if (mContext)
				mContext.resize(mSize.x, mSize.y);
		}
		Vector2s32	size() {return mSize;}

		void	setFullScreen(bool fullScreen) {mFullScreen = fullScreen;}
		bool	fullScreen() {return mFullScreen;}

		Vector2s32	screenResolution() const
		{
/*			RECT	rc;
			GetWindowRect(GetDesktopWindow(), &rc);
			return Vector2s32(rc.right - rc.left, rc.bottom - rc.top);*/
			return Vector2s32(0, 0);
		}

		//==========================================================================
		//==========================================================================

	private:
		void	onPaint()
		{
			Renderer.startFrame();

			if (mRootItem)
				mRootItem.paint(false);

			if (mContext)
				mContext.swapBuffers();
		}

		void	onMouseEvent(MouseEvent mouseEvent)
		{
			if (mRootItem)
			{
				mRootItem.mouseEvent(mouseEvent);
			}
		}

		DMLEngine	mScriptContext;

		static int	mWindowsCounter = 0;
		int			mWindowId;

		xcb_window_t		mWindow;
		GLXWindow 			mGLXWindow;
		string				mWindowName = "";
		GraphicItem			mRootItem;
		Vector2s32			mPosition;
		Vector2s32			mSize = Vector2s32(640, 480);
		bool				mFullScreen = false;

		OpenGLContext		mContext;

		// TODO move to OpenGLContext module
		GLXContext	context;
	}
}