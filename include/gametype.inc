#if defined _GameTypes_
	#endinput
#endif
#define _GameTypes_

/* **	****************************************
	*
	*	Game Type Determination Functions
	*	Author: Dirka_Dirka
	*
	*	Functions:
	*		GetGameType()		Takes the mp_gamemode and categorizes it based upon the type of game it is.
	*		GetGameMode()		Takes the mp_gamemode and converts it into an enum for easier use then a string.
	*		GetGameModeName()	Returns a translated string of desired mp_gamemode.
	*		CheckGameMode()		Input a gamemode string and return if it is valid (known).
	*		GetDifficulty()		Takes z_difficulty and converts it to an enum for easier use then a string.
	*		GetDifficultyName()	Returns a translated string of desired z_difficulty.
	*		CheckDifficulty()	Input a difficulty string and return if it is valid (known).
	*		GetTankHealth()		Takes z_tank_health and figures out what a tanks health should be based upon
	*							mp_gamemode and z_difficulty (it is calculated internally by the game).
	*		IsL4D();			Returns 1 (true) if L4D1 or L4D2, returns 0 (false) if not.
	*							For IsL4D(VERSION_L4D12 = 1): returns actual version of L4D (1 or 2). Returns 0 if neither.
	*
	*	Game Types that Left 4 Dead (1 or 2) supports:
	*	'coop' = 4 player style cooperative gameplay that runs through a campaign until the finale is won.
	*			A campaign can be 1 map with no safe rooms, or many linked maps.
	*			The campaign ends with an escape after the finale event is won.
	*			There is no score, the survivors either make it or they don't.
	*	'versus' = 4 vs 4 gameplay that runs through a campaign (like in coop) with the teams swapping sides each map.
	*			Score is based upon distance through the map by each player on the survivors team.
	*			The lobby 'survivor' team goes first on map 1, the losing team goes first every map afterwards.
	*	'scavenge' = 4 vs 4 gameplay on a single (section of a) map that is played over several rounds.
	*			Score is simply how many gas cans get poured into the target container.
	*			Losing team always starts each round. Best of X rounds is the winning team.
	*			Game ends as soon as the majority number of wins is reached.
	*			This is a Left 4 Dead 2 only game type.
	*	'survival' = 4 player gameplay on a single (section of a) map that is replayed over and over.
	*			Score is the time until all 4 survivors are dead/incapacitated.
	*			Game never ends. Players either need to leave or vote for a map change.
	*
	*	Valid mp_gamemode settings and the game type they fall into:
	*	'coop'		=	coop, realism, mutation3 (Bleed Out), mutation9 (Last Gnome on Earth)
	*	'versus'	=	versus, teamversus, mutation12 (Realism Versus)
	*	'scavenge'	=	scavenge, teamscavenge, mutation13 (Follow the Liter)
	*	'survival'	=	survival
	*
	*	New mutations are currently being released periodically.
	*	They will be added as the type of game they are part of is determined.
	*
	*	****************************************
	*
	*	Version Notes:
	*	1.0.0	Initial Release - Contains GetGameType() and GetDifficulty()
	*	1.1.0	Added GetTankHealth()
	*	1.1.1	Learned about 'static'
	*	1.1.2	Added mutation7 and mutation10 into coop.. mutation1 is single player only..????
	*			Don't know as much about static as I thought. Reverted some of the changes
	*	1.2		Added GetGameMode() to return an actual game mode for comparisons. eg:
	*				Use GetGameType() to find a game is 'coop' to make sure it is a 4 player campaign style game.
	*				Then use GetGameMode() to make sure that it is not 'bleed out' - since your playing around with health
	*			Changed previously used GM_* to GT_* due to the new GM_* overlapping.
	*			Changed GT_* from 0 -> X to -1 -> X
	*			mutation1 is now GT_SINGLEPLAY which is GT_Unknown - best to consider it to default to coop
	*			Added IsL4D() - returns 0 if neither, otherwise depends on input.
	*			Fixed a mistake in GetTankHealth()
	*			Added more readable friendly names for the gamemodes.. eg: 'Realism Versus' instead of mutation12
	*			Added GetGameModeName(). Returns the readable friendly version of mp_gamemode.
	*				eg: mutation3 = Last Gnome on Earth
	*				Optional inputs are the game type and game mode. If they are not included GetGameType() and GetGameMode() will be called.
	*	1.2.1	Added mutation2 - Headshots.
	*	1.3		Added mutation15 - Versus Survival
	*			Updated GetTankHealth() - tank has vs health, not survival health.
	*			Started on mutation?? - Four Swordsmen (it'll be coop so probably < mutation10).
	*			Changed all the gamemode defines to a single enum.
	*			Changed all the gametype defines to a single enum.
	*			Changed all the difficulty defines to a single enum.
	*			Got rid of g_i*ModesCount defines.. using sizeof(enum) instead.
	*			Got rid of g_iDifficuliesCount.. using sizeof(enum) instead.
	*			Compressed g_s*Modes and g_s*ModesFriendly into 1 m.d. array.
	*			Added Translations for the friendly printable gamemodes.
	*			Re-wrote most of the plugin to work with the changes listed above.
	*			Added mode input to GetGameType(), will return the type of any mode inputted, or the current mode (if empty)
	*			Added GetDifficultyName() - just like GetGameModeName().
	*				No input = find current, and report.. input means convert what is asked.
	*	1.3.1	Added CheckDifficulty() and CheckGameMode().
	*	1.3.2	Added Versus Survival as a game type (it's not quite versus, yet it's definitely not survival).
	*			Updated GetTankHealth()
	*			Didnt actually compile the code from 1.3 until now.. seems as though I can't figure out how
	*				to use the enums properly.. added back in some defines :(
	*			Also, translations don't work.. keep getting invalid client numbers when calling functions on round start.
	*				Can use translations in a plugin if needed.
	*	1.3.3	Added mutation5 - Four Swordsmen
	*	1.3.4	Added mutation4 - Hard Eight
	*
	***	*/

