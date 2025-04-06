package;

import flixel.FlxState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import haxe.Json;
import sinlib.utilities.Application;
import sinlib.utilities.TryCatch;
import sys.io.File;
import tools.FileDialogHandler;

using StringTools;

class PlayState extends FlxState
{
	var watermark:FlxText = new FlxText(10, 10, 0, '', 16);

	var ui_container:FlxUITabMenu;
	final ui_container_tabs = [{name: 'Data', label: 'Data'}];

	override public function create():Void
	{
		watermark.text = 'FCCT v${Application.VERSION}';
		watermark.alignment = LEFT;
		add(watermark);

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
		container_group.name = 'Data';

		var loadOGJsonButton:FlxButton = new FlxButton(10, 10, "Load chart you would like to convert", function()
		{
			loadChart();
		});

		container_group.add(loadOGJsonButton);
		ui_container.addGroup(container_group);
	}
	var fileDialog:FileDialogHandler = new FileDialogHandler();

	public function loadChart():Void
	{
		fileDialog.open(function()
		{
			TryCatch.tryCatch(() ->
			{
				var filePath:String = fileDialog.path.replace('\\', '/');
				// trace(filePath);
				var chartFile:Dynamic = Json.parse(File.getContent(filePath));
				// trace(chartFile);

				if (chartFile == null)
				{
					throw 'Error: File loaded is not a chart file.';
				}

				final chartType:ChartTypes = getChartType(chartFile);
				trace('${chartType} chart');
			}, {
					traceErr: true
			});
		});
	}

	public function getChartType(chartFile:Dynamic):ChartTypes
	{
		final hasGfVersionField:Bool = Reflect.hasField(chartFile, 'gfVersion');

		final hasGeneratedByField:Bool = Reflect.hasField(chartFile, 'generatedBy');
		final hasVersionField:Bool = Reflect.hasField(chartFile, 'version');

		if (hasGfVersionField)
		{
			return ChartTypes.PSYCH;
		}
		else if (hasVersionField && hasGeneratedByField)
		{
			return ChartTypes.VSLICE;
		}
		else
		{
			return ChartTypes.LEGACY;
		}

		return ChartTypes.UNKNOWN;
	}
}

enum abstract ChartTypes(String) from String to String
{
	// Error value
	public var UNKNOWN:String = 'Unknown';

	// Base game
	public var VSLICE:String = 'V-Slice';
	public var LEGACY:String = 'Legacy';

	// Others
	public var PSYCH:String = 'Psych';
	// public var KADE:String = 'Kade'; // How to difference from Legacy?
	// public var MODDING_PLUS:String = 'Modding+'; // How to difference from Legacy?
	// public var PSLICE:String = 'P-Slice'; // How to difference from Psych?
}
