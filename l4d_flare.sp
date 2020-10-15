#define PLUGIN_VERSION 		"2.5"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Flare Package
*	Author	:	SilverShot
*	Descrp	:	Creates flares on the ground, attached to survivors, when incapped or upgrade ammo is deployed.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=173258
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.5 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

2.4 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.
	- Removed "colors.inc" dependency.
	- Updated these translation file encodings to UTF-8 (to display all characters correctly): German (de).

2.3.1 (28-Jun-2019)
	- Changed PrecacheParticle method.
	- Delete redundant if statement. Thanks to "BHaType" for reporting.

2.3 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_flare_modes_tog" now supports L4D1.
	- Potentially fixed the plugin from rarely breaking for a round.

2.2.1 (19-Nov-2015)
	- Fix to prevent garbage being passed into SetVariantString, as suggested by "KyleS".

2.2 (21-May-2012)
	- Added German translations - Thanks to "Dont Fear The Reaper".

2.2 (30-Mar-2012)
	- Added Spanish translations - Thanks to "Januto".
	- Added cvar "l4d_flare_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_flare_modes_tog" same as above, but only works for L4D2.
	- Changed the way "l4d_flare_attach_cmd_flags" and "l4d_flare_ground_cmd_flags" validate clients by checking they have one of the flags.
	- Fixed cvar "l4d_flare_ground_light_allow" setting of "2" not removing lights.
	- Small changes and fixes.

2.1 (19-Dec-2011)
	- Fixed flares not loading on changelevel command.
	- Removed more CreateTimer functions. The game itself will remove those entities.

2.0 (02-Dec-2011)
	- Plugin separated and taken from the "Flare and Light Package" plugin.
	- Added Russian translations - Thanks to "disawar1".
	- Added cvar "l4d_flare_attach_time" to control how long attached flares burn.
	- Added cvar "l4d_flare_ground_upgrade" to drop a flare when upgrade ammo is deployed.
	- Added commands: sm_flaresave, sm_flaredel, sm_flareclear, sm_flarewipe, sm_flareset, sm_flarelist.
	- Added "data/l4d_flare.cfg" so admins can save flares to maps using the above commands.
	- Added the following triggers to specify colors with sm_flare: red, green, blue, purple, orange, yellow, white.
	- Increased cvar "l4d_flare_time" from 120 to 600 seconds (10 minutes).
	- Removed cvar "l4d_flare_max_admin". Admins can place all flares instead of being limited.
	- Removed some CreateTimer functions. The game itself will remove flares after "l4d_flare_time".

1.0 (29-Jan-2011)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "honorcode23" for "PrecacheParticle" function
	https://forums.alliedmods.net/showpost.php?p=1314807&postcount=21

*	Thanks to "DJ_WEST" for "[L4D/L4D2] Incapped Grenade (Pipe/Molotov/Vomitjar)" - Used for particle effects
	https://forums.alliedmods.net/showthread.php?p=1127479

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Smoker Cloud Damage" - Modified the IsVisibleTo() for GetGroundAngles()
	https://forums.alliedmods.net/showthread.php?p=866613

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate ground flares
	https://forums.alliedmods.net/showthread.php?t=93716

*	Thanks to "FoxMulder" for "[SNIPPET] Kill Entity in Seconds" - Used to delete flare models
	https://forums.alliedmods.net/showthread.php?t=129135

======================================================================================*/

#pragma semicolon 1

#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Flare\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_flare.cfg"
#define MAX_FLARES			32

#define ATTACH_PILLS		"pills"

#define MODEL_FLARE			"models/props_lighting/light_flares.mdl"
#define PARTICLE_FLARE		"flare_burning"
#define PARTICLE_FUSE		"weapon_pipebomb_fuse"
#define SOUND_CRACKLE		"ambient/fire/fire_small_loop2.wav"


// Cvar Handles
ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hGrndCmdAllow, g_hGrndCmdFlags, g_hGrndFuse, g_hGrndLAlpha, g_hGrndLColor, g_hGrndLight, g_hGrndSAlpha, g_hGrndSColor, g_hGrndSHeight, g_hGrndSmoke, g_hGrndStock, g_hGrndUpgrade, g_hHint, g_hIncapped, g_hIntro, g_hLocked, g_hMaxFlares, g_hSelfCmdAllow, g_hSelfCmdFlags, g_hSelfFuse, g_hSelfLColor, g_hSelfLight, g_hSelfStock, g_hSelfTime, g_hTime;

// Cvar Variables
int g_iGrndCmdAllow, g_iGrndFlags, g_iGrndLAlpha, g_iGrndLight, g_iGrndSAlpha, g_iGrndSHeight, g_iIncapped, g_iMaxFlares, g_iSelfCmdAllow, g_iSelfFlags;
bool g_bCvarAllow, g_bMapStarted, g_bGrndFuse, g_bGrndSmokeOn, g_bGrndStock, g_bGrndUpgrade, g_bHint, g_bLocked, g_bSelfFuse, g_bSelfLight, g_bSelfStock;
char g_sGrndLCols[12], g_sGrndSCols[12], g_sSelfLCols[12];
float g_fIntro, g_fSelfTime, g_fTime;

// Plugin Variables
ConVar g_hCvarMPGameMode;
int g_iPlayerSpawn, g_iRoundStart;
bool g_bBlockAutoFlare[MAXPLAYERS], g_bLeft4Dead2, g_bLoaded, g_bRoundOver;
float g_fFlareAngle;

