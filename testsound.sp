#include <sourcemod>
#include <sdktools>
 
new const String:FULL_SOUND_PATH[] = "sound/music/hfl.mp3";
new const String:RELATIVE_SOUND_PATH[] = "*/music/hfl.mp3";
 
public OnPluginStart()
{
	RegConsoleCmd( "sm_testsound", sm_testsound );
}
 
public OnMapStart()
{
	AddFileToDownloadsTable( FULL_SOUND_PATH );
	FakePrecacheSound( RELATIVE_SOUND_PATH );
}
 
public Action:sm_testsound( client, argc )
{
	EmitSoundToClient( client, RELATIVE_SOUND_PATH );
 
	return Plugin_Handled;
}
 
stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable( FindStringTable( "soundprecache" ), szPath );
}