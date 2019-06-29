#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sdktools_functions>

#define	SOUND_MUSIC1			"music/flu/jukebox/re_your_brains.wav"
#define SOUND_MUSIC2			"music/flu/concert/save_me_some_sugar_stereo.wav"
#define	SOUND_MUSIC3			"music/flu/jukebox/portal_still_alive.wav"
#define	SOUND_MUSIC4			"music/flu/jukebox/all_i_want_for_xmas.wav"
#define	SOUND_MUSIC5			"music/flu/concert/midnightride.wav"
#define	SOUND_MUSIC6			"music/flu/concert/onebadman.wav"
#define	SOUND_MUSIC7			"music/flu/jukebox/thesaintswillnevercome.wav"
#define	SOUND_MUSIC8			"music/stmusic/southofhuman.wav"
#define	SOUND_MUSIC9			"music/stmusic/deadeasy.wav"
#define	SOUND_MUSIC10			"music/tank/midnighttank.wav"
#define	SOUND_MUSIC11			"music/tank/onebadtank.wav"
#define	SOUND_MUSIC12			"music/unalive/themonsterswithin.wav"
#define	SOUND_MUSIC13			"music/scavenge/gascanofvictory.wav"
#define	SOUND_MUSIC14			"music/tank/taank.wav"
#define	SOUND_MUSIC15			"hehe13/cxk.mp3"

Handle 	g_hMenuMain;
char	current_sound[128];

public Plugin:myinfo =
{
	name = "播放音乐",
	description = "",
	author = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_music", Sound, ADMFLAG_ROOT, "播放音乐");
	RegAdminCmd("sm_selectmusic", SoundPath, ADMFLAG_ROOT, "选择音乐");
	RegAdminCmd("sm_cache", CacheSound, ADMFLAG_ROOT, "选择音乐");

	g_hMenuMain = CreateMenu(MainMenuHandler);
	AddMenuItem(g_hMenuMain, "0", "停止播放");
	AddMenuItem(g_hMenuMain, "1", "Re: Your Brains");
	AddMenuItem(g_hMenuMain, "2", "Save Me Some Sugar");
	AddMenuItem(g_hMenuMain, "3", "Potral Still Alive");
	AddMenuItem(g_hMenuMain, "4", "All I Want For Chirstmas");
	AddMenuItem(g_hMenuMain, "5", "Midnight Ride");
	AddMenuItem(g_hMenuMain, "6", "One Bad Man");
	AddMenuItem(g_hMenuMain, "7", "The Saints Will Never Come");
	AddMenuItem(g_hMenuMain, "8", "South Of Man");
	AddMenuItem(g_hMenuMain, "9", "Dead Easy");
	AddMenuItem(g_hMenuMain, "10", "Midnight Tank");
	AddMenuItem(g_hMenuMain, "11", "One Bad Tank");
	AddMenuItem(g_hMenuMain, "12", "The Monsters Within");
	AddMenuItem(g_hMenuMain, "13", "Gascan Of Victory");
	AddMenuItem(g_hMenuMain, "14", "Taank");
	AddMenuItem(g_hMenuMain, "15", "CXK");
	SetMenuTitle(g_hMenuMain, "选择音乐");
	SetMenuExitButton(g_hMenuMain, true);
}

public OnMapStart()
{
	PrecacheSound(SOUND_MUSIC1, true);
	PrecacheSound(SOUND_MUSIC2, true);
	PrecacheSound(SOUND_MUSIC3, true);
	PrecacheSound(SOUND_MUSIC4, true);
	PrecacheSound(SOUND_MUSIC5, true);
	PrecacheSound(SOUND_MUSIC6, true);
	PrecacheSound(SOUND_MUSIC7, true);
	PrecacheSound(SOUND_MUSIC8, true);
	PrecacheSound(SOUND_MUSIC9, true);
	PrecacheSound(SOUND_MUSIC10, true);
	PrecacheSound(SOUND_MUSIC11, true);
	PrecacheSound(SOUND_MUSIC12, true);
	PrecacheSound(SOUND_MUSIC13, true);
	PrecacheSound(SOUND_MUSIC14, true);
	PrecacheSound(SOUND_MUSIC15, true);
}

public Action Sound(int client, int args)
{
	DisplayMenu(g_hMenuMain, client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public Action SoundPath(int client, int args)
{
	if (args == 0)
	{
		PrintToChat(client, "请输入参数", client);
		return Plugin_Handled;
	}
	GetCmdArg(1, current_sound, sizeof(current_sound));
	PrintToChat(client, current_sound);
	StopAmbientSound();
	if(!IsSoundPrecached(current_sound)) PrecacheSound(current_sound, true);
	CreateTimer(1.0, PlayAmbientSound);
	return Plugin_Continue;
}

public Action CacheSound(int client, int args)
{
	if (args == 0)
	{
		PrintToChat(client, "请输入参数", client);
		return Plugin_Handled;
	}
	GetCmdArg(1, current_sound, sizeof(current_sound));
	PrintToChat(client, current_sound);
	PrecacheSound(current_sound, true);
	return Plugin_Continue;
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Select )
	{
		StopAmbientSound();	
		if( index == 1 )		current_sound = SOUND_MUSIC1;
		else if( index == 2 )	current_sound = SOUND_MUSIC2;
		else if( index == 3 )	current_sound = SOUND_MUSIC3;
		else if( index == 4 )	current_sound = SOUND_MUSIC4;
		else if( index == 5 )	current_sound = SOUND_MUSIC5;
		else if( index == 6 )	current_sound = SOUND_MUSIC6;
		else if( index == 7 )	current_sound = SOUND_MUSIC7;
		else if( index == 8 )	current_sound = SOUND_MUSIC8;
		else if( index == 9 )	current_sound = SOUND_MUSIC9;
		else if( index == 10)	current_sound = SOUND_MUSIC10;
		else if( index == 11)	current_sound = SOUND_MUSIC11;
		else if( index == 12)	current_sound = SOUND_MUSIC12;
		else if( index == 13)	current_sound = SOUND_MUSIC13;
		else if( index == 14)	current_sound = SOUND_MUSIC14;
		else if( index == 15)	current_sound = SOUND_MUSIC15;
		PrintToChatAll(current_sound);
		if(index > 0){
			if(!IsSoundPrecached(current_sound)) PrecacheSound(current_sound, true);
			CreateTimer(1.0, PlayAmbientSound);
		}
	}
}

StopAmbientSound()
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			StopSound(i, SNDCHAN_AUTO, current_sound);
		}
	}
}

public Action PlayAmbientSound(Handle timer)
{
	EmitSoundToAll(current_sound);
}