#define FOR_EACH_GAME_MODE(%1)					\
	for(new %1=0; %1<sizeof(GameModes); %1++)

#define FOR_EACH_DIFFICULTY(%1)					\
	for(new %1=0; %1<sizeof(Difficulties); %1++)

#define GM_SIZE		24		// length of mp_gamemode (teamscavenge = 12 and is longest to date)
							// Adding in the new friendly game modes.. and longest is now 'Last Gnome on Earth' at 19
#define GF_SIZE		12		// length of the gamefolder (left4dead2 = 10)

#define	VERSION_L4D		0		// Used to find if it is L4D1/2
#define	VERSION_L4D12		1		// Used to determine if game is L4D1 (false) or L4D2 (true)

enum g_eDifficulties {
	DIF_Unknown = 0,		// z_difficulty != any of the below..
	Easy,					// z_difficulty == Easy
	Normal,					// z_difficulty == Normal
	Hard,					// z_difficulty == Hard
	Impossible				// z_difficulty == Impossible
}
#define		DIF_UNKNOWN		0
#define		DIF_EASY			1
#define		DIF_NORMAL			2
#define		DIF_HARD			3
#define		DIF_IMPOSSIBLE		4
enum g_eDifficultyInfo {
				Difficulty,
	String:		s_Difficulty[GM_SIZE],
	String:		s_Name[GM_SIZE]
}
public		Difficulties[g_eDifficulties][g_eDifficultyInfo];

static	String:	g_sDifficulies[g_eDifficulties][] = {
	"Unknown",
	"Easy",
	"Normal",
	"Hard",
	"Impossible"
};
static	String:	g_sDifficultiesFriendly[g_eDifficulties][] = {
	"Unknown",
	"Easy",
	"Normal",
	"Hard",
	"Impossible"
};

enum g_eGameTypes {
	GT_Unknown = -1,	// unknown or new mutation/gamemode.
	GT_Single_Play,	// mutation1 (Last Man On Earth)
	GT_Coop = 1,		// coop, realism, mutation2 (Headshots), mutation3 (Bleed Out), etc.
	GT_Versus,			// versus, teamversus, mutation12 (Realism Versus)
	GT_Scavenge,		// scavenge, teamscavenge, mutation13 (Follow the Liter)
	GT_Survival,		// survival
	GT_VsSurvival		// mutation15
}
#define		GT_UNKNOWN		-1
#define		GT_SP			0
#define		GT_COOP			1
#define		GT_VERSUS		2
#define		GT_SCAVENGE	3
#define		GT_SURVIVAL	4
#define		GT_VS_SURV		5

/* **	**********************************************************************************
	*	**																				**
	*	**	Add new game modes below	\ /		\ /		\ /		\ /		\ /		\ /		**
	*	**																				**
	*	**********************************************************************************
	*
	*	Case is critical.. All game modes are lower case.
	*	If you add any (eg: new mutations), and type them in wrong here, don't blame me when it doesn't work.
	*
	***	*/

enum g_eGameModes {
	GM_Unknown = 0,		// mp_gamemode != any of the below
	Last_Man_On_Earth,		// mp_gamemode == mutation1
	Coop,					// mp_gamemode == coop
	Realism,				// mp_gamemode == realism
	Headshots,				// mp_gamemode == mutation2
	Bleedout,				// mp_gamemode == mutation3
	Hard_Eight,			// mp_gamemode == mutation4
	Four_Swordsmen,		// mp_gamemode == mutation5
	Chainsaws,				// mp_gamemode == mutation7
	Last_Gnome_On_Earth,	// mp_gamemode == mutation9
	Room_4_One,			// mp_gamemode == mutation10
	Versus,					// mp_gamemode == versus
	Team_Versus,			// mp_gamemode == teamversus
	Realism_Versus,		// mp_gamemode == mutation12
	Scavenge,				// mp_gamemode == scavenge
	Team_Scavenge,			// mp_gamemode == teamscavenge
	Follow_The_Liter,		// mp_gamemode == mutation13
	Survival,				// mp_gamemode == survival
	Versus_Survival		// mp_gamemode == mutation15
}
#define		GM_UNKNOWN		0
#define		GM_LMOE			1
#define		GM_COOP			2
#define		GM_REALISM		3
#define		GM_HEADSHOT	4
#define		GM_HARDEIGHT	5
#define		GM_BLEEDOUT	6
#define		GM_4SWORD		7
#define		GM_CHAINSAW	8
#define		GM_LGOE			9
#define		GM_ROOM4ONE	10
#define		GM_VERSUS		11
#define		GM_T_VERSUS	12
#define		GM_R_VERSUS	13
#define		GM_SCAVENGE	14
#define		GM_T_SCAVENGE	15
#define		GM_FTL			16
#define		GM_SURVIVAL	17
#define		GM_VS_SURV		18
enum g_eGameModesInfo {
	String:		s_Mode[GM_SIZE],
	String:		s_Name[GM_SIZE],
				GameMode,
				GameType
}
public		GameModes[g_eGameModes][g_eGameModesInfo];

