module dquick.system.window;

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

public import dquick.script.dmlEngine;

interface IWindow
{
	bool		create();
	void		destroy();	/// If call on main Window (first instancied) the application will exit
	
	bool		wasCreated() const;

	void			setMainItem(GraphicItem item);
	void			setMainItem(string filePath);
	GraphicItem		mainItem();

	void		setPosition(Vector2s32 position);
	Vector2s32	position();

	void		setSize(Vector2s32 size);
	Vector2s32	size();

	void		setFullScreen(bool fullScreen);	/// It's recommanded to set the size with the screenResolution method before entering in FullScreen mode to avoid scaling
	bool		fullScreen();

	Vector2s32	screenResolution() const;

	void		show();

	// TODO rajouter les flag maximized et minimized, comme ce sont des etats eclusifs, les mettre en enum avec le fullscreen
}

class WindowBase
{
}
