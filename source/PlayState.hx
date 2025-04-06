package;

import flixel.FlxState;
import flixel.addons.ui.FlxButtonPlus;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUITabMenu;
import flixel.text.FlxText;
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

	public var JSON_TO_CONVERT:Dynamic;

	public var OLD_CHART_TYPE:ChartTypes = UNKNOWN;
	public var NEW_CHART_TYPE:ChartTypes = VSLICE;

	final CHART_TYPES:Array<ChartTypes> = [VSLICE, LEGACY, PSYCH];

	override public function create():Void
	{
		trace(CHART_TYPES);

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

	final ui_offset:Float = 16;

	public function addDataTab():Void
	{
		var container_group = new FlxUI(null, ui_container);
		container_group.name = 'Data';

		var loadOGJsonButton:FlxButtonPlus = new FlxButtonPlus(ui_offset, ui_offset, function()
		{
			loadChart();
		}, "Load chart you would like to convert", 200);

		var newChartType:FlxUIDropDownMenu = new FlxUIDropDownMenu(loadOGJsonButton.x + loadOGJsonButton.width + ui_offset, loadOGJsonButton.y,
			FlxUIDropDownMenu.makeStrIdLabelArray(CHART_TYPES, true), function(newType:ChartTypes)
		{
			final thenewtype:ChartTypes = CHART_TYPES[Std.parseInt(newType)];

			NEW_CHART_TYPE = thenewtype;
			trace(NEW_CHART_TYPE);
		});

		var convertButton:FlxButtonPlus = new FlxButtonPlus(loadOGJsonButton.x, loadOGJsonButton.y + loadOGJsonButton.height + ui_offset, function()
		{
			trace('Transfer ${OLD_CHART_TYPE} chart to ${NEW_CHART_TYPE} chart');
		}, "Convert chart");

		loadOGJsonButton.update(0);
		convertButton.update(0);

		container_group.add(loadOGJsonButton);
		container_group.add(newChartType);
		container_group.add(convertButton);
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

				JSON_TO_CONVERT = chartFile;

				OLD_CHART_TYPE = getChartType(chartFile);
				trace('${OLD_CHART_TYPE} chart');
			}, {
					traceErr: true
			});
		});
	}

	public function getChartType(chartFile:Dynamic):ChartTypes
	{
		final hasSongField:Bool = Reflect.hasField(chartFile, 'song');

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
		else if (hasSongField)
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
