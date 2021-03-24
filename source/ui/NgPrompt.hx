package ui;

import NGio;
import ui.Prompt;

class NgPrompt extends Prompt
{
	public function new (text:String, style:ButtonStyle = Yes_No)
	{
		super(text, style);
	}
	
	static public function showLogin()
	{
		return showLoginPrompt(true);
	}
	
	static public function showSavedSessionFailed()
	{
		return showLoginPrompt(false);
	}
	
	static function showLoginPrompt(fromUi:Bool)
	{
		var prompt = new NgPrompt("Talking to server...", None);
		prompt.openCallback = NGio.login.bind
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
			function onLoginComplete(result:ConnectionResult)
			{
				switch (result)
				{
					case Success:
					{
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
		);
		
		return prompt;
	}
	
	static public function showLogout()
	{
		var user = io.newgrounds.NG.core.user.name;
		var prompt = new NgPrompt('Log out of $user?', Yes_No);
		prompt.onYes = function()
		{
			NGio.logout();
			prompt.close();
		};
		prompt.onNo = prompt.close;
		return prompt;
	}
}