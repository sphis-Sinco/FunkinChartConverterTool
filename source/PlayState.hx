package;

import flixel.FlxState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;

class PlayState extends FlxState
{
	var ui_container:FlxUITabMenu;
	final ui_container_tabs = [{name: "Data", label: 'Data'}];

	override public function create():Void
	{
		ui_container = new FlxUITabMenu(null, ui_container_tabs, true);

		ui_container.resize(640, 480);
		ui_container.screenCenter();
		ui_container.selected_tab = 0;

		add(ui_container);
		ui_container.scrollFactor.set();

		addDataTab();

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
	public function addDataTab():Void
	{
		var container_group = new FlxUI(null, ui_container);
		container_group.name = "Data";

		ui_container.addGroup(container_group);
	}
}
