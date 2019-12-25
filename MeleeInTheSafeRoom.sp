#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:g_hEnabled;
new Handle:g_hWeaponRandom;
new Handle:g_hWeaponRandomAmount;
new Handle:g_hWeaponBaseballBat;
new Handle:g_hWeaponCricketBat;
new Handle:g_hWeaponCrowbar;
new Handle:g_hWeaponElecGuitar;
new Handle:g_hWeaponFireAxe;
new Handle:g_hWeaponFryingPan;
new Handle:g_hWeaponGolfClub;
new Handle:g_hWeaponKnife;
new Handle:g_hWeaponKatana;
new Handle:g_hWeaponMachete;
new Handle:g_hWeaponRiotShield;
new Handle:g_hWeaponTonfa;

new bool:g_bSpawnedMelee;

new g_iMeleeClassCount = 0;
new g_iMeleeRandomSpawn[20];
new g_iRound = 2;

new String:g_sMeleeClass[16][32];

MeleeInTheSafeRoom_OnModuleStart()
{
	g_hEnabled				= CreateConVar( "l4d2_MITSR_Enabled",		"1", "是否启用插件", FCVAR_PLUGIN ); 
	g_hWeaponRandom			= CreateConVar( "l4d2_MITSR_Random",		"1", "生成随机武器(1)或定制列表(0)", FCVAR_PLUGIN ); 
	g_hWeaponRandomAmount	= CreateConVar( "l4d2_MITSR_Amount",		"4", "如果l4d2_MITSR_Random为1, 则生成的武器数量", FCVAR_PLUGIN ); 
	g_hWeaponBaseballBat 	= CreateConVar( "l4d2_MITSR_BaseballBat",	"1", "要产卵的棒球棒的数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponCricketBat 	= CreateConVar( "l4d2_MITSR_CricketBat", 	"1", "需要产卵的板球棒数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponCrowbar 		= CreateConVar( "l4d2_MITSR_Crowbar", 	"1", "要产卵的撬棍数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponElecGuitar		= CreateConVar( "l4d2_MITSR_ElecGuitar",	"1", "要生成的电吉他数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponFireAxe			= CreateConVar( "l4d2_MITSR_FireAxe",		"1", "消防斧的产卵数量 (l4d2_MITSR_Random必须为 0)", FCVAR_PLUGIN );
	g_hWeaponFryingPan		= CreateConVar( "l4d2_MITSR_FryingPan",	"1", "要产卵的煎锅数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponGolfClub		= CreateConVar( "l4d2_MITSR_GolfClub",	"1", "要产卵的高尔夫球杆数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponKnife			= CreateConVar( "l4d2_MITSR_Knife",		"1", "要产卵的小刀的数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponKatana			= CreateConVar( "l4d2_MITSR_Katana",		"1", "武士刀产卵的数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponMachete			= CreateConVar( "l4d2_MITSR_Machete",		"1", "要生成的弯刀数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponRiotShield		= CreateConVar( "l4d2_MITSR_RiotShield",	"1", "要生成的防暴盾牌数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	g_hWeaponTonfa			= CreateConVar( "l4d2_MITSR_Tonfa",		"1", "要生成的tonfas的数量 (l4d2_MITSR_Random 必须为 0)", FCVAR_PLUGIN );
	//AutoExecConfig( true, "[L4D2]MeleeInTheSaferoom" );
	
	RegAdminCmd( "sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in current campaign" );
}

public Action:Command_SMMelee(client, args)
{
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		PrintToChat( client, "%d : %s", i, g_sMeleeClass[i] );
	}
}

MeleeInTheSafeRoom_OnMapStart()
{
	PrecacheModel( "models/weapons/melee/v_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/v_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/v_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/v_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/v_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/v_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/v_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/v_tonfa.mdl", true );
	
	PrecacheModel( "models/weapons/melee/w_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_cricket_bat.mdl", true );
	PrecacheModel( "models/weapons/melee/w_crowbar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_electric_guitar.mdl", true );
	PrecacheModel( "models/weapons/melee/w_fireaxe.mdl", true );
	PrecacheModel( "models/weapons/melee/w_frying_pan.mdl", true );
	PrecacheModel( "models/weapons/melee/w_golfclub.mdl", true );
	PrecacheModel( "models/weapons/melee/w_katana.mdl", true );
	PrecacheModel( "models/weapons/melee/w_machete.mdl", true );
	PrecacheModel( "models/weapons/melee/w_tonfa.mdl", true );
	
	PrecacheGeneric( "scripts/melee/baseball_bat.txt", true );
	PrecacheGeneric( "scripts/melee/cricket_bat.txt", true );
	PrecacheGeneric( "scripts/melee/crowbar.txt", true );
	PrecacheGeneric( "scripts/melee/electric_guitar.txt", true );
	PrecacheGeneric( "scripts/melee/fireaxe.txt", true );
	PrecacheGeneric( "scripts/melee/frying_pan.txt", true );
	PrecacheGeneric( "scripts/melee/golfclub.txt", true );
	PrecacheGeneric( "scripts/melee/katana.txt", true );
	PrecacheGeneric( "scripts/melee/machete.txt", true );
	PrecacheGeneric( "scripts/melee/tonfa.txt", true );
}

MeleeInTheSafeRoom_OnRoundStart()
{
	if( !GetConVarBool( g_hEnabled ) ) return;
	
	g_bSpawnedMelee = false;
	
	if( g_iRound == 2 && IsVersus() ) g_iRound = 1; else g_iRound = 2;
	
	GetMeleeClasses();
	
	CreateTimer( 1.0, Timer_SpawnMelee );
}

public Action:Timer_SpawnMelee( Handle:timer )
{
	new client = GetInGameClient();

	if( client != 0 && !g_bSpawnedMelee )
	{
		decl Float:SpawnPosition[3], Float:SpawnAngle[3];
		GetClientAbsOrigin( client, SpawnPosition );
		SpawnPosition[2] += 20; SpawnAngle[0] = 90.0;
		
		if( GetConVarBool( g_hWeaponRandom ) )
		{
			new i = 0;
			while( i < GetConVarInt( g_hWeaponRandomAmount ) )
			{
				new RandomMelee = GetRandomInt( 0, g_iMeleeClassCount-1 );
				if( IsVersus() && g_iRound == 2 ) RandomMelee = g_iMeleeRandomSpawn[i]; 
				SpawnMelee( g_sMeleeClass[RandomMelee], SpawnPosition, SpawnAngle );
				if( IsVersus() && g_iRound == 1 ) g_iMeleeRandomSpawn[i] = RandomMelee;
				i++;
			}
			g_bSpawnedMelee = true;
		}
		else
		{
			SpawnCustomList( SpawnPosition, SpawnAngle );
			g_bSpawnedMelee = true;
		}
	}
	else
	{
		if( !g_bSpawnedMelee ) CreateTimer( 1.0, Timer_SpawnMelee );
	}
}

stock SpawnCustomList( Float:Position[3], Float:Angle[3] )
{
	decl String:ScriptName[32];
	
	//Spawn Basseball Bats
	if( GetConVarInt( g_hWeaponBaseballBat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponBaseballBat ); i++ )
		{
			GetScriptName( "baseball_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Cricket Bats
	if( GetConVarInt( g_hWeaponCricketBat ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCricketBat ); i++ )
		{
			GetScriptName( "cricket_bat", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Crowbars
	if( GetConVarInt( g_hWeaponCrowbar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponCrowbar ); i++ )
		{
			GetScriptName( "crowbar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Electric Guitars
	if( GetConVarInt( g_hWeaponElecGuitar ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponElecGuitar ); i++ )
		{
			GetScriptName( "electric_guitar", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Fireaxes
	if( GetConVarInt( g_hWeaponFireAxe ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFireAxe ); i++ )
		{
			GetScriptName( "fireaxe", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Frying Pans
	if( GetConVarInt( g_hWeaponFryingPan ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponFryingPan ); i++ )
		{
			GetScriptName( "frying_pan", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Golfclubs
	if( GetConVarInt( g_hWeaponGolfClub ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponGolfClub ); i++ )
		{
			GetScriptName( "golfclub", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Knifes
	if( GetConVarInt( g_hWeaponKnife ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKnife ); i++ )
		{
			GetScriptName( "hunting_knife", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Katanas
	if( GetConVarInt( g_hWeaponKatana ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponKatana ); i++ )
		{
			GetScriptName( "katana", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Machetes
	if( GetConVarInt( g_hWeaponMachete ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponMachete ); i++ )
		{
			GetScriptName( "machete", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn RiotShields
	if( GetConVarInt( g_hWeaponRiotShield ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponRiotShield ); i++ )
		{
			GetScriptName( "riotshield", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
	
	//Spawn Tonfas
	if( GetConVarInt( g_hWeaponTonfa ) > 0 )
	{
		for( new i = 0; i < GetConVarInt( g_hWeaponTonfa ); i++ )
		{
			GetScriptName( "tonfa", ScriptName );
			SpawnMelee( ScriptName, Position, Angle );
		}
	}
}

stock SpawnMelee( const String:Class[32], Float:Position[3], Float:Angle[3] )
{
	decl Float:SpawnPosition[3], Float:SpawnAngle[3];
	SpawnPosition = Position;
	SpawnAngle = Angle;
	
	SpawnPosition[0] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[1] += ( -10 + GetRandomInt( 0, 20 ) );
	SpawnPosition[2] += GetRandomInt( 0, 10 );
	SpawnAngle[1] = GetRandomFloat( 0.0, 360.0 );

	new MeleeSpawn = CreateEntityByName( "weapon_melee" );
	DispatchKeyValue( MeleeSpawn, "melee_script_name", Class );
	DispatchSpawn( MeleeSpawn );
	TeleportEntity(MeleeSpawn, SpawnPosition, SpawnAngle, NULL_VECTOR );
}

stock GetMeleeClasses()
{
	new MeleeStringTable = FindStringTable( "MeleeWeapons" );
	g_iMeleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, g_sMeleeClass[i], 32 );
	}	
}

stock GetScriptName( const String:Class[32], String:ScriptName[32] )
{
	for( new i = 0; i < g_iMeleeClassCount; i++ )
	{
		if( StrContains( g_sMeleeClass[i], Class, false ) == 0 )
		{
			Format( ScriptName, 32, "%s", g_sMeleeClass[i] );
			return;
		}
	}
	Format( ScriptName, 32, "%s", g_sMeleeClass[0] );	
}
