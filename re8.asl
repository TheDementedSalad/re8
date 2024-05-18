/*
--------------------------------------
	Resident Evil Village
	Load Remover & Auto Splitter
	
	Official timing method for RE8 speedruns for PC.
	https://www.speedrun.com/re8
	
	Scipt & offsets pre WW_1.5 by CursedToast 05.26.2021
	SoR script & offsets post WW_1.5 by TheDementedSalad 01/12/2022
	Last updated 18 April 2024
	Maintained & Revamped by TheDementedSalad
--------------------------------------
*/

state("re8"){}


startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/RE8.Settings.xml");
	
	// Asks user to change to game time if LiveSplit is currently set to Real Time.
		if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show (
            "This game uses In Game Time as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Resident Evil Village",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );

        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }
}

init
{
	IntPtr EventSystemApp = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 85 c9 41 bf");
	IntPtr EnvSceneManager = vars.Helper.ScanRel(3, "48 39 35 ?? ?? ?? ?? 8b c6 48 0f 45 05 ?? ?? ?? ?? 48 85 c0 75");
	IntPtr SceneTransitionManager = vars.Helper.ScanRel(3, "4c 8b 0d ?? ?? ?? ?? 48 8b fa 4c 8b 15");
	IntPtr FadeManager = vars.Helper.ScanRel(3, "48 39 35 ?? ?? ?? ?? 4c 8b c3");
	IntPtr InventoryManager = vars.Helper.ScanRel(3, "48 39 05 ?? ?? ?? ?? 48 0f 45 05 ?? ?? ?? ?? 48 85 c0 74 ?? 48 8b 40");
	IntPtr Paused = vars.Helper.ScanRel(3, "48 8b 2d ?? ?? ?? ?? 48 85 c0 75 ?? 45 33 c0 8d 56");
	IntPtr Cutscene = vars.Helper.ScanRel(3, "48 8b 0d ?? ?? ?? ?? 84 d2 48 8d 54 24");
	
	vars.Helper["EventName"] = vars.Helper.MakeString(EventSystemApp, 0x58, 0x68, 0x10, 0x20, 0x30, 0x14);
	vars.Helper["EventName"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["MapID"] = vars.Helper.MakeString(EnvSceneManager, 0x180, 0x248, 0x28, 0x14);
	vars.Helper["View"] = vars.Helper.MakeString(SceneTransitionManager, 0x58, 0x14);
	vars.Helper["ExecuteProgressValue"] = vars.Helper.Make<bool>(SceneTransitionManager, 0xE1);
	vars.Helper["FadeProgress"] = vars.Helper.Make<byte>(FadeManager, 0x60);
	vars.Helper["NewItem"] = vars.Helper.Make<uint>(InventoryManager, 0x60, 0x18, 0x10, 0x20, 0x58, 0x3C);
	vars.Helper["isPaused"] = vars.Helper.Make<bool>(Paused, 0x48);
	vars.Helper["isCutscene"] = vars.Helper.Make<byte>(Cutscene, 0x10);
	
	if (EventSystemApp == IntPtr.Zero || EnvSceneManager == IntPtr.Zero || SceneTransitionManager == IntPtr.Zero || FadeManager == IntPtr.Zero || InventoryManager == IntPtr.Zero || Paused == IntPtr.Zero || Cutscene == IntPtr.Zero)
    {
        const string Msg = "Not all required addresses could be found by scanning.";
        throw new Exception(Msg);
    }
	
	vars.completedSplits = new HashSet<string>();
}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();
}

onStart
{
	vars.completedSplits.Clear();
	timer.IsGameTimePaused = true;
}

start
{
	if(settings["NoInt"]){
		if(current.MapID == "st10_039_CentralChurch_Out" && current.FadeProgress == 4){
			return true;
		}
	}
	
	if(current.EventName != "c10e001_00" && old.EventName == "c10e001_00" || current.EventName != "c101e020_00" && old.EventName == "c101e020_00"){
		return true;
	}
}

split
{
	string setting = "";
	
	if(current.MapID != old.MapID){
		setting = "Map_" + current.MapID;
	}
	
	if(current.MapID == "st15_074_ScrapArea_In5B" && old.MapID == "st15_010_Passage_In1B"){
		setting = "Map_propellerOne";
	}
	
	if(current.MapID == "st15_072_HallArea_In5B" && old.MapID == "st15_042_Passage7_In3B"){
		setting = "Map_propellerTwo";
	}
	
	if(current.MapID == "st15_018_ControlRoom_In1B" && old.MapID == "st15_022_PropellerManFinal_In1B"){
		setting = "Map_controlRoom";
	}
	
	if(current.NewItem != old.NewItem){
		setting = "Item_" + current.NewItem;
	}
	
	if(current.EventName != old.EventName && !string.IsNullOrEmpty(current.EventName)){
		setting = "Event_" + current.EventName;
	}
	
	if(current.EventName == "c21e160_02" || current.EventName == "c21e160_00" || current.EventName == "c21e160_01" || current.EventName == "c21e160_03"){
		setting = "Event_arrowKnee";
	}
	
	if(current.EventName == "c31e000_00" || current.EventName == "c31e100_04"){
		setting = "Event_chrisStart";
	}
	
	// Debug. Comment out before release.
    if (!string.IsNullOrEmpty(setting))
    vars.Log(setting);

	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)){
		return true;
	}
}

isLoading
{
	return current.isCutscene == 15 || current.isPaused || current.ExecuteProgressValue || current.FadeProgress == 3 || current.View == "MainMenu" || current.View == "DLCRoot_GE/DLC05/DLC05_2/Chapter10MainMenu";
}

reset
{
	return current.View == "MainMenu" || current.View == "DLCRoot_GE/DLC05/DLC05_2/Chapter10MainMenu";
}
