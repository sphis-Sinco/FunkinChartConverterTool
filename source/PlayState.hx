package;

import flixel.FlxState;
import flixel.addons.ui.FlxUITabMenu;

class PlayState extends FlxState
{
	var container:FlxUITabMenu;
	final container_tabs = [{name: "Data", label: 'Data'}];

	override public function create():Void
	{
		container = new FlxUITabMenu(null, tabs, true);

		container.resize(640, 480);
		container.screenCenter();
		add(container);

		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
