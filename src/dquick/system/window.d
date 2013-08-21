module dquick.system.window;

import dquick.item.declarative_item;
import dquick.maths.vector2s32;

interface IWindow
{
	bool		create();
	void		destroy();	/// If call on main Window (first instancied) the application will exit

	void			setMainItem(DeclarativeItem item);
	void			setMainItem(string filePath);
	DeclarativeItem	mainItem();

	void		setPosition(Vector2s32 position);
	Vector2s32	position();

	void		setSize(Vector2s32 size);
	Vector2s32	size();

	void		setFullScreen(bool fullScreen);	/// It's recommanded to set the size with the screenResolution method before entering in FullScreen mode to avoid scaling
	bool		fullScreen();

	Vector2s32	screenResolution() const;

	// TODO rajouter les flag maximized et minimized, comme ce sont des etats eclusifs, les mettre en enum avec le fullscreen
}
