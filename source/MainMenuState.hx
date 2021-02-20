package;

import NGio;
import flixel.ui.FlxButton;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

import ui.MenuItemList;
import ui.Prompt;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var menuItems:MainMenuItemList;

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new MainMenuItemList('FNF_main_menu_assets');
		add(menuItems);
		menuItems.onChange.add(onMenuItemChange);
		menuItems.onAcceptPress.add(function(_)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		});
		
		
		var hasPopupBlocker = #if web true #else false #end;
		
		menuItems.enabled = false;// disable for intro
		menuItems.createItem('story mode', function () startExitState(new StoryMenuState()));
		menuItems.createItem('freeplay', function () startExitState(new FreeplayState()));
		// addMenuItem('options', function () startExitState(new OptionMenu()));
		#if CAN_OPEN_LINKS
			menuItems.createItem('donate', selectDonate, hasPopupBlocker);
		#end
		#if newgrounds
			if (NGio.isLoggedIn)
				menuItems.createItem("logout", selectLogout);
			else
				menuItems.createItem("login", selectLogin);
		#end
		
		// center vertically
		var spacing = 160;
		var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
		for (i in 0...menuItems.length)
		{
			var menuItem = menuItems.members[i];
			menuItem.x = FlxG.width / 2;
			menuItem.y = top + spacing * i;
		}

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, "v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		super.create();
	}
	
	override function finishTransIn()
	{
		super.finishTransIn();
		
		menuItems.enabled = true;
		
		#if newgrounds
		if (NGio.savedSessionFailed)
			showSavedSessionFailed();
		#end
	}
	
	function onMenuItemChange(selected:MenuItem)
	{
		camFollow.setPosition(selected.getGraphicMidpoint().x, selected.getGraphicMidpoint().y);
	}
	
	function selectDonate()
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
		#else
		FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
		#end
	}
	
	#if newgrounds
	function selectLogin()
	{
		showNgPrompt(true);
	}
	
	function showSavedSessionFailed()
	{
		showNgPrompt(false);
	}
	
	function showNgPrompt(fromUi:Bool)
	{
		var prompt = createNGPrompt("Talking to server...", None);
		openSubState(prompt);
		function onLoginComplete(result:ConnectionResult)
		{
			switch (result)
			{
				case Success:
				{
					menuItems.resetItem("login", "logout", selectLogout);
					prompt.setText("Login Successful");
					prompt.setButtons(Ok);
					prompt.onYes = prompt.close;
				}
				case Fail(msg):
				{
					trace("Login Error:" + msg);
					prompt.setText("Login failed");
					prompt.setButtons(Ok);
					prompt.onYes = prompt.close;
				}
				case Cancelled:
				{
					if (prompt != null)
					{
						prompt.setText("Login cancelled by user");
						prompt.setButtons(Ok);
						prompt.onYes = prompt.close;
					}
					else
						trace("Login cancelled via prompt");
				}
			}
		}
		
		NGio.login
		(
			function popupLauncher(openPassportUrl)
			{
				var choiceMsg = fromUi
					? #if web "Log in to Newgrounds?" #else null #end // User-input needed to allow popups
					: "Your session has expired.\n Please login again.";
				
				if (choiceMsg != null)
				{
					prompt.setText(choiceMsg);
					prompt.setButtons(Yes_No);
					#if web
					prompt.buttons.getItem("yes").fireInstantly = true;
					#end
					prompt.onYes = function()
					{
						prompt.setText("Connecting..." #if web + "\n(check your popup blocker)" #end);
						prompt.setButtons(None);
						openPassportUrl();
					};
					prompt.onNo = function()
					{
						prompt.close();
						prompt = null;
						NGio.cancelLogin();
					};
				}
				else
				{
					prompt.setText("Connecting...");
					openPassportUrl();
				}
			},
			onLoginComplete
		);
	}
	
	function selectLogout()
	{
		var user = io.newgrounds.NG.core.user.name;
		var prompt = createNGPrompt('Log out of $user?', Yes_No);
		prompt.onYes = function()
		{
			NGio.logout();
			prompt.close();
			menuItems.resetItem("logout", "login", selectLogin);
		};
		prompt.onNo = prompt.close;
		openSubState(prompt);
	}
	
	public function createNGPrompt(text:String, style:ButtonStyle = Yes_No)
	{
		var oldAutoPause = FlxG.autoPause;
		FlxG.autoPause = false;
		menuItems.enabled = false;
		
		var prompt = new Prompt("prompt-ng_login", text, style);
		prompt.closeCallback = function ()
		{
			menuItems.enabled = true;
			FlxG.autoPause = oldAutoPause;
		}
		
		return prompt;
	}
	#end
	
	function startExitState(state:FlxState)
	{
		var duration = 0.4;
		menuItems.forEach(function(item)
		{
			if (menuItems.selectedIndex != item.ID)
			{
				FlxTween.tween(item, {alpha: 0}, duration, { ease: FlxEase.quadOut });
			}
			else
			{
				item.visible = false;
			}
		});
		
		new FlxTimer().start(duration, function(_) FlxG.switchState(state));
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (menuItems.enabled && controls.BACK)
			FlxG.switchState(new TitleState());

		super.update(elapsed);
	}
}


private class MainMenuItemList extends MenuTypedItemList<MainMenuItem>
{
	public var atlas:FlxAtlasFrames;
	
	public function new (atlas)
	{
		super(Vertical);
		
		if (Std.is(atlas, String))
			this.atlas = Paths.getSparrowAtlas(cast atlas);
		else
			this.atlas = cast atlas;
	}
	
	public function createItem(x = 0.0, y = 0.0, name:String, callback, fireInstantly = false)
	{
		var i = length;
		var item = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = i;
		
		return addItem(name, item);
	}
	
	override function destroy()
	{
		super.destroy();
		atlas = null;
	}
}
private class MainMenuItem extends MenuItem
{
	public function new(x = 0.0, y = 0.0, name, atlas, callback)
	{
		super(x, y, name, atlas, callback);
		scrollFactor.set();
	}
	
	override function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		// position by center
		centerOrigin();
		offset.copyFrom(origin);
	}
}