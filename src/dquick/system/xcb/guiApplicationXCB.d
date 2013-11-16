module dquick.system.xcb.guiApplicationXCB;

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

	pragma(lib, "X11");
	pragma(lib, "X11-xcb");
	pragma(lib, "xcb");

	import dquick.system.xcb.openglContextXCB;
	import deimos.X11.Xlib;
	import deimos.X11.Xlib_xcb;
	import deimos.XCB.xcb;
	import deimos.XCB.xproto;

	class GuiApplication : IGuiApplication
	{
	public:
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
//			while (!mQuit)
			{
/*				while (PeekMessageA(&msg, null, 0, 0, PM_REMOVE))
				{
					TranslateMessage(&msg);
					DispatchMessageA(&msg);
				}*/

/*				if (!mQuit)
					foreach (Window window; mWindows)
						window.onPaint();*/
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

		static GuiApplication	mInstance;
		static bool				mQuit = false;

		static string		mApplicationDisplayName = "DQuick - Application";
		static string		mApplicationDirectory = ".";
		static bool			mInitialized = false;
//		static Window[HWND]	mWindows;
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
			Display*	display;
			int			default_screen;
			
			/* Open Xlib Display */ 
			display = XOpenDisplay(null);
			if (!display)
			{
				throw new Exception("Can't open display");
				return false;
			}
			
			default_screen = DefaultScreen(display);
			
			/* Get the XCB connection from the display */
			xcb_connection_t *connection = 
				XGetXCBConnection(display);
			if (!connection)
			{
				XCloseDisplay(display);
				throw new Exception("Can't get xcb connection from display");
				return false;
			}
			
			/* Acquire event queue ownership */
			XSetEventQueueOwner(display, XEventQueueOwner.XCBOwnsEventQueue);
			
			/* Find XCB screen */
			xcb_screen_t*			screen = null;
			xcb_screen_iterator_t	screen_iter =xcb_setup_roots_iterator(xcb_get_setup(connection));
			for (int screen_num = default_screen; screen_iter.rem && screen_num > 0; --screen_num, xcb_screen_next(&screen_iter))
			{
			}
			screen = screen_iter.data;
			
			/* Initialize window and OpenGL context, run main loop and deinitialize */  
//			int retval = setup_and_run(display, connection, default_screen, screen);
			
			/* Cleanup */
			XCloseDisplay(display);


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

//		HWND		mhWnd = null;
		string		mWindowName = "";
		GraphicItem	mRootItem;
		Vector2s32	mPosition;
		Vector2s32	mSize = Vector2s32(640, 480);
		bool		mFullScreen = false;

		OpenGLContext	mContext;
	}
}
