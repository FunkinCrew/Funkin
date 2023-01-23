package funkin.ui.haxeui.components;

import flixel.FlxG;
import flixel.util.FlxTimer;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.SideBar;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;

class Notifbar extends SideBar
{
	final NOTIFICATION_DISMISS_TIME = 5.0; // seconds
	var dismissTimer:FlxTimer = null;

	var outerContainer:Box = null;
	var container:VBox = null;
	var message:Label = null;
	var action:Button = null;
	var dismiss:Button = null;

	public function new()
	{
		super();

		buildSidebar();
		buildChildren();
	}

	public function showNotification(message:String, ?actionText:String = null, ?actionCallback:Void->Void = null, ?dismissTime:Float = null)
	{
		if (dismissTimer != null)
			dismissNotification();

		if (dismissTime == null)
			dismissTime = NOTIFICATION_DISMISS_TIME;

		// Message text.
		this.message.text = message;

		// Action
		if (actionText != null)
		{
			this.action.text = actionText;
			this.action.visible = true;
			this.action.disabled = false;
			this.action.onClick = (_) ->
			{
				actionCallback();
			};
		}
		else
		{
			this.action.visible = false;
			this.action.disabled = false;
			this.action.onClick = null;
		}

		this.show();

		// Auto dismiss.
		dismissTimer = new FlxTimer().start(dismissTime, (_:FlxTimer) -> dismissNotification());
	}

	public function dismissNotification()
	{
		if (dismissTimer != null)
		{
			dismissTimer.cancel();
			dismissTimer = null;
		}

		this.hide();
	}

	function buildSidebar():Void
	{
		this.width = 256;
		this.height = 80;

		// border-top: 1px solid #000; border-left: 1px solid #000;
		this.styleString = "border: 1px solid #000; background-color: #3d3f41; padding: 8px; border-top-left-radius: 8px;";

		// float to the right
		this.x = FlxG.width - this.width;

		this.position = "bottom";
		this.method = "float";
	}

	function buildChildren():Void
	{
		outerContainer = cast(buildComponent("assets/data/notifbar.xml"), Box);
		addComponent(outerContainer);

		container = outerContainer.findComponent('notifbarContainer', VBox);
		message = outerContainer.findComponent('notifbarMessage', Label);
		action = outerContainer.findComponent('notifbarAction', Button);
		dismiss = outerContainer.findComponent('notifbarDismiss', Button);

		dismiss.onClick = (_) ->
		{
			dismissNotification();
		};
	}

	function buildComponent(path:String):Component
	{
		return RuntimeComponentBuilder.fromAsset(path);
	}
}
