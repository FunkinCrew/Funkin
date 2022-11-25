package funkin.ui.debug.charting;

import flixel.util.FlxTimer;
import flixel.FlxSprite;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.VBox;
import haxe.ui.components.Image;

class ChartEditorDialogHandler
{
	static final CHART_EDITOR_DIALOG_ABOUT_LAYOUT = Paths.ui('chart-editor/dialogs/about');
	static final CHART_EDITOR_DIALOG_SPLASH_LAYOUT = Paths.ui('chart-editor/dialogs/splash');
	static final CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT = Paths.ui('chart-editor/dialogs/user-guide');

	/**
	 * 
	 */
	public static inline function openAboutDialog(state:ChartEditorState):Void
	{
		openDialog(state, CHART_EDITOR_DIALOG_ABOUT_LAYOUT, true, true);
	}

	/**
	 * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
	 */
	public static function openSplashDialog(state:ChartEditorState, closable:Bool = true):Void
	{
		var dialog:Dialog = openDialog(state, CHART_EDITOR_DIALOG_SPLASH_LAYOUT, true, closable);

		// TODO: Add callbacks to the dialog buttons

		// Switch the graphic for frames.
		var bfSpritePlaceholder:Image = dialog.findComponent('bfSprite', Image);

		// TODO: Replace this bullshit with a custom HaxeUI component that loads the sprite from the game's assets.

		if (bfSpritePlaceholder != null)
		{
			var bfSprite:FlxSprite = new FlxSprite(0, 0);

			bfSprite.visible = false;

			var frames = Paths.getSparrowAtlas(bfSpritePlaceholder.resource);
			bfSprite.frames = frames;

			bfSprite.animation.addByPrefix('idle', 'Boyfriend DJ0', 24, true);
			bfSprite.animation.play('idle');

			bfSpritePlaceholder.rootComponent.add(bfSprite);
			bfSpritePlaceholder.visible = false;

			new FlxTimer().start(0.10, (_timer:FlxTimer) ->
			{
				bfSprite.x = bfSpritePlaceholder.screenLeft;
				bfSprite.y = bfSpritePlaceholder.screenTop;
				bfSprite.setGraphicSize(Std.int(bfSpritePlaceholder.width), Std.int(bfSpritePlaceholder.height));
				bfSprite.visible = true;
			});
		}
	}

	/**
	 * Builds and opens a dialog displaying the user guide, providing guidance and help on how to use the chart editor.
	 */
	public static inline function openUserGuideDialog(state:ChartEditorState):Void
	{
		openDialog(state, CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT, true, true);
	}

	/**
	 * Builds and opens a dialog from a given layout path.
	 * @param modal Makes the background uninteractable while the dialog is open.
	 * @param closable Hides the close button on the dialog, preventing it from being closed unless the user interacts with the dialog.
	 */
	static function openDialog(state:ChartEditorState, key:String, modal:Bool = true, closable:Bool = true):Dialog
	{
		var dialog:Dialog = cast state.buildComponent(key);
		dialog.destroyOnClose = true;
		dialog.closable = closable;
		dialog.showDialog(modal);

		return dialog;
	}
}