static	String:	g_sModes[g_eGameModes][] = {
	"unknown",			// If none of the below are found - use this.
	"mutation1",		// Last Man on Earth
	"coop",
	"realism",
	"mutation2",		// Headshots
	"mutation3",		// Bleed Out
	"mutation4",		// Hard Eight
	"mutation5",		// Four Swordsmen of the Apocalypse
	"mutation7",		// Chainsaws
	"mutation9",		// Last Gnome On Earth
	"mutation10",		// Room 4 One
	"versus",
	"teamversus",
	"mutation12",		// Realism Versus
	"scavenge",
	"teamscavenge",
	"mutation13",		// Follow The Liter
	"survival",
	"mutation15"		// Versus Survival
};
static	String:	g_sModesFriendly[g_eGameModes][] = {
	"Unknown",
	"Last Man on Earth",
	"Coop",
	"Realism",
	"Headshot!",
	"Bleed Out",
	"Hard Eight",
	"Four Swordsmen of the Apocalypse",
	"Chainsaw Massacre",
	"Last Gnome on Earth",
	"Room 4 One",
	"Versus",
	"Team Versus",
	"Realism Versus",
	"Scavenge",
	"Team Scavenge",
	"Follow the Liter",
	"Survival",
	"Versus Survival"
};

/* **	**********************************************************************************
	*	**																				**
	*	**	Add new game modes above	/ \		/ \		/ \		/ \		/ \		/ \		**
	*	**																				**
	*	**********************************************************************************
	***	*/

stock GetGameType(mode = GM_UNKNOWN) {
/**
 * Determines the type of game being played.. see above for a more complete description.
 *
 * @param 		None.
 * @returns		The gametype being played: GT_Coop, GT_Versus, GT_Scavenge or GT_Survival
 *				Returns GT_Unknown, if it cannot be determined (eg: new mode that is not in lists).
 * @errors		none (errors would occur in GetGameMode()).
 */
	_Init();
	
	if (mode == GM_UNKNOWN)
		mode = GetGameMode();
	return GameModes[mode][GameType];
}

stock GetGameMode() {
/**
 * Finds the actual mp_gamemode and converts it into an enum (int) for easy computing
 *
 * @param 		None.
 * @returns		The current Game Mode, too many to list, but for eg:
 *				Returns Coop when mp_gamemode == coop & Last_Gnome_On_Earth when mp_gamemode == mutation9
 *				Returns GM_Unknown (-1) if it cannot be determined (eg: new and not in lists).
 * @errors		cannot find mp_gamemode, cannot continue
 */
	_Init();
	// Can't find mp_gamemode?? don't continue..
	decl String:s_mp_gamemode[GM_SIZE];
	new Handle:h_mp_gamemode = FindConVar("mp_gamemode");
	if (h_mp_gamemode != INVALID_HANDLE)
		GetConVarString(h_mp_gamemode, s_mp_gamemode, GM_SIZE);
	else
		ThrowError("Cannot find ConVar mp_gamemode");
	
	FOR_EACH_GAME_MODE(index) {
		if (StrEqual(s_mp_gamemode, GameModes[index][s_Mode], true)) {
			return GameModes[index][GameMode];
		}
	}
	return GameModes[GM_Unknown][GameMode];
}

stock GetGameModeName(mode = GM_UNKNOWN) {
/**
 * Converts mp_gamemode into a string for easy reading.
 *
 * @param 		mode	The game mode as per GetGameMode(). Will look it up if mode == GM_Unknown
 * @returns				The current Gamemode Name (translated), too many to list, but for eg:
 *						Returns "Coop" when mp_gamemode == coop & "Headshots!" when mp_gamemode == mutation2
 * @errors				none (errors would occur in GetGameMode()).
 */
	_Init();
	if (mode == GM_UNKNOWN)
		mode = GetGameMode();
	return GameModes[mode][s_Name];
}

stock CheckGameMode(const String:mode[GM_SIZE]) {
/**
 * Converts mp_gamemode into a string for easy reading.
 *
 * @param 		mode	The gamemode string in question.
 * @returns				True if mode is valid/known. False otherwise.
 * @errors				none.
 */
	_Init();
	new g_eGameModes:index;
	FOR_EACH_GAME_MODE(index) {
		if (StrEqual(mode, GameModes[index][s_Mode], true)) {
			return true;
		}
	}
	return false;
}

