package funkin.ui;

import funkin.ui.Page.PageName;
import flixel.group.FlxGroup;

/**
 * The Codex class is what holds our `Page` objects together. Apologies for the potentially obtuse quirky name.
 * Codex stands for "Collection Of Pages ex"... imagine P is rotated 180 degress now its a d :)
 * I just wanted something not called "PageManager" grr...
 */
class Codex<T:PageName> extends FlxGroup
{
  var pages:Map<T, Page<T>>;

  public var currentName:T;
  public var currentPage(get, never):Page<T>;

  inline function get_currentPage():Page<T>
    return pages[currentName];

  public function new(initPage:T)
  {
    super();
    pages = new Map<T, Page<T>>();
    currentName = initPage;
  }

  public function addPage<P:Page<T>>(name:T, page:P):P
  {
    page.onSwitch.add(switchPage);
    page.codex = this;
    pages[name] = page;
    add(page);
    page.exists = currentName == name;
    return page;
  }

  public function setPage(name:T):Void
  {
    if (pages.exists(currentName))
    {
      currentPage.exists = false;
      currentPage.visible = false;
    }

    currentName = name;

    if (pages.exists(currentName))
    {
      currentPage.exists = true;
      currentPage.visible = true;
    }
  }

  public function switchPage(name:T):Void
  {
    // TODO: Animate this transition?
    setPage(name);
  }
}
