package;

import flixel.FlxState;
import flixel.addons.ui.FlxButtonPlus;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUITabMenu;
import flixel.text.FlxText;
import haxe.Json;
import moonchart.formats.BasicFormat.FormatStringify;
import moonchart.formats.fnf.FNFVSlice;
import moonchart.formats.fnf.legacy.FNFLegacy;
import moonchart.formats.fnf.legacy.FNFPsych;
import sinlib.utilities.Application;
import sinlib.utilities.FileManager;
import sinlib.utilities.TryCatch;
import sys.io.File;
import tools.FileDialogHandler;

using StringTools;

class PlayState extends FlxState
{
	public static var watermark:FlxText;

	var ui_container:FlxUITabMenu;
	final ui_container_tabs = [{name: 'Data', label: 'Data'}];

	public var JSON_TO_CONVERT:Dynamic = null;
	public var JSON_METADATA:Dynamic;

	public var JSON_CHART_PATH:String;
	public var JSON_META_PATH:String;

	public var OLD_CHART_TYPE:ChartTypes = UNKNOWN;
	public var NEW_CHART_TYPE:ChartTypes = VSLICE;

	final CHART_TYPES:Array<ChartTypes> = [VSLICE, LEGACY, PSYCH];

	override public function create():Void
	{
		trace(CHART_TYPES);

		watermark = new FlxText(10, 10, 0, '', 16);
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

	var warningText:FlxText;

	public function addDataTab():Void
	{
		var container_group = new FlxUI(null, ui_container);
		container_group.name = 'Data';

		warningText = new FlxText(ui_offset, ui_container.height - (ui_offset * 4), 0, '', 16);

		var loadOGJsonButton:FlxButtonPlus = new FlxButtonPlus(ui_offset, ui_offset, function()
		{
			openFileDialogueFile(true);
		}, "Load chart you would like to convert", 200);

		var loadMetaDataBtn:FlxButtonPlus = new FlxButtonPlus(loadOGJsonButton.x, loadOGJsonButton.y + loadOGJsonButton.height + ui_offset, function()
		{
			openFileDialogueFile(false, true);
		}, "Load chart metadata (V-Slice only)", 200);

		var newChartType:FlxUIDropDownMenu = new FlxUIDropDownMenu(loadOGJsonButton.x + loadOGJsonButton.width + (ui_offset * 2), loadMetaDataBtn.y * 2,
			FlxUIDropDownMenu.makeStrIdLabelArray(CHART_TYPES, true), function(newType:ChartTypes)
		{
			final thenewtype:ChartTypes = CHART_TYPES[Std.parseInt(newType)];

			NEW_CHART_TYPE = thenewtype;
			trace(NEW_CHART_TYPE);
		});

		var convertButton:FlxButtonPlus = new FlxButtonPlus(loadMetaDataBtn.x, loadMetaDataBtn.y + loadMetaDataBtn.height + ui_offset, function()
		{
			warningText.text = '';

			if (JSON_TO_CONVERT == null)
			{
				warningText.text = 'Missing Chart';
				return;
			}
			else if (OLD_CHART_TYPE == UNKNOWN)
			{
				warningText.text = 'Unconvertable chart';
				return;
			}
			else if (OLD_CHART_TYPE == VSLICE && JSON_METADATA == null)
			{
				warningText.text = 'Missing V-Slice metadata';
				return;
			}
			else if (OLD_CHART_TYPE == NEW_CHART_TYPE)
			{
				warningText.text = 'Same chart type';
				return;
			}
			else if (OLD_CHART_TYPE == VSLICE && NEW_CHART_TYPE == LEGACY)
			{
				warningText.text = 'V-Slice charts are unconvertable to legacy';
				return;
			}

			trace('Transfer ${OLD_CHART_TYPE} chart to ${NEW_CHART_TYPE} chart');
			#if !DISABLE_CRASH_HANDLING
			TryCatch.tryCatch(function()
			{
			#end
				convertChart(JSON_TO_CONVERT, NEW_CHART_TYPE);
			#if !DISABLE_CRASH_HANDLING
			}, {
					traceErr: true,
					errFunc: function()
					{
						warningText.text = 'An error has occored';
					}
			});
			#end
		}, "Convert chart");

		loadOGJsonButton.update(0);
		convertButton.update(0);

		container_group.add(loadOGJsonButton);
		container_group.add(loadMetaDataBtn);
		container_group.add(new FlxText(newChartType.x, newChartType.y - (ui_offset * 2), 0, "New chart type:", 16));
		container_group.add(newChartType);
		container_group.add(convertButton);
		container_group.add(warningText);

		ui_container.addGroup(container_group);
	}

	var fileDialog:FileDialogHandler = new FileDialogHandler();

	public function openFileDialogueFile(chartRelated:Bool = false, metadata:Bool = false):Void
	{
		fileDialog.open(function()
		{
			TryCatch.tryCatch(() ->
			{
				loadFile(chartRelated, metadata);
			}, {
					traceErr: true
			});
		});
	}

	public function loadFile(chartRelated:Bool = false, metadata:Bool = false):Dynamic
	{
		var filePath:String = fileDialog.path.replace('\\', '/');
		// trace(filePath);
		var chartFile:Dynamic = Json.parse(File.getContent(filePath));
		// trace(chartFile);

		if (chartFile == null)
		{
			throw 'Error: File loaded is not a ${(chartRelated ? 'chart' : 'metadata')} file.';
		}

		if (chartRelated)
		{
			JSON_CHART_PATH = filePath;
			JSON_TO_CONVERT = chartFile;

			OLD_CHART_TYPE = getChartType(chartFile);
			trace('${OLD_CHART_TYPE} chart');
		}

		if (metadata)
		{
			if (!Reflect.hasField(chartFile, 'playData'))
			{
				return null;
			}

			JSON_META_PATH = filePath;
			JSON_METADATA = chartFile;
		}

		return chartFile;
	}

	public function getChartType(chartFile:Dynamic):ChartTypes
	{
		final hasSongField:Bool = Reflect.hasField(chartFile, 'song');

		final hasSpeedField:Bool = Reflect.hasField(chartFile.song, 'speed');
		final hasGfVersionField:Bool = Reflect.hasField(chartFile.song, 'gfVersion');

		final hasGeneratedByField:Bool = Reflect.hasField(chartFile, 'generatedBy');
		final hasVersionField:Bool = Reflect.hasField(chartFile, 'version');
		final hasScrollSpeedField:Bool = Reflect.hasField(chartFile, 'scrollSpeed');

		if (hasGfVersionField && hasSpeedField)
		{
			return ChartTypes.PSYCH;
		}
		else if (hasVersionField && hasGeneratedByField && hasScrollSpeedField)
		{
			JSON_METADATA = null;
			return ChartTypes.VSLICE;
		}
		else if (hasSongField)
		{
			return ChartTypes.LEGACY;
		}

		return ChartTypes.UNKNOWN;
	}

	public function convertChart(Json:Dynamic, newFormat:ChartTypes):Void
	{
		var curChartType:ChartTypes = getChartType(Json);

		final splitPath:Array<String> = JSON_CHART_PATH.split('/');
		var newFileName:String = splitPath[splitPath.length - 1].split('.')[0];

		newFileName.replace('-chart', '');

		newFileName.replace('-easy', '');
		newFileName.replace('-normal', '');
		newFileName.replace('-hard', '');
		newFileName.replace('-erect', '');
		newFileName.replace('-nightmare', '');

		trace(JSON_CHART_PATH);
		trace(newFileName);

		switch (newFormat)
		{
			case VSLICE:
				var newChart:FNFVSlice = new FNFVSlice();

				var genBy:String = '${newChart.getGeneratedBy()} - ${curChartType} to VSlice';

				if (curChartType == LEGACY)
				{
					var oldChart:FNFLegacy = new FNFLegacy();
					oldChart.fromFile(JSON_CHART_PATH);
					newChart.fromFormat(oldChart);
				}
				else if (curChartType == PSYCH)
				{
					var oldChart:FNFPsych = new FNFPsych();
					oldChart.fromFile(JSON_CHART_PATH);
					newChart.fromFormat(oldChart);
				}
				newChart.updateGeneratedBy(genBy);
				newChart.formatting = '\t';

				var vsliceChart:Dynamic = newChart.stringify();
				var chart:String = vsliceChart.data;
				var meta:String = vsliceChart.meta;

				fileDialog.save('${newFileName}-chart.json', chart, function()
				{
					fileDialog.save('${newFileName}-metadata.json', meta);
				});

			case LEGACY:
				var newChart:FNFLegacy;
				newChart = new FNFLegacy();

				if (curChartType == VSLICE)
				{
					var oldChart:FNFVSlice = new FNFVSlice(JSON_TO_CONVERT, JSON_METADATA).fromFile(JSON_CHART_PATH);

					newChart.fromFormat(oldChart);
				}
				else if (curChartType == PSYCH)
				{
					var oldChart:FNFPsych = new FNFPsych();
					oldChart.fromFile(JSON_CHART_PATH);
					newChart.fromFormat(oldChart);
				}
				newChart.formatting = '\t';

				var finalChart:FormatStringify = newChart.stringify();

				fileDialog.save('${newFileName}.json', Std.string(finalChart.data));

			case PSYCH:
				var newChart:FNFPsych;

			case UNKNOWN:
				return;
		}
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