stock GetDifficulty() {
/**
 * Finds the Difficulty cvar (z_difficulty) and converts it into an enum (int) for easy computing.
 *
 * @param 		None.
 * @returns		The current Difficulty being played as an enum: Easy, Normal, Hard or Impossible
 *				Returns DIF_Unknown if it cannot be determined (not in defined lists).
 * @errors		cannot find z_difficulty, cannot continue
 */
	_Init();
	// Can't find z_difficulty?? don't continue..
	decl String:s_diff[GM_SIZE];
	new Handle:h_z_difficulty = FindConVar("z_difficulty");
	if (h_z_difficulty != INVALID_HANDLE)
		GetConVarString(h_z_difficulty, s_diff, GM_SIZE);
	else
		ThrowError("Cannot find ConVar z_difficulty");
	
	FOR_EACH_DIFFICULTY(index) {
		if (StrEqual(s_diff, Difficulties[index][s_Difficulty], true)) {
			return Difficulties[index][Difficulty];
		}
	}
	return Difficulties[DIF_Unknown][Difficulty];
}

stock GetDifficultyName(diff = DIF_UNKNOWN) {
/**
 * Converts z_difficulty into string for easy reading.
 *
 * @param 		diff	The difficulty as per GetDifficulty(). Will look it up if diff == DIF_Unknown
 * @returns				The current Difficulty Name (translated), for eg:
 *						Returns "Easy" when z_difficulty == Easy
 * @errors				none (errors would occur in GetDifficulty()).
 */
	_Init();
	if (diff == DIF_UNKNOWN)
		diff = GetDifficulty();
	return Difficulties[diff][s_Name];
}

stock CheckDifficulty(const String:diff[GM_SIZE]) {
/**
 * Converts mp_gamemode into a string for easy reading.
 *
 * @param 		diff	The difficulty string in question.
 * @returns				True if difficulty is valid/known. False otherwise.
 * @errors				none.
 */
	_Init();
	FOR_EACH_DIFFICULTY(index) {
		if (StrEqual(mode, Difficulties[index][s_Mode], true)) {
			return true;
		}
	}
	return false;
}

stock GetTankHealth(bool:combine = false) {
/**
 * Finds the Health of a tank based upon z_tank_health, Difficulty & Game Mode.
 *
 * @param 	combine		Combine Difficulty and Game Mode results before returning?
 *						Normally it doesn't happen, but it will be checked for modified servers
 * @returns				The max health of a Tank.
 * @errors				cannot find z_tank_health, cannot continue
 */
	_Init();
	// Can't find z_tank_health?? don't continue..
	static Float:z_tankhealth;
	new Handle:ztankhealth = FindConVar("z_tank_health");
	if (ztankhealth != INVALID_HANDLE)
		z_tankhealth = GetConVarFloat(ztankhealth);
	else
		ThrowError("Cannot find ConVar z_tank_health");
	
	static tankHealth;
	new difficulty = GetDifficulty();
	new gamemode = GetGameType();
/*
	Tank health is a function of the difficulty:
		For Easy games, it is 0.75x z_tank_health
		For Normal games, it is 1x z_tank_health
		For Hard and Impossible games, it is 2x z_tank_health
	It is also a function of the game mode:
		For all Coop, see above
		For all Versus and Scavenge games, it is 1.5x z_tank_health
		For Survival, it is z_tank_health.
		For Versus Survival, it is 1.5x z_tank_health
	Not entirely certain what a combination would do.. Versus/Scavenge/Survival are ALWAYS Normal (unless forced)
	Will check against each and combine the results
*/
	// Check difficulties for the health
	static Float:multi1 = 0.0;
	if (difficulty == DIF_EASY)
		multi1 = 0.75;
	else if (difficulty == DIF_NORMAL)
		multi1 = 1.0;
	else if ((difficulty == DIF_HARD) || (difficulty == DIF_IMPOSSIBLE))
		multi1 = 2.0;
	
	// Check the gamemodes for the health
	static Float:multi2 = 0.0;
	switch (gamemode) {
		case GT_Coop, GT_Survival:					multi2 = 1.0;
		case GT_Versus, GT_Scavenge, GT_VsSurvival:	multi2 = 1.5;
		default:										multi2 = 1.0;
	}
	
	// If mixing is allowed, do it
	if (combine) {
		tankHealth = RoundToNearest(FloatMul(FloatMul(z_tankhealth, multi1), multi2));
	} else {
		if (gamemode == GT_Coop)
			tankHealth = RoundToNearest(FloatMul(z_tankhealth, multi1));
		else
			tankHealth = RoundToNearest(FloatMul(z_tankhealth, multi2));
	}
	return tankHealth;
}