int g_iFlareTimeout[MAXPLAYERS], g_iAttachedFlare[MAXPLAYERS], g_iFlares[MAX_FLARES][6]; // [0]=[1]/attached client. [1]=prop_dynamic. [2]=point_spotlight. [3]=info_particle Flare. [4]=info_particle Fuse. [5] = env_steam



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Flare Package",
	author = "SilverShot",
	description = "Creates flares on the ground, attached to survivors, when incapped or upgrade ammo is deployed.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=173258"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/flare.phrases.txt");
	if( FileExists(sPath) )
		LoadTranslations("flare.phrases");
	else
		SetFailState("Missing required 'translations/flare.phrases.txt', please download and install.");

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	g_hCvarAllow =			CreateConVar(	"l4d_flare_allow",					"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );

	g_hSelfCmdAllow =		CreateConVar(	"l4d_flare_attach_cmd_allow",		"2",			"0=Disable sm_self command. 1=Incapped only (not admins). 2=Any time.", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hSelfCmdFlags =		CreateConVar(	"l4d_flare_attach_cmd_flags",		"",				"Players with these flags may use the sm_flareme command. (Empty = all).", CVAR_FLAGS );
	g_hSelfFuse =			CreateConVar(	"l4d_flare_attach_fuse",			"1",			"Adds the pipebomb fuse particles to the flare.", CVAR_FLAGS );
	g_hSelfLight =			CreateConVar(	"l4d_flare_attach_light_allow",		"1",			"0=Off, 1=Attaches light_dynamic glow to the player.", CVAR_FLAGS );
	g_hSelfLColor =			CreateConVar(	"l4d_flare_attach_light_colour",	"200 20 15",	"The default light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hSelfStock =			CreateConVar(	"l4d_flare_attach_stock",			"1",			"0=Off, 1=Adds The Sacrifice flare smoke particles.", CVAR_FLAGS );
	g_hSelfTime =			CreateConVar(	"l4d_flare_attach_time",			"10.0", 		"How long the attached flares should burn. 1 flare per player.", CVAR_FLAGS, true, 1.0, true, 60.0 );

	g_hGrndCmdAllow =		CreateConVar(	"l4d_flare_ground_cmd_allow",		"2",			"0=Disable sm_flare command. 1=Incapped only (not admins). 2=Any time.", CVAR_FLAGS );
	g_hGrndCmdFlags =		CreateConVar(	"l4d_flare_ground_cmd_flags",		"",				"Players with these flags may use the sm_flare command. Empty = all.", CVAR_FLAGS );
	g_hGrndFuse =			CreateConVar(	"l4d_flare_ground_fuse",			"0",			"Adds the pipebomb fuse particles to the flare.", CVAR_FLAGS );
	g_hGrndLight =			CreateConVar(	"l4d_flare_ground_light_allow",		"1",			"Light glow around flare. 0=Off, 1=light_dynamic, 2=point_spotlight.", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hGrndLAlpha =			CreateConVar(	"l4d_flare_ground_light_bright",	"255",			"Brightness of the light <10-255>.", CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hGrndLColor =			CreateConVar(	"l4d_flare_ground_light_colour",	"200 20 15",	"The default light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hGrndSmoke =			CreateConVar(	"l4d_flare_ground_smoke_allow",		"0",			"0=Off, 1=Adds extra smoke to the flare (env_steam).", CVAR_FLAGS );
	g_hGrndSAlpha =			CreateConVar(	"l4d_flare_ground_smoke_alpha",		"60",			"Transparency of the extra smoke (10-255).", CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hGrndSColor =			CreateConVar(	"l4d_flare_ground_smoke_colour",	"200 20 15",	"The extra smoke color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hGrndSHeight =		CreateConVar(	"l4d_flare_ground_smoke_height",	"100",			"How tall the extra smoke should rise.", CVAR_FLAGS );
	g_hGrndStock =			CreateConVar(	"l4d_flare_ground_stock",			"1",			"0=Off, 1=Adds The Sacrifice flare smoke particles.", CVAR_FLAGS );
	g_hGrndUpgrade =		CreateConVar(	"l4d_flare_ground_upgrade",			"1",			"0=Off, 1=Drop a flare when incendiary or explosive rounds are deployed.", CVAR_FLAGS );

	g_hIncapped =			CreateConVar(	"l4d_flare_incapped",				"1",			"Display flare when incapped. 0=Off, 1=On ground, 2=Attach to player.", CVAR_FLAGS );
	g_hIntro =				CreateConVar(	"l4d_flare_intro",					"35.0",			"0=Off, Show intro message in chat this many seconds after joining.", CVAR_FLAGS, true, 0.0, true, 120.0);
	g_hLocked =				CreateConVar(	"l4d_flare_lock",					"0",			"0=Let players edit light/smoke colors, 1=Force to cvar specified.", CVAR_FLAGS );
	g_hMaxFlares =			CreateConVar(	"l4d_flare_max_total",				"32",			"Limit the total number of simultaneous flares.", CVAR_FLAGS, true, 1.0, true, float(MAX_FLARES));
	g_hCvarModes =			CreateConVar(	"l4d_flare_modes",					"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_flare_modes_off",				"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_flare_modes_tog",				"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hHint =				CreateConVar(	"l4d_flare_notify",					"1",			"0=Off, 1=Print hints to chat (requires translation file provided).", CVAR_FLAGS );
	g_hTime =				CreateConVar(	"l4d_flare_time",					"10.0", 		"How long the flares should burn, blocks non-admins making flares also.", CVAR_FLAGS, true, 1.0, true, 600.0 );
	CreateConVar(							"l4d_flare_version",				PLUGIN_VERSION, "Flare plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_flare");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hSelfCmdAllow.AddChangeHook(ConVarChanged_Self);
	g_hSelfCmdFlags.AddChangeHook(ConVarChanged_Self);
	g_hSelfFuse.AddChangeHook(ConVarChanged_Self);
	g_hSelfLight.AddChangeHook(ConVarChanged_Self);
	g_hSelfLColor.AddChangeHook(ConVarChanged_Self);
	g_hSelfStock.AddChangeHook(ConVarChanged_Self);
	g_hSelfTime.AddChangeHook(ConVarChanged_Self);
	g_hGrndCmdAllow.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndCmdFlags.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndFuse.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndLight.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndLAlpha.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndLColor.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndSmoke.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndSAlpha.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndSColor.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndSHeight.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndStock.AddChangeHook(ConVarChanged_Grnd);
	g_hGrndUpgrade.AddChangeHook(ConVarChanged_Grnd);
	g_hIncapped.AddChangeHook(ConVarChanged_Main);
	g_hIntro.AddChangeHook(ConVarChanged_Main);
	g_hLocked.AddChangeHook(ConVarChanged_Main);
	g_hMaxFlares.AddChangeHook(ConVarChanged_Main);
	g_hHint.AddChangeHook(ConVarChanged_Main);
	g_hTime.AddChangeHook(ConVarChanged_Main);

	RegConsoleCmd(	"sm_flare",			CmdFlare,							"Create a flare on the ground.");
	RegConsoleCmd(	"sm_flareme",		CmdFlareSelf,						"Create a flare attached to yourself.");
	RegAdminCmd(	"sm_flareclient",	CmdFlareAttach,		ADMFLAG_ROOT,	"Create a flare attached to the specified target. Usage: sm_flareclient <#userid|name>");
	RegAdminCmd(	"sm_flareground",	CmdFlareGround,		ADMFLAG_ROOT,	"Create a flare on the ground next to specified target.");
	RegAdminCmd(	"sm_flaresave",		CmdFlareSave,		ADMFLAG_ROOT, 	"Spawns a flare at your crosshair and saves to config. Usage: sm_flaresave <r> <g> <b>.");
	RegAdminCmd(	"sm_flareset",		CmdFlareSet,		ADMFLAG_ROOT, 	"Usage: sm_flareset <r> <g> <b>. Changes the nearest flare light color and saves to config.");
	RegAdminCmd(	"sm_flarelist",		CmdFlareList,		ADMFLAG_ROOT, 	"Display a list flare positions and the number of flares.");
	RegAdminCmd(	"sm_flaredel",		CmdFlareDelete,		ADMFLAG_ROOT, 	"Removes the flare you are nearest to and deletes from the config if saved.");
	RegAdminCmd(	"sm_flareclear",	CmdFlareClear,		ADMFLAG_ROOT, 	"Removes all fire flares from the current map.");
	RegAdminCmd(	"sm_flarewipe",		CmdFlareWipe,		ADMFLAG_ROOT, 	"Removes all fire flares from the current map and deletes them from the config.");
	RegAdminCmd(	"sm_flarebug",		CmdFlareBug,		ADMFLAG_ROOT, 	"When the plugin fails to work during a round, run this command report the error.");
}

public void OnPluginEnd()
{
	DeleteAllFlares();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_FLARE, true);
	PrecacheSound(SOUND_CRACKLE, true);

	PrecacheParticle(PARTICLE_FLARE);
	PrecacheParticle(PARTICLE_FUSE);
}

public void OnMapEnd()
{
	DeleteAllFlares();
	g_bMapStarted = false;
	g_bLoaded = false;
	g_bRoundOver = true;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}



// ====================================================================================================
//					INTRO
// ====================================================================================================
public void OnClientPostAdminCheck(int client)
{
	g_bBlockAutoFlare[client] = false;
	g_iFlareTimeout[client] = 0;

	if( !IsFlareValidNow() || IsFakeClient(client) )
		return;

	int clientID = GetClientUserId(client);

	// Display intro / welcome message
	if( g_fIntro )
		CreateTimer(g_fIntro, tmrIntro, clientID, TIMER_FLAG_NO_MAPCHANGE);
}

public Action tmrIntro(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Intro", client);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Self(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars(1);
}

public void ConVarChanged_Grnd(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars(2);
}

public void ConVarChanged_Main(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars(3);
}

void GetCvars(int iGroup = 0) // 0 = All, for plugin start
{
	char sTemp[16];

	if( iGroup == 0 || iGroup == 1 ) // Attached flare
	{
		g_iSelfCmdAllow = g_hSelfCmdAllow.IntValue;
		g_hSelfCmdFlags.GetString(sTemp, sizeof(sTemp));
		g_iSelfFlags = ReadFlagString(sTemp);
		g_bSelfFuse = g_hSelfFuse.BoolValue;
		g_bSelfLight = g_hSelfLight.BoolValue;
		g_hSelfLColor.GetString(g_sSelfLCols, sizeof(g_sSelfLCols));
		g_bSelfStock = g_hSelfStock.BoolValue;
		g_fSelfTime = g_hSelfTime.FloatValue;
		if( iGroup ) return;
	}

	if( iGroup == 0 || iGroup == 2 ) // Ground flare
	{
		g_iGrndCmdAllow = g_hGrndCmdAllow.IntValue;
		g_hGrndCmdFlags.GetString(sTemp, sizeof(sTemp));
		g_iGrndFlags = ReadFlagString(sTemp);
		g_bGrndFuse = g_hGrndFuse.BoolValue;
		g_iGrndLight = g_hGrndLight.IntValue;
		g_iGrndLAlpha = g_hGrndLAlpha.IntValue;
		g_hGrndLColor.GetString(g_sGrndLCols, sizeof(g_sGrndLCols));
		g_bGrndSmokeOn = g_hGrndSmoke.BoolValue;
		g_iGrndSAlpha = g_hGrndSAlpha.IntValue;
		g_hGrndSColor.GetString(g_sGrndSCols, sizeof(g_sGrndSCols));
		g_iGrndSHeight = g_hGrndSHeight.IntValue;
		g_bGrndStock = g_hGrndStock.BoolValue;
		g_bGrndUpgrade = g_hGrndUpgrade.BoolValue;
		if( iGroup ) return;
	}

	if( iGroup == 0 || iGroup == 3 ) // Main cvars
	{
		g_iIncapped = g_hIncapped.IntValue;
		g_fIntro = g_hIntro.FloatValue;
		g_bLocked = g_hLocked.BoolValue;
		g_iMaxFlares = g_hMaxFlares.IntValue;
		g_bHint = g_hHint.BoolValue;
		g_fTime = g_hTime.FloatValue;
	}
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadFlares();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		DeleteAllFlares();
		UnhookEvents();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS (mostly for auto flare spawn)
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("player_death",			Event_PlayerDeath);
	HookEvent("player_spawn",			Event_PlayerSpawn);
	HookEvent("player_incapacitated",	Event_PlayerIncapped);
	HookEvent("revive_success",			Event_ReviveSuccess);
	HookEvent("lunge_pounce",			Event_BlockStart);
	HookEvent("pounce_end",				Event_BlockEnd);
	HookEvent("tongue_grab",			Event_BlockStart);
	HookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 == true )
	{
		HookEvent("charger_pummel_start",	Event_BlockStart);
		HookEvent("charger_carry_start",	Event_BlockStart);
		HookEvent("charger_carry_end",		Event_BlockEnd);
		HookEvent("charger_pummel_end",		Event_BlockEnd);
		HookEvent("upgrade_pack_used",		Event_UpgradePack);
	}
}

void UnhookEvents()
{
	UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("player_death",				Event_PlayerDeath);
	UnhookEvent("player_spawn",				Event_PlayerSpawn);
	UnhookEvent("player_incapacitated",		Event_PlayerIncapped);
	UnhookEvent("revive_success",			Event_ReviveSuccess);
	UnhookEvent("lunge_pounce",				Event_BlockStart);
	UnhookEvent("pounce_end",				Event_BlockEnd);
	UnhookEvent("tongue_grab",				Event_BlockStart);
	UnhookEvent("tongue_release",			Event_BlockEnd);

	if( g_bLeft4Dead2 == true )
	{
		UnhookEvent("charger_pummel_start",		Event_BlockStart);
		UnhookEvent("charger_carry_start",		Event_BlockStart);
		UnhookEvent("charger_carry_end",		Event_BlockEnd);
		UnhookEvent("charger_pummel_end",		Event_BlockEnd);
		UnhookEvent("upgrade_pack_used",		Event_UpgradePack);
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bLoaded = false;
	g_bRoundOver = true;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	DeleteAllFlares();

	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
	g_bRoundOver = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;

	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bBlockAutoFlare[client] = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || GetClientTeam(client) != 2 )
		return;

	g_bBlockAutoFlare[client] = true;
}

public void Event_PlayerIncapped(Event event, const char[] name, bool dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	int clientID = event.GetInt("userid");
	int client = GetClientOfUserId(clientID);
	if( IsValidForFlare(client) )
		CreateTimer(2.0, tmrCreateFlare, clientID, TIMER_FLAG_NO_MAPCHANGE); // Auto spawn flare if allowed
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	int client = GetClientOfUserId(event.GetInt("subject"));
	if( IsValidForFlare(client) )
		g_bBlockAutoFlare[client] = false;
}

public void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	int client = GetClientOfUserId(event.GetInt("victim"));
	if( IsValidForFlare(client) )
		g_bBlockAutoFlare[client] = true;
}

public void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	if( !IsFlareValidNow() || !g_iIncapped )
		return;

	int clientID = event.GetInt("victim");
	int client = GetClientOfUserId(clientID);
	if( IsValidForFlare(client) )
	{
		g_bBlockAutoFlare[client] = false;
		CreateTimer(2.0, tmrCreateFlare, clientID, TIMER_FLAG_NO_MAPCHANGE); // Auto spawn flare if allowed
	}
}

public void Event_UpgradePack(Event event, const char[] name, bool dontBroadcast)
{
	if( !IsFlareValidNow() || !g_bGrndUpgrade )
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsValidForFlare(client) )
		CreateFlare(client, g_sGrndLCols, g_sGrndSCols, true);
}

// Call from incap events
public Action tmrCreateFlare(Handle timer, any userid)
{
	// Must be incapped and valid to spawn a flare
	int client = GetClientOfUserId(userid);
	if( !IsFlareValidNow() || !IsValidForFlare(client) || IsValidEntRef(g_iFlareTimeout[client]) || g_bBlockAutoFlare[client] ||
		!IsIncapped(client) || GetFlareIndex(g_iMaxFlares) == -1 )
		return;

	// Auto flare on ground or attached?
	if( g_iIncapped == 1 )
		CreateFlare(client, g_sGrndLCols, g_sGrndSCols, true);
	else if( g_iIncapped == 2 )
		CreateFlare(client, g_sGrndLCols, g_sGrndSCols, false);
	else
		return;

	// Display hint if they are still incapped
	if( g_bHint && g_fTime < 61.0 && !IsFakeClient(client) )
		CreateTimer(g_fTime, tmrFlareHintMsg, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public Action tmrFlareHintMsg(Handle timer, any client)
{
	// Don't affect players who left, maybe a new client
	client = GetClientOfUserId(client);

	if( !IsFlareValidNow() || !IsValidForFlare(client) )
		return;

	// Display hint message if they are still incapped
	if( g_bHint && IsIncapped(client) )
	{
		if( g_iGrndCmdAllow )
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Cmd Ground", client);
		else if( g_iSelfCmdAllow )
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Cmd Attach", client);
	}
}



// ====================================================================================================
//					LOAD FLARES FROM CONFIG
// ====================================================================================================
public Action tmrStart(Handle timer)
{
	LoadFlares();
}

void LoadFlares()
{
	if( g_bLoaded ) return;
	g_bLoaded = true;
	
	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("flares");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many flares to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	char sColorL[12], sTemp[10];
	float vPos[3], vAng[3];
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "angle_%d", i);
		hFile.GetVector(sTemp, vAng);
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);
		Format(sTemp, sizeof(sTemp), "color_%d", i);
		hFile.GetString(sTemp, sColorL, sizeof(sColorL), g_sGrndLCols);

		MakeFlare(vAng, vPos, sColorL, sColorL, true);
	}
}



// ====================================================================================================
//					COMMANDS - SAVE, SET, LIST, GLOW, DELETE, CLEAR, WIPE
// ====================================================================================================
//					sm_flarebug
// ====================================================================================================
public Action CmdFlareBug(int client, int args)
{
	LogError("Error logging: %0.01f% = %d/%d/%d/%d/%d", GetGameTime(), g_bLoaded, g_bCvarAllow, g_iPlayerSpawn, g_iRoundStart, g_bRoundOver);
	ReplyToCommand(client, "[Flare] Please report the problem with the error log in the Flare plugin thread.");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flaresave
// ====================================================================================================
public Action CmdFlareSave(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Flare] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("flares");
	if( !hFile.ImportFromFile(sPath) )
	{
		CPrintToChat(client, "%sError: Cannot read the flare config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		CPrintToChat(client, "%sError: Failed to add map to flare spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many flares are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_FLARES )
	{
		CPrintToChat(client, "%sError: Cannot add anymore flares. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_FLARES);
		delete hFile;
		return Plugin_Handled;
	}

	// Set player position as flare spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos) )
	{
		CPrintToChat(client, "%sCannot place flare, please try again.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Trace from target origin and get ground position/angles for placement
	GetGroundAngles(vPos, vAng);

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[12];
	Format(sTemp, sizeof(sTemp), "angle_%d", iCount);
	hFile.SetVector(sTemp, vAng);
	Format(sTemp, sizeof(sTemp), "origin_%d", iCount);
	hFile.SetVector(sTemp, vPos);

	char sColor[12];

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( strcmp(sTemp, "red", false) == 0 )				Format(sColor, sizeof(sColor), "255 0 0");
		else if( strcmp(sTemp, "green", false) == 0 )		Format(sColor, sizeof(sColor), "0 255 0");
		else if( strcmp(sTemp, "blue", false) == 0 )		Format(sColor, sizeof(sColor), "0 0 255");
		else if( strcmp(sTemp, "purple", false) == 0 )		Format(sColor, sizeof(sColor), "100 0 150");
		else if( strcmp(sTemp, "orange", false) == 0 )		Format(sColor, sizeof(sColor), "255 155 0");
		else if( strcmp(sTemp, "yellow", false) == 0 )		Format(sColor, sizeof(sColor), "255 255 0");
		else if( strcmp(sTemp, "white", false) == 0 )		Format(sColor, sizeof(sColor), "-1 -1 -1");
		else
			strcopy(sColor, sizeof(sColor), g_sGrndLCols);
	}
	else if( args == 3 )
	{
		char sRed[4], sGreen[4], sBlue[4];
		GetCmdArg(1, sRed, sizeof(sRed));
		GetCmdArg(2, sGreen, sizeof(sGreen));
		GetCmdArg(3, sBlue, sizeof(sBlue));
		Format(sColor,sizeof(sColor), "%d %d %d", StringToInt(sRed), StringToInt(sGreen), StringToInt(sBlue));
	}
	else
	{
		strcopy(sColor, sizeof(sColor), g_sGrndLCols);
	}

	Format(sTemp, sizeof(sTemp), "color_%d", iCount);
	hFile.SetString(sTemp, sColor);

	// Save cfg
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	// Create flare
	MakeFlare(vAng, vPos, sColor, sColor, true);
	CPrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_FLARES, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flareset
// ====================================================================================================
public Action CmdFlareSet(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Flare] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args != 3 )
	{
		ReplyToCommand(client, "[Flare] You must specify 3 RGB values, EG: 'sm_flareset 0 0 255'");
		return Plugin_Handled;
	}

	int entity; int ent; int index = -1; float vDistance; float vDistanceLast = 250.0;
	float vPos[3], vPos2[3];
	GetClientAbsOrigin(client, vPos2);

	for( int i = 0; i < MAX_FLARES; i++ )
	{
		ent = g_iFlares[i][2];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
			vDistance = GetVectorDistance(vPos, vPos2);
			if( vDistance < vDistanceLast )
			{
				vDistanceLast = vDistance;
				entity = ent;
				index = i;
			}
		}
	}

	if( index == -1 )
	{
		CPrintToChat(client, "%sCannot find a flare nearby to edit!", CHAT_TAG);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		CPrintToChat(client, "%sError: Cannot find the flare config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("flares");
	if( !hFile.ImportFromFile(sPath) )
	{
		CPrintToChat(client, "%sError: Cannot read the flare config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sTemp[64];
	GetCurrentMap(sTemp, sizeof(sTemp));
	if( !hFile.JumpToKey(sTemp, true) )
	{
		CPrintToChat(client, "%sError: Cannot find the current map in the config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	Format(sTemp, sizeof(sTemp), "origin_%d", index+1);
	hFile.SetVector(sTemp, vPos);

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos2);

	if( GetVectorDistance(vPos, vPos2) > 1.0 )
	{
		CPrintToChat(client, "%sError: Could not match the origins from the config, try re-loading the plugin.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	char sColor[12];
	char sRed[4], sGreen[4], sBlue[4];
	GetCmdArg(1, sRed, sizeof(sRed));
	GetCmdArg(2, sGreen, sizeof(sGreen));
	GetCmdArg(3, sBlue, sizeof(sBlue));
	Format(sColor,sizeof(sColor), "%s %s %s", sRed, sGreen, sBlue);

	int color;
	color = StringToInt(sRed);
	color += 256 * StringToInt(sGreen);
	color += 65536 * StringToInt(sBlue);
	SetEntProp(entity, Prop_Send, "m_clrRender", color);

	Format(sTemp, sizeof(sTemp), "color_%d", index+1);
	hFile.SetString(sTemp, sColor);

	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	CPrintToChat(client, "%sSaved new color to the config.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flarelist
// ====================================================================================================
public Action CmdFlareList(int client, int args)
{
	float vPos[3];
	int i, ent, count;

	for( i = 0; i < MAX_FLARES; i++ )
	{
		ent = g_iFlares[i][1];

		if( IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Flare] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Flare] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flareglow
// ====================================================================================================
public Action CmdFlareGlow(int client, int args)
{
	int i, ent;
	static bool glow;
	glow = !glow;

	for( i = 0; i < MAX_FLARES; i++ )
	{
		ent = g_iFlares[i][1];

		if( IsValidEntRef(ent) )
		{
			if( glow )
				AcceptEntityInput(ent, "StartGlowing");
			else
				AcceptEntityInput(ent, "StopGlowing");
		}
	}

	CPrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flaredel
// ====================================================================================================
public Action CmdFlareDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Flare] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int ent; int index = -1; float vDistance; float vDistanceLast = 250.0;
	float vEntPos[3], vPos[3], vAng[3];
	GetClientAbsOrigin(client, vAng);

	for( int i = 0; i < MAX_FLARES; i++ )
	{
		ent = g_iFlares[i][1];
		if( IsValidEntRef(ent) )
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
			vDistance = GetVectorDistance(vPos, vAng);
			if( vDistance < vDistanceLast )
			{
				vDistanceLast = vDistance;
				vEntPos = vPos;
				index = i;
			}
		}
	}

	if( index == -1 )
	{
		CPrintToChat(client, "%sCannot find a flare nearby to edit!", CHAT_TAG);
		return Plugin_Handled;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the flare config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("flares");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the flare config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the flare config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many flares
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[10], sColor[12];

	// Move the other entries down
	for( int i = 1; i <= iCount; i++ )
	{
		Format(sTemp, sizeof(sTemp), "origin_%d", i);
		hFile.GetVector(sTemp, vPos);

		if( !bMove )
		{
			if( GetVectorDistance(vPos, vEntPos) <= 1.0 )
			{
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "angle_%d", i);
				hFile.DeleteKey(sTemp);
				Format(sTemp, sizeof(sTemp), "color_%d", i);
				hFile.DeleteKey(sTemp);

				DeleteFlare(index);
				bMove = true;
			}
			else if( i == iCount ) // No flares... exit
			{
				PrintToChat(client, "%sWarning: Cannot find the flare inside the config.", CHAT_TAG);
				delete hFile;
				return Plugin_Handled;
			}
		}
		else
		{
			// Delete above key
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "angle_%d", i);
			hFile.GetVector(sTemp, vAng);
			hFile.DeleteKey(sTemp);
			Format(sTemp, sizeof(sTemp), "color_%d", i);
			hFile.GetString(sTemp, sColor, sizeof(sColor));
			hFile.DeleteKey(sTemp);

			// Save data to previous id
			Format(sTemp, sizeof(sTemp), "angle_%d", i-1);
			hFile.SetVector(sTemp, vAng);
			Format(sTemp, sizeof(sTemp), "origin_%d", i-1);
			hFile.SetVector(sTemp, vPos);
			Format(sTemp, sizeof(sTemp), "color_%d", i-1);
			if( sColor[0] )
			{
				Format(sTemp, sizeof(sTemp), "color_%d", i-1);
				hFile.SetString(sTemp, sColor);
			}
		}
	}

	iCount--;
	hFile.SetNum("num", iCount);

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	CPrintToChat(client, "%s(\x05%d/%d\x01) - Flare removed from config.", CHAT_TAG, iCount, MAX_FLARES);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flareclear
// ====================================================================================================
public Action CmdFlareClear(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	DeleteAllFlares();
	CPrintToChat(client, "%sAll flares removed from the map.", CHAT_TAG);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_flarewipe
// ====================================================================================================
public Action CmdFlareWipe(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Flare] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		CPrintToChat(client, "%sError: Cannot find the flare config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("flares");
	if( !hFile.ImportFromFile(sPath) )
	{
		CPrintToChat(client, "%sError: Cannot load the flare config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		CPrintToChat(client, "%sError: Current map not in the flare config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	DeleteAllFlares();
	CPrintToChat(client, "%s(0/%d) - All flares removed from config, add new flares with \x05sm_flaresave\x01.", CHAT_TAG, MAX_FLARES);
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - sm_flareclient / sm_flareground
// ====================================================================================================
public Action CmdFlareAttach(int client, int args)
{
	if( args == 0 ) return Plugin_Handled;

	char sArg[32], target_name[MAX_TARGET_LENGTH];
	GetCmdArg(1, sArg, sizeof(sArg));

	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		sArg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE, /* Only allow alive players */
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArgString(sArg, sizeof(sArg));
	for( int i = 0; i < target_count; i++ )
	{
		if( IsValidForFlare(target_list[i]) )
			CommandForceFlare(client, target_list[i], args, sArg, false);
	}

	return Plugin_Handled;
}

public Action CmdFlareGround(int client, int args)
{
	if( args == 0 ) return Plugin_Handled;

	char sArg[32], target_name[MAX_TARGET_LENGTH];
	GetCmdArg(1, sArg, sizeof(sArg));

	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		sArg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE, /* Only allow alive players */
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	GetCmdArgString(sArg, sizeof(sArg));
	for( int i = 0; i < target_count; i++ )
	{
		if( IsValidForFlare(target_list[i]) )
			CommandForceFlare(client, target_list[i], args, sArg, true);
	}

	return Plugin_Handled;
}

void CommandForceFlare(int client, int target, int args, const char[] sArg, bool bGroundFlare)
{
	// Must be valid time to spawn flare
	if( !IsFlareValidNow() )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Invalid Now", client);
		return;
	}

	// Must be valid target
	if( target == -1 || !IsValidForFlare(target) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Invalid Target", client);
		return;
	}

	// Wrong number of arguments
	if( args != 1 && args != 2 && args != 4 && args != 7 )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Invalid Args", client);
		return;
	}

	// Do not spawn flares when maximum reached
	if( GetFlareIndex(g_iMaxFlares) == -1 )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Max", client);
		return;
	}

	// Stop admins spawning more than 1 attached flare on targets
	if( !bGroundFlare && IsValidEntRef(g_iAttachedFlare[target]) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Wait", client);
		return;
	}

	// Passed the checks, lets create the flare. Args specify the light/extra smoke (env_steam) color
	char sTempL[12], sTempS[12], sBuffers[8][8];

	if( args == 2 )
	{
		ExplodeString(sArg, " ", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
		strcopy(sTempL, sizeof(sTempL), sBuffers[1]);

		if( strcmp(sTempL, "red", false) == 0 )				Format(sTempL, sizeof(sTempL), "255 0 0");
		else if( strcmp(sTempL, "green", false) == 0 )		Format(sTempL, sizeof(sTempL), "0 255 0");
		else if( strcmp(sTempL, "blue", false) == 0 )		Format(sTempL, sizeof(sTempL), "0 0 255");
		else if( strcmp(sTempL, "purple", false) == 0 )		Format(sTempL, sizeof(sTempL), "155 0 255");
		else if( strcmp(sTempL, "orange", false) == 0 )		Format(sTempL, sizeof(sTempL), "255 155 0");
		else if( strcmp(sTempL, "yellow", false) == 0 )		Format(sTempL, sizeof(sTempL), "255 255 0");
		else if( strcmp(sTempL, "white", false) == 0 )		Format(sTempL, sizeof(sTempL), "-1 -1 -1");
		else
			return;

		strcopy(sTempS, sizeof(sTempS), sTempL);
	}
	else if( args == 4 )
	{
		ExplodeString(sArg, " ", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
		Format(sTempL, sizeof(sTempL), "%s %s %s", sBuffers[1], sBuffers[2], sBuffers[3]);
		strcopy(sTempS, sizeof(sTempS), sTempL);
	}
	else if( args == 7 )
	{
		ExplodeString(sArg, " ", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));
		Format(sTempL, sizeof(sTempL), "%s %s %s", sBuffers[1], sBuffers[2], sBuffers[3]);
		Format(sTempS, sizeof(sTempS), "%s %s %s", sBuffers[4], sBuffers[5], sBuffers[6]);
	}
	else // No args, use default colors from cvars
	{
		if( bGroundFlare )
		{
			strcopy(sTempL, sizeof(sTempL), g_sGrndLCols);
			strcopy(sTempS, sizeof(sTempS), g_sGrndSCols);
		}
		else
		{
			g_hSelfLColor.GetString(sTempL, sizeof(sTempL));
		}
	}

	if( bGroundFlare )
		CreateFlare(target, sTempL, sTempS, true);
	else
		CreateFlare(target, sTempL, _, false);
}



// ====================================================================================================
//					COMMANDS - sm_flare, sm_flareme
// ====================================================================================================
public Action CmdFlare(int client, int args)
{
	char sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CommandCreateFlare(client, args, sArg, true);
	return Plugin_Handled;
}

public Action CmdFlareSelf(int client, int args)
{
	char sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CommandCreateFlare(client, args, sArg, false);
	return Plugin_Handled;
}

void CommandCreateFlare(int client, int args, const char[] sArg, bool bGroundFlare)
{
	// Must be valid
	if( !IsFlareValidNow() || !IsValidForFlare(client) )
		return;

	// Must be enabled
	if( bGroundFlare && !g_iGrndCmdAllow || !bGroundFlare && !g_iSelfCmdAllow )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Make sure the user has the correct permissions
	int flags;
	if( bGroundFlare )
		flags = g_iGrndFlags;
	else
		flags = g_iSelfFlags;
	int flagc = GetUserFlagBits(client);

	// if( bGroundFlare && !CheckCommandAccess(client, "sm_flare", flag) || !bGroundFlare && !CheckCommandAccess(client, "sm_flareme", flag) )
	if( flags != 0 && !(flagc & flags) && !(flagc & ADMFLAG_ROOT) )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Do not spawn flares when maximum reached
	if( GetFlareIndex(g_iMaxFlares) == -1 )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Max", client);
		return;
	}

	// Only attach 1 flare to players
	if( !bGroundFlare && IsValidEntRef(g_iAttachedFlare[client]) )
	{
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Wait", client);
		return;
	}

	// Only allow ROOT admins to spawn multiple flares
	if( !(flagc & ADMFLAG_ROOT) )
	{
		// Limit players to 1 flare
		if( IsValidEntRef(g_iFlareTimeout[client]) )
		{
			if( g_bHint )
				CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Wait", client);
			return;
		}

		// Don't allow players access to sm_flare command if cvar set only for incapped
		if( bGroundFlare && g_iGrndCmdAllow == 1 && !IsIncapped(client)
		|| !bGroundFlare && g_iSelfCmdAllow == 1 && !IsIncapped(client) )
		{
			if( g_bHint )
				CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Incapped", client);
			return;
		}
	}

	// Wrong number of arguments
	if( args != 0 && args != 1 && args != 3 && args != 6 )
	{
		// Display usage help if translation exists and hints turned on
		if( g_bHint )
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Usage", client);
		return;
	}

	// Passed the checks, lets create the flare
	char sTempL[12], sTempS[12];

	// Specified colors
	if( g_bLocked && !(flagc & ADMFLAG_ROOT) )
		flagc = 0;
	else
		flagc = 1;

	char sBuffers[6][4];
	if( flagc && args == 1 )
	{
		if( strcmp(sArg, "red", false) == 0 )				Format(sTempL, sizeof(sTempL), "255 0 0");
		else if( strcmp(sArg, "green", false) == 0 )		Format(sTempL, sizeof(sTempL), "0 255 0");
		else if( strcmp(sArg, "blue", false) == 0 )			Format(sTempL, sizeof(sTempL), "0 0 255");
		else if( strcmp(sArg, "purple", false) == 0 )		Format(sTempL, sizeof(sTempL), "100 0 150");
		else if( strcmp(sArg, "orange", false) == 0 )		Format(sTempL, sizeof(sTempL), "255 155 0");
		else if( strcmp(sArg, "yellow", false) == 0 )		Format(sTempL, sizeof(sTempL), "255 255 0");
		else if( strcmp(sArg, "white", false) == 0 )		Format(sTempL, sizeof(sTempL), "-1 -1 -1");
		else
			return;
	
		strcopy(sTempS, sizeof(sTempS), sTempL);
	}
	else if( flagc && args == 3 )
	{
		char sSplit[3][4];
		ExplodeString(sArg, " ", sSplit, sizeof(sSplit), sizeof(sSplit[]));
		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));
	}
	else if( flagc && args == 6 )
	{
		ExplodeString(sArg, " ", sBuffers, sizeof(sBuffers), sizeof(sBuffers[]));

		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sBuffers[0]), StringToInt(sBuffers[1]), StringToInt(sBuffers[2]));
		Format(sTempS, sizeof(sTempS), "%d %d %d", StringToInt(sBuffers[3]), StringToInt(sBuffers[4]), StringToInt(sBuffers[5]));
	}
	else
	{
		if( bGroundFlare )
		{
			strcopy(sTempL, sizeof(sTempL), g_sGrndLCols);
			strcopy(sTempS, sizeof(sTempS), g_sGrndSCols);
		}
		else
		{
			strcopy(sTempL, sizeof(sTempL), g_sSelfLCols);
		}
	}

	// Create flare
	if( bGroundFlare )
		CreateFlare(client, sTempL, sTempS, true);
	else
		CreateFlare(client, sTempL, _, false);
}



// ====================================================================================================
//					FLARE
// ====================================================================================================
// Create flare Attached / Ground, called from incap events and sm_flare commands.
void CreateFlare(int client, const char[] sColorL, const char[] sColorS = "", bool bGroundFlare = false)
{
	// Do not spawn flares when maximum reached
	if( GetFlareIndex(g_iMaxFlares) == -1 )
	{
		if( g_bHint )
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Max", client);
		return;
	}

	// Place on ground
	if( bGroundFlare )
	{
		float vAngles[3], vOrigin[3];

		// Flare position
		if( !MakeFlarePosition(client, vOrigin, vAngles) )
		{
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flare Invalid Place", client);
			return;	// Could not place after 12 attempts?!
		}

		int entity = MakeFlare(vAngles, vOrigin, sColorL, sColorS);
		g_iFlareTimeout[client] = entity;
	}
	// Attach to survivor
	else
	{
		AttachFlare(client, sColorL);
	}
}

bool MakeFlarePosition(int client, float vOrigin[3], float vAngles[3])
{
	float i, iLoop, fRadius=30.0, vAngle, vTargetOrigin[3];

	GetClientAbsOrigin(client, vOrigin);
	iLoop = GetRandomFloat(1.0, 360.0); // Random circle starting point

	// Loop through 12 positions around the player to find a good flare position
	for( i = iLoop; i <= iLoop + 6.0; i += 0.5 )
	{
		vTargetOrigin = vOrigin;
		vAngle = i * 360.0 / 12.0; // Divide circle into 12
		fRadius -= GetRandomFloat(0.0, 10.0); // Randomise circle radius

		// Draw in a circle around player
		vTargetOrigin[0] += fRadius * (Cosine(vAngle));
		vTargetOrigin[1] += fRadius * (Sine(vAngle));

		// Trace from target origin and get ground position/angles for placement
		GetGroundAngles(vTargetOrigin, vAngles);

		// Make sure the flare is within a reasonable height and distance
		fRadius = vTargetOrigin[2] - vOrigin[2];
		if( (fRadius >= -60.0 && fRadius <= 5.0) && GetVectorDistance(vTargetOrigin, vOrigin) <= 100.0)
		{
			vOrigin = vTargetOrigin;
			return true;
		}
	}
	return false;
}

void GetGroundAngles(float vOrigin[3], float vAngles[3])
{
	float vAng[3], vLookAt[3], vTargetOrigin[3];

	vTargetOrigin = vOrigin;
	vTargetOrigin[2] -= 20.0; // Point to the floor
	MakeVectorFromPoints(vOrigin, vTargetOrigin, vLookAt);
	GetVectorAngles(vLookAt, vAng); // get angles from vector for trace

	// execute Trace
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAng, MASK_ALL, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vStart[3], vNorm[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		TR_GetPlaneNormal(trace, vNorm); // Ground angles
		GetVectorAngles(vNorm, vAngles);

		float fRandom = GetRandomFloat(1.0, 360.0); // Random angle

		if( vNorm[2] == 1.0 ) // Is flat on ground
		{
			vAngles[0] = 0.0;
			vAngles[1] = fRandom;			// Rotate the prop in a random direction
		}
		else
		{
			vAngles[0] += 90.0;
			RotateYaw(vAngles, fRandom);	// Rotate the prop in a random direction
		}

		vOrigin = vStart;
	}

	delete trace;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
		return false;
	return true;
}

//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
void RotateYaw(float angles[3], float degree)
{
	float direction[3], normal[3];
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	float sin = Sine( degree * 0.01745328 );	 // Pi/180
	float cos = Cosine( degree * 0.01745328 );
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	float up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	float roll = GetAngleBetweenVectors( up, normal, direction );
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	float degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );

	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}



bool SetTeleportEndPoint(int client, float vPos[3])
{
	GetClientEyePosition(client, vPos);
	float vAng[3];
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, ExcludeSelf_Filter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool ExcludeSelf_Filter(int entity, int contentsMask, any client)
{
	if( entity == client )
		return false;
	return true;
}



// ====================================================================================================
//					GROUND FLARE
// ====================================================================================================
int GetFlareIndex(int total = MAX_FLARES)
{
	for( int i = 0; i < total; i++ )
		if( !g_iFlares[i][1] || EntRefToEntIndex(g_iFlares[i][1]) == INVALID_ENT_REFERENCE )
			return i;
	return -1;
}

public void OnUser(const char[] output, int caller, int activator, float delay)
{
	int entity;
	entity = EntIndexToEntRef(caller);

	for( int i = 0; i < MAX_FLARES; i++ )
	{
		if( entity == g_iFlares[i][1] )
			DeleteFlare(i);
	}
}

// After getting the flare position, we finally make it...
int MakeFlare(float vAngles[3], float vOrigin[3], const char[] sColorL, const char[] sColorS, bool forever = false)
{
	char sTemp[48];
	int entity, index;
	index = GetFlareIndex();
	if( index == -1 ) return 0;

	// Flare model
	entity = CreateEntityByName("prop_dynamic");
	if( entity == -1 )
	{
		LogError("Failed to create 'prop_dynamic'. Stopped making flare.");
		return 0;
	}
	else
	{
		if( forever == false )
		{
			Format(sTemp, sizeof(sTemp), "OnUser1 !self:FireUser2::%f:1", g_fTime);
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
			HookSingleEntityOutput(entity, "OnUser2", OnUser);
		}
		SetEntityModel(entity, MODEL_FLARE);
		DispatchSpawn(entity);
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		g_iFlares[index][1] = EntIndexToEntRef(entity);
	}

	// Light
	entity = 0;
	if( g_iGrndLight )
	{
		if( g_iGrndLight == 1 )
		{
			vOrigin[2] += 15.0;
			entity = MakeLightDynamic(vOrigin, view_as<float>({ 90.0, 0.0, 0.0 }), sColorL, g_iGrndLAlpha);
			vOrigin[2] -= 15.0;
			if( entity ) entity = EntIndexToEntRef(entity);
		}
		else
		{
			entity = CreateEntityByName("point_spotlight");
			if( entity == -1)
				LogError("Failed to create 'point_spotlight'");
			else
			{
				DispatchKeyValue(entity, "rendercolor", sColorL);
				DispatchKeyValue(entity, "rendermode", "9");
				DispatchKeyValue(entity, "spotlightwidth", "1");
				DispatchKeyValue(entity, "spotlightlength", "3");
				IntToString(g_iGrndLAlpha, sTemp, sizeof(sTemp));
				DispatchKeyValue(entity, "renderamt", sTemp);
				DispatchKeyValue(entity, "spawnflags", "1");
				DispatchSpawn(entity);
				AcceptEntityInput(entity, "TurnOn");

				DispatchKeyValue(entity, "angles", "90 0 0");
				vOrigin[2] += 0.4;
				TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
				vOrigin[2] -= 0.4;

				entity = EntIndexToEntRef(entity);
			}
		}
	}
	g_iFlares[index][2] = entity;

	// Position particles / smoke
	entity = 0;
	if( g_fFlareAngle == 0.0 ) g_fFlareAngle = GetRandomFloat(1.0, 360.0);
	vAngles[1] = g_fFlareAngle;
	vAngles[0] = -80.0;
	vOrigin[0] += (1.0 * (Cosine(DegToRad(vAngles[1]))));
	vOrigin[1] += (1.5 * (Sine(DegToRad(vAngles[1]))));
	vOrigin[2] += 1.0;

	// Flare particles
	entity = 0;
	if( g_bGrndStock )
	{
		entity = DisplayParticle(PARTICLE_FLARE, vOrigin, vAngles);
		if( entity ) entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][3] = entity;

	// Fuse particles
	entity = 0;
	if( g_bGrndFuse )
	{
		entity = DisplayParticle(PARTICLE_FUSE, vOrigin, vAngles);
		if( entity ) entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][4] = entity;

	// Smoke
	entity = 0;
	if( g_bGrndSmokeOn )
	{
		vAngles[0] = -85.0;
		entity = MakeEnvSteam(vOrigin, vAngles, sColorS, g_iGrndSAlpha, g_iGrndSHeight);
		if( entity ) entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][5] = entity;

	g_iFlares[index][0] = g_iFlares[index][1];
	PlaySound(g_iFlares[index][1]);

	return g_iFlares[index][1];
}



// ====================================================================================================
//					ATTACH FLARE
// ====================================================================================================
int AttachFlare(int client, const char[] sColorL)
{
	// Get survivor model
	char sModel[48];
	int iType;
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	switch( sModel[29] )
	{
		case 'c': iType = 1; // "coach");	
		case 'b': iType = 1; // "gambler");
		case 'h': iType = 3; // "mechanic");
		case 'd': iType = 1; // "producer");
		case 'v': iType = 2; // "NamVet");	
		case 'e': iType = 4; // "Biker");	
		case 'a': iType = 2; // "Manager");
		case 'n': iType = 5; // "TeenGirl");
		default: return 0;
	}

	char sTemp[40];
	float vOrigin[3], vAngles[3];
	int entity, index;

	index = GetFlareIndex();
	if( index == -1 ) return 0; // Should never happen

	// Flare model
	entity = CreateEntityByName("prop_dynamic");
	if( entity == -1 )
	{
		entity = 0;
		LogError("Failed to create 'prop_dynamic'");
	}
	else
	{
		SetEntityModel(entity, MODEL_FLARE);
		DispatchSpawn(entity);

		// Attach to survivor
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString(ATTACH_PILLS);
		AcceptEntityInput(entity, "SetParentAttachment");

		// Rotate to hide small parts of flare model and point upside down, so burning flare part at top
		switch( iType )
		{
			case 1:		// REST
			{
				vAngles = view_as<float>(  { 20.0, 90.0, -90.0 });
				vOrigin = view_as<float>(  { 3.0, 1.5, 8.0 });
			}
			case 2:		// NICK
			{
				vAngles = view_as<float>(  { 20.0, 90.0, -90.0 });
				vOrigin = view_as<float>(  { 2.5, 2.0, 8.0 });
			}
			case 3:		// ELLIS
			{
				vAngles = view_as<float>(  { 20.0, 90.0, -90.0 });
				vOrigin = view_as<float>(  { 2.5, 2.0, 8.0 });
			}
			case 4:		// FRANCIS
			{
				vAngles = view_as<float>(  { 20.0, 90.0, -90.0 });
				vOrigin = view_as<float>(  { 4.0, 2.0, 8.0 });
			}
			case 5:		// ZOEY
			{
				vAngles = view_as<float>(  { 10.0, -30.0, -110.0 });
				vOrigin = view_as<float>(  { -2.5, -6.5, 8.0 });
			}
		}

		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		entity = EntIndexToEntRef(entity);
		g_iAttachedFlare[client] = entity;

		Format(sTemp, sizeof(sTemp), "OnUser1 !self:FireUser2::%f:1", g_fSelfTime);
		SetVariantString(sTemp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		HookSingleEntityOutput(entity, "OnUser2", OnUser);
	}
	g_iFlares[index][1] = entity;

	// Position light and particles
	if( iType == 5 ) // Zoey
	{
		vOrigin = view_as<float>(  { -2.0, -7.0, 7.0 });
		vAngles = view_as<float>(  { -90.0, -180.0, 90.0 });
	}
	else
	{
		vOrigin[2] = 7.0;
		vAngles = view_as<float>(  { -110.0, -80.0, 90.0 });
	}

	// Light_Dynamic
	entity = 0;
	if( g_bSelfLight )
	{
		entity = MakeLightDynamic(vOrigin, vAngles, sColorL, g_iGrndLAlpha, true, client, ATTACH_PILLS);
		if( entity )
			entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][2] = entity;

	// Flare particles
	entity = 0;
	if( g_bSelfStock )
	{
		entity = DisplayParticle(PARTICLE_FLARE, vOrigin, vAngles, client, ATTACH_PILLS);

		if( entity )
			entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][3] = entity;

	// Fuse particles
	entity = 0;
	if( g_bSelfFuse )
	{
		entity = DisplayParticle(PARTICLE_FUSE, vOrigin, NULL_VECTOR, client, ATTACH_PILLS);

		if( entity )
			entity = EntIndexToEntRef(entity);
	}
	g_iFlares[index][4] = entity;

	g_iFlares[index][0] = client;
	PlaySound(client);

	return 1;
}



// ====================================================================================================
//					SOUND
// ====================================================================================================
void PlaySound(int entity)
{
	EmitSoundToAll(SOUND_CRACKLE, entity, SNDCHAN_AUTO, SNDLEVEL_DISHWASHER, SND_SHOULDPAUSE, SNDVOL_NORMAL, SNDPITCH_HIGH, -1, NULL_VECTOR, NULL_VECTOR);
}



// ====================================================================================================
//					LIGHTS
// ====================================================================================================
int MakeLightDynamic(const float vOrigin[3], const float vAngles[3], const char[] sColor, int iDist, bool bFlicker = true, int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	char sTemp[16];
	if( bFlicker )
		Format(sTemp, sizeof(sTemp), "6");
	else
		Format(sTemp, sizeof(sTemp), "0");
	DispatchKeyValue(entity, "style", sTemp);
	Format(sTemp, sizeof(sTemp), "%s 255", sColor);
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", float(iDist));
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);

	// Attach to survivor
	int len = strlen(sAttachment);
	if( client )
	{
		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		if( len != 0 )
		{
			SetVariantString(sAttachment);
			AcceptEntityInput(entity, "SetParentAttachment");
		}
	}
	return entity;
}

int MakeEnvSteam(const float vOrigin[3], const float vAngles[3], const char[] sColor, int iAlpha, int iLength)
{
	int entity = CreateEntityByName("env_steam");
	if( entity == -1 )
	{
		LogError("Failed to create 'env_steam'");
		return 0;
	}

	char sTemp[5];
	DispatchKeyValue(entity, "SpawnFlags", "1");
	DispatchKeyValue(entity, "rendercolor", sColor);
	DispatchKeyValue(entity, "SpreadSpeed", "1");
	DispatchKeyValue(entity, "Speed", "15");
	DispatchKeyValue(entity, "StartSize", "1");
	DispatchKeyValue(entity, "EndSize", "3");
	DispatchKeyValue(entity, "Rate", "10");
	IntToString(iLength, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "JetLength", sTemp);
	IntToString(iAlpha, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "renderamt", sTemp);
	DispatchKeyValue(entity, "InitialState", "1");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}



// ====================================================================================================
//					PARTICLES
// ====================================================================================================
void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

int DisplayParticle(const char[] sParticle, const float vPos[3], const float vAng[3], int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("info_particle_system");

	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		if( client )
		{
			// Attach to survivor
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);

			if( strlen(sAttachment) != 0 )
			{
				SetVariantString(sAttachment);
				AcceptEntityInput(entity, "SetParentAttachment");
			}
		}

		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		return entity;
	}
	return 0;
}



// ====================================================================================================
//					DELETE
// ====================================================================================================
void DeleteFlare(int index)
{
	int entity;

	entity = g_iFlares[index][0];
	g_iFlares[index][0] = 0;

	if( entity != 0 && (entity > 0 && entity <= MaxClients || EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE) )
		StopSound(entity, SNDCHAN_AUTO, SOUND_CRACKLE);

	entity = g_iFlares[index][1];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	entity = g_iFlares[index][2];
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "LightOff");
		AcceptEntityInput(entity, "Kill");
	}

	entity = g_iFlares[index][3];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	entity = g_iFlares[index][4];
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	entity = g_iFlares[index][5];
	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "TurnOff");
		SetVariantString("OnUser1 !self:Kill::10.0:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void DeleteAllFlares()
{
	g_bLoaded = false;
	for( int i = 0; i < MAX_FLARES; i++ )
		DeleteFlare(i);
}



// ====================================================================================================
//					BOOLEANS
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool IsValidForFlare(int client)
{
	if( !client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		return false;
	return true;
}

bool IsFlareValidNow()
{
	if( g_bRoundOver || !g_bCvarAllow )
		return false;
	return true;
}

bool IsIncapped(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}



// ====================================================================================================
//					SDKHOOKS TRANSMIT
// ====================================================================================================
public Action Hook_SetTransmit(int entity, int client)
{
	int iFlare = g_iAttachedFlare[client];

	if( iFlare && EntRefToEntIndex(iFlare) == entity )
		return Plugin_Handled;
	return Plugin_Continue;
}



// ====================================================================================================
//					COLORS.INC REPLACEMENT
// ====================================================================================================
void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");

	PrintToChat(client, buffer);
}