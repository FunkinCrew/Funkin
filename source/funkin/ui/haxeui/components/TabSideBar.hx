package funkin.ui.haxeui.components;

import haxe.ui.Toolkit;
import haxe.ui.containers.SideBar;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.styles.elements.AnimationKeyFrame;
import haxe.ui.styles.elements.AnimationKeyFrames;
import haxe.ui.styles.elements.Directive;

class TabSideBar extends SideBar
{
	var closeButton:Component;

	public function new()
	{
		super();
	}

	inline function getCloseButton()
	{
		if (closeButton == null)
		{
			closeButton = findComponent("closeSideBar", Component);
		}
		return closeButton;
	}

	public override function hide()
	{
		var animation = Toolkit.styleSheet.findAnimation("sideBarRestoreContent");
		var first:AnimationKeyFrame = animation.keyFrames[0];
		var last:AnimationKeyFrame = animation.keyFrames[animation.keyFrames.length - 1];
		var rootComponent = Screen.instance.rootComponents[0];

		first.set(new Directive("left", Value.VDimension(Dimension.PX(rootComponent.left))));
		first.set(new Directive("top", Value.VDimension(Dimension.PX(rootComponent.top))));
		first.set(new Directive("width", Value.VDimension(Dimension.PX(rootComponent.width))));
		first.set(new Directive("height", Value.VDimension(Dimension.PX(rootComponent.height))));

		last.set(new Directive("left", Value.VDimension(Dimension.PX(0))));
		last.set(new Directive("top", Value.VDimension(Dimension.PX(0))));
		last.set(new Directive("width", Value.VDimension(Dimension.PX(Screen.instance.width))));
		last.set(new Directive("height", Value.VDimension(Dimension.PX(Screen.instance.height))));

		for (r in Screen.instance.rootComponents)
		{
			if (r.classes.indexOf("sidebar") == -1)
			{
				r.swapClass("sideBarRestoreContent", "sideBarModifyContent");
				r.onAnimationEnd = function(_)
				{
					r.restorePercentSizes();
					r.onAnimationEnd = null;
					rootComponent.removeClass("sideBarRestoreContent");
				}
			}
		}

		hideSideBar();
	}

	private override function hideSideBar()
	{
		var showSideBarClass = null;
		var hideSideBarClass = null;
		if (position == "left")
		{
			showSideBarClass = "showSideBarLeft";
			hideSideBarClass = "hideSideBarLeft";
		}
		else if (position == "right")
		{
			showSideBarClass = "showSideBarRight";
			hideSideBarClass = "hideSideBarRight";
		}
		else if (position == "top")
		{
			showSideBarClass = "showSideBarTop";
			hideSideBarClass = "hideSideBarTop";
		}
		else if (position == "bottom")
		{
			showSideBarClass = "showSideBarBottom";
			hideSideBarClass = "hideSideBarBottom";
		}

		this.onAnimationEnd = function(_)
		{
			this.removeClass(hideSideBarClass);
			// onHideAnimationEnd();
		}

		this.swapClass(hideSideBarClass, showSideBarClass);

		if (modal == true)
		{
			hideModalOverlay();
		}
	}
}
