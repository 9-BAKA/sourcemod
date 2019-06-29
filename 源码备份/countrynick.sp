/*
SourceMod Country Nick Plugin
Add country of the player near his nick
 
Country Nick Plugin (C)2009-2010 A-L. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

$Id: countrynick.sp 29 2009-02-23 23:45:22Z aen0 $
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
 
#define VERSION "1.1.1"

public Plugin:myinfo =
{
	name = "Country Nick Plugin",
	author = "Antoine LIBERT aka AeN0",
	description = "Add country of the player near his nick",
	version = VERSION,
	url = "http://www.a-l.fr/"
};

public OnPluginStart()
{
	LoadTranslations("countrynick.phrases");
	CreateConVar("countrynick_version", VERSION, "本插件版本", FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	decl String:ip[16];
	decl String:country[46];
	decl String:name[65];
	
	if(!IsFakeClient(client) && client != 0)
	{
		getPlayerNameWithCountry(client, name, 65);
		if (name[1] == 'C' && name[2] == 'N')
		{
			return;
		}

		SetClientInfo(client, "name", name);
		
		GetClientIP(client, ip, 16); 
		
		if(GeoipCountry(ip, country, 45))
		{
			PrintToChatAll("\x03%T", "Announcer country found", LANG_SERVER, client, country);
			PrintToServer("\x03%T", "Announcer country found", LANG_SERVER, client, country);
		}
		else
		{
			PrintToChatAll("\x03%T", "Announcer country not found", LANG_SERVER, client);
			PrintToServer("\x03%T", "Announcer country not found", LANG_SERVER, client);
			LogError("[Country Nick] Warning : %s使用%s 那不是列在GEOIP資料庫內", name, ip);
		}
	}
}

getFlagOfPlayer(client, String:flag[], size)
{
	decl String:ip[16];
	decl String:code2[3];
	
	GetClientIP(client, ip, 16);
	if(GeoipCode2(ip, code2))
	{
		Format(flag, size, "[%2s]", code2);
		return true;
	}
	else
	{
		Format(flag, size, "[--]");
		return false;
	}
}

getPlayerNameWithCountry(client, String:name[], size)
{
	decl String:flag[5];
	
	getFlagOfPlayer(client, flag, 5);
	char clientName[64];
	GetClientName(client, clientName, 64);
	Format(name, size, "%s%s", flag, clientName);
}