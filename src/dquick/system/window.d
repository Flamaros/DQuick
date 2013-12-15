module dquick.system.window;

import dquick.system.guiApplication;
import dquick.maths.vector2f32;

public import dquick.script.dmlEngine;
public import dquick.item.declarativeItem;
public import dquick.item.graphicItem;
public import dquick.item.imageItem;
public import dquick.item.textItem;
public import dquick.item.borderImageItem;
public import dquick.item.mouseAreaItem;
public import dquick.item.scrollViewItem;
public import dquick.maths.vector2s32;
public import dquick.renderer3D.openGL.renderer;
public import dquick.events.mouseEvent;

interface IWindow
{
public:
	bool			create();
	
	bool			wasCreated() const;
	bool			isMainWindow() const;

	void			setMainItem(GraphicItem item);	/// Window will take size of this item
	void			setMainItem(string filePath);	/// Window will take size of this item
	GraphicItem		mainItem();
	DMLEngine		dmlEngine();

	void			setPosition(Vector2s32 position);
	Vector2s32		position();

	void			setSize(Vector2s32 size);
	Vector2s32		size();

	void			setFullScreen(bool fullScreen);	/// It's recommanded to set the size with the screenResolution method before entering in FullScreen mode to avoid scaling
	bool			fullScreen();

	Vector2s32		screenResolution() const;

	void			show();

protected:
	void	destroy();	/// If call on main Window (first instancied) the application will exit. This method is only called by the destructor

	// TODO rajouter les flag maximized et minimized, comme ce sont des etats eclusifs, les mettre en enum avec le fullscreen
}

abstract class WindowBase : IWindow
{
public:
	this()
	{
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
		mScriptContext = null;
		destroy();
	}

	void	setMainItem(GraphicItem item)
	{
		mRootItem = item;
		/*
		GraphicItem	graphicItem = cast(GraphicItem)mRootItem;
		if (graphicItem)
		setSize(graphicItem.size);*/
	}

	void	setMainItem(string filePath)
	{
		mScriptContext.executeFile(filePath);

		mRootItem = mScriptContext.rootItem!GraphicItem();
		if (mRootItem is null)
			throw new Exception("There is no root item or it's not a GraphicItem");

		mRootItem.setSize(Vector2f32(size()));
	}

	GraphicItem	mainItem() {return mRootItem;}

	DMLEngine	dmlEngine() {return mScriptContext;}

protected:
	void	destroy()
	{
		if (wasCreated())
		{
			mScriptContext = null;
			if (isMainWindow())
				GuiApplication.instance().quit();
		}
	}

	DMLEngine	mScriptContext;
	GraphicItem	mRootItem;
}