/**
 * Finds if the game is L4D or L4D2.
 *
 * @param 	version			Used to determine check type.. either if any L4D game, or which L4D game.
 * @returns					For VERSION_L4D: returns 1 if L4D1 or L4D2, otherwise returns -1.
 *							For VERSION_L4D12: returns 1 if L4D1, returns 2 if L4D2, otherwise returns 0.
 * @errors					on bad input (version != VERSION_L4D or VERSION_L4D12), throw error
 */
stock IsL4D(version = VERSION_L4D) {
	// Is the game left 4 dead *
	new l4d_version = -1;
	decl String:game_name[GF_SIZE];
	GetGameFolderName(game_name, GF_SIZE);
	
	switch (version) {
		case VERSION_L4D: {
			if ((StrEqual(game_name, "left4dead2", false)) || (StrEqual(game_name, "left4dead", false)))
				l4d_version = 1;
		}
		case VERSION_L4D12: {
			if (StrEqual(game_name, "left4dead", false))
				l4d_version = 1;
			else if (StrEqual(game_name, "left4dead2", false))
				l4d_version = 2;
			else
				l4d_version = 0;
				//ThrowError("Game is not Left 4 Dead 1 or 2.");
		}
		default: {
			ThrowError("Invalid input, must be 0 (VERSION_L4D) or 1 (VERSION_L4D12).");
		}
	}
	return l4d_version;
}

static _Init() {
	//only need to init once.
	static bool:b_HasInit = false;
	
	if (!b_HasInit) {
		b_HasInit = true;
		LoadTranslations("gametype.phrases.txt");
		
		Format(GameModes[GM_Unknown][s_Mode],			GM_SIZE-1,	g_sModes[GM_Unknown]);
		Format(GameModes[Last_Man_On_Earth][s_Mode],	GM_SIZE-1,	g_sModes[Last_Man_On_Earth]);
		Format(GameModes[Coop][s_Mode],					GM_SIZE-1,	g_sModes[Coop]);
		Format(GameModes[Realism][s_Mode],				GM_SIZE-1,	g_sModes[Realism]);
		Format(GameModes[Headshots][s_Mode],				GM_SIZE-1,	g_sModes[Headshots]);
		Format(GameModes[Bleedout][s_Mode],				GM_SIZE-1,	g_sModes[Bleedout]);
		Format(GameModes[Four_Swordsmen][s_Mode],		GM_SIZE-1,	g_sModes[Four_Swordsmen]);
		Format(GameModes[Chainsaws][s_Mode],				GM_SIZE-1,	g_sModes[Chainsaws]);
		Format(GameModes[Last_Gnome_On_Earth][s_Mode],	GM_SIZE-1,	g_sModes[Last_Gnome_On_Earth]);
		Format(GameModes[Room_4_One][s_Mode],			GM_SIZE-1,	g_sModes[Room_4_One]);
		Format(GameModes[Versus][s_Mode],					GM_SIZE-1,	g_sModes[Versus]);
		Format(GameModes[Team_Versus][s_Mode],			GM_SIZE-1,	g_sModes[Team_Versus]);
		Format(GameModes[Realism_Versus][s_Mode],		GM_SIZE-1,	g_sModes[Realism_Versus]);
		Format(GameModes[Scavenge][s_Mode],				GM_SIZE-1,	g_sModes[Scavenge]);
		Format(GameModes[Team_Scavenge][s_Mode],			GM_SIZE-1,	g_sModes[Team_Scavenge]);
		Format(GameModes[Follow_The_Liter][s_Mode],		GM_SIZE-1,	g_sModes[Follow_The_Liter]);
		Format(GameModes[Survival][s_Mode],				GM_SIZE-1,	g_sModes[Survival]);
		Format(GameModes[Versus_Survival][s_Mode],		GM_SIZE-1,	g_sModes[Versus_Survival]);
		
		Format(GameModes[GM_Unknown][s_Name],			GM_SIZE-1,	g_sModesFriendly[GM_Unknown]);
		Format(GameModes[Last_Man_On_Earth][s_Name],	GM_SIZE-1,	g_sModesFriendly[Last_Man_On_Earth]);
		Format(GameModes[Coop][s_Name],					GM_SIZE-1,	g_sModesFriendly[Coop]);
		Format(GameModes[Realism][s_Name],				GM_SIZE-1,	g_sModesFriendly[Realism]);
		Format(GameModes[Headshots][s_Name],				GM_SIZE-1,	g_sModesFriendly[Headshots]);
		Format(GameModes[Bleedout][s_Name],				GM_SIZE-1,	g_sModesFriendly[Bleedout]);
		Format(GameModes[Four_Swordsmen][s_Name],		GM_SIZE-1,	g_sModesFriendly[Four_Swordsmen]);
		Format(GameModes[Chainsaws][s_Name],				GM_SIZE-1,	g_sModesFriendly[Chainsaws]);
		Format(GameModes[Last_Gnome_On_Earth][s_Name],	GM_SIZE-1,	g_sModesFriendly[Last_Gnome_On_Earth]);
		Format(GameModes[Room_4_One][s_Name],			GM_SIZE-1,	g_sModesFriendly[Room_4_One]);
		Format(GameModes[Versus][s_Name],					GM_SIZE-1,	g_sModesFriendly[Versus]);
		Format(GameModes[Team_Versus][s_Name],			GM_SIZE-1,	g_sModesFriendly[Team_Versus]);
		Format(GameModes[Realism_Versus][s_Name],		GM_SIZE-1,	g_sModesFriendly[Realism_Versus]);
		Format(GameModes[Scavenge][s_Name],				GM_SIZE-1,	g_sModesFriendly[Scavenge]);
		Format(GameModes[Team_Scavenge][s_Name],			GM_SIZE-1,	g_sModesFriendly[Team_Scavenge]);
		Format(GameModes[Follow_The_Liter][s_Name],		GM_SIZE-1,	g_sModesFriendly[Follow_The_Liter]);
		Format(GameModes[Survival][s_Name],				GM_SIZE-1,	g_sModesFriendly[Survival]);
		Format(GameModes[Versus_Survival][s_Name],		GM_SIZE-1,	g_sModesFriendly[Versus_Survival]);
		
		GameModes[GM_Unknown][GameMode]				=	GM_UNKNOWN;
		GameModes[Last_Man_On_Earth][GameMode]		=	GM_LMOE;
		GameModes[Coop][GameMode]						=	GM_COOP;
		GameModes[Realism][GameMode]					=	GM_REALISM;
		GameModes[Headshots][GameMode]				=	GM_HEADSHOT;
		GameModes[Bleedout][GameMode]					=	GM_BLEEDOUT;
		GameModes[Four_Swordsmen][GameMode]			=	GM_4SWORD;
		GameModes[Chainsaws][GameMode]				=	GM_CHAINSAW;
		GameModes[Last_Gnome_On_Earth][GameMode]		=	GM_LGOE;
		GameModes[Room_4_One][GameMode]				=	GM_ROOM4ONE;
		GameModes[Versus][GameMode]					=	GM_VERSUS;
		GameModes[Team_Versus][GameMode]				=	GM_T_VERSUS;
		GameModes[Realism_Versus][GameMode]			=	GM_R_VERSUS;
		GameModes[Scavenge][GameMode]					=	GM_SCAVENGE;
		GameModes[Team_Scavenge][GameMode]			=	GM_T_SCAVENGE;
		GameModes[Follow_The_Liter][GameMode]		=	GM_FTL;
		GameModes[Survival][GameMode]					=	GM_SURVIVAL;
		GameModes[Versus_Survival][GameMode]			=	GM_VS_SURV;
		
		GameModes[GM_Unknown][GameType]				=	GT_UNKNOWN;
		GameModes[Last_Man_On_Earth][GameType]		=	GT_SP;
		GameModes[Coop][GameType]						=	GT_COOP;
		GameModes[Realism][GameType]					=	GT_COOP;
		GameModes[Headshots][GameType]				=	GT_COOP;
		GameModes[Bleedout][GameType]					=	GT_COOP;
		GameModes[Four_Swordsmen][GameType]			=	GT_COOP;
		GameModes[Chainsaws][GameType]				=	GT_COOP;
		GameModes[Last_Gnome_On_Earth][GameType]		=	GT_COOP;
		GameModes[Room_4_One][GameType]				=	GT_COOP;
		GameModes[Versus][GameType]					=	GT_VERSUS;
		GameModes[Team_Versus][GameType]				=	GT_VERSUS;
		GameModes[Realism_Versus][GameType]			=	GT_VERSUS;
		GameModes[Scavenge][GameType]					=	GT_SCAVENGE;
		GameModes[Team_Scavenge][GameType]			=	GT_SCAVENGE;
		GameModes[Follow_The_Liter][GameType]		=	GT_SCAVENGE;
		GameModes[Survival][GameType]					=	GT_SURVIVAL;
		GameModes[Versus_Survival][GameType]			=	GT_VS_SURV;
		
		Difficulties[DIF_Unknown][Difficulty]	=	DIF_UNKNOWN;
		Difficulties[Easy][Difficulty]			=	DIF_EASY;
		Difficulties[Normal][Difficulty]			=	DIF_NORMAL;
		Difficulties[Hard][Difficulty]			=	DIF_HARD;
		Difficulties[Impossible][Difficulty]		=	DIF_IMPOSSIBLE;
		
		Format(Difficulties[DIF_Unknown][s_Difficulty],	GM_SIZE-1,	g_sDifficulies[DIF_Unknown]);
		Format(Difficulties[Easy][s_Difficulty],			GM_SIZE-1,	g_sDifficulies[Easy]);
		Format(Difficulties[Normal][s_Difficulty],		GM_SIZE-1,	g_sDifficulies[Normal]);
		Format(Difficulties[Hard][s_Difficulty],			GM_SIZE-1,	g_sDifficulies[Hard]);
		Format(Difficulties[Impossible][s_Difficulty],	GM_SIZE-1,	g_sDifficulies[Impossible]);
		
		Format(Difficulties[DIF_Unknown][s_Name],	GM_SIZE-1,	g_sDifficultiesFriendly[DIF_Unknown]);
		Format(Difficulties[Easy][s_Name],			GM_SIZE-1,	g_sDifficultiesFriendly[Easy]);
		Format(Difficulties[Normal][s_Name],			GM_SIZE-1,	g_sDifficultiesFriendly[Normal]);
		Format(Difficulties[Hard][s_Name],			GM_SIZE-1,	g_sDifficultiesFriendly[Hard]);
		Format(Difficulties[Impossible][s_Name],		GM_SIZE-1,	g_sDifficultiesFriendly[Impossible]);
	}
}
