//Drop Luky item
//edit by Johnson
//2013-11-27
#define SLOT_NUM		20
#define WEPN_NUM		200
new g_ItemSlot[SLOT_NUM]					= { -1, ... };
new Float:g_ItemLimitLife[SLOT_NUM]			= { 0.0, ... };
//new g_WepnSlot[WEPN_NUM]					= { -1, ... };


#define LUMA_MDL		"models/items/l4d_gift.mdl"

#define LUCKY_TANK_DROP	1			//坦克是否掉落 0不掉落 1掉落
#define LUCKY_BOT_DROP 	0			//电脑人是否可以捡起来
#define g_ItemStay		15.0			//道具停留时间
#define LuckyMax			3			//最大掉落
#define REWARD_SOUND	"level/gnomeftw.wav"
#define TELEPOT_SOUND	"ui/menu_horror01.wav"
new Handle:g_ItemLife[SLOT_NUM]				= { INVALID_HANDLE, ... };
new String:curMap[128];

public Action:EVENT_PlayerDeath2(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client		= GetClientOfUserId( GetEventInt( event, "userid" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "attacker" ));
	new slot		= GetEmptySlot();
	
	if ( IsValidInfected( client ) && IsValidClient( attacker ) && slot != -1 )
	{
		if (( GetEntProp( client, Prop_Send, "m_zombieClass") == 8 && LUCKY_TANK_DROP == 0 ) || ( IsFakeClient( attacker ) && LUCKY_BOT_DROP == 0 ))
		{
			return;
		}
		
		new drop = true;
		decl Float:infPos[3];
		decl Float:surPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", infPos );
		
		for ( new i = 1; i <= MaxClients; i ++ )
		{
			if ( IsValidClient( i ))
			{
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", surPos );
				if ( GetVectorDistance( infPos, surPos ) <= 70.0 )
				{
					drop = false;
					break;
				}
			}
		}

		if ( drop )
		{
			if ( GetRandomInt( 0, 100 ) <= 40 )
			{
				DropItemLucky( client, LUMA_MDL, slot );
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsValidPlayer(i))
					{
						if(GetClientTeam(i) == 2)
						{
							PrintHintText(i, "天降礼物盒子，赶紧去抢！！！");
						}
					}	
				}					
			}
		}
	}
}


DropItemLucky( client, const String:Model[], slotNumber )
{
	if ( !StrEqual( Model, "random", false ))
	{
		if ( !IsModelPrecached( Model ))
		{
			PrecacheModel( Model );
		}
	}
	
	g_ItemSlot[slotNumber] = CreateEntityByName( "prop_dynamic_override" );
	if ( g_ItemSlot[slotNumber] != -1 )
	{
		new Float:life = g_ItemStay;
		if ( life > 300.0 ) life = 300.0;
		if ( life < 10.0 ) life = 10.0;
		
		g_ItemLimitLife[slotNumber] = life;
		
		new Float:vecPos[3];
		GetEntPropVector( client, Prop_Send, "m_vecOrigin", vecPos );
		vecPos[2] += 20.0;
	
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fademindist", 10000.0);
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fademaxdist", 20000.0);
		DispatchKeyValueFloat( g_ItemSlot[slotNumber], "fadescale", 0.0); 
		
		
		DispatchKeyValue( g_ItemSlot[slotNumber], "model", Model );
		DispatchSpawn( g_ItemSlot[slotNumber] );

		g_ItemLife[slotNumber] = CreateTimer( 0.1, Timer_ItemLifeSpawn, g_ItemSlot[slotNumber], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );

		SetEntProp( g_ItemSlot[slotNumber], Prop_Send, "m_CollisionGroup", 1 ); 
		ToggleGlowEnable( g_ItemSlot[slotNumber], true );
		TeleportEntity( g_ItemSlot[slotNumber], vecPos, NULL_VECTOR, NULL_VECTOR);
	}
}


public Action:Timer_ItemLifeSpawn( Handle:timer, any:index )
{
	new id = GetIndex( index );
	g_ItemLimitLife[id] -= 0.1;

	if ( IsValidEntity( index ) && g_ItemLimitLife[id] > 0.1 )
	{
		RotateAdvance( index, 10.0, 1 );
		
		decl Float:myPos[3];
		decl Float:hePos[3];
		GetEntPropVector( index, Prop_Send, "m_vecOrigin", myPos );
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ))
			{
				if ( IsFakeClient( i ))
				{
					continue;
				}
				
				GetEntPropVector( i, Prop_Send, "m_vecOrigin", hePos );
				if ( GetVectorDistance( myPos, hePos ) < 50.0 )
				{
					decl String:moName[256];
					GetEntPropString( index, Prop_Data, "m_ModelName", moName, sizeof( moName ));
					ToggleGlowEnable( index, false );
					RewardPicker( i, index );
					Item_Destroy( index );
					break;
				}
			}
		}
	}
	else
	{
		if ( g_ItemLife[id] != INVALID_HANDLE )
		{
			KillTimer( g_ItemLife[id] );
			g_ItemLife[id] = INVALID_HANDLE;
		}
		g_ItemSlot[id] = -1;
		
		if ( IsValidEntity( index ))
		{
			ToggleGlowEnable( index, false );
			Item_Destroy( index );
		}
		return Plugin_Stop;
	}
	//PrintToChatAll(" Item Spining");
	return Plugin_Continue;
}

RewardPicker( client, ent )
{
	if ( IsValidClient( client ))
	{
		decl String:mName[256];
		GetEntPropString( ent, Prop_Data, "m_ModelName", mName, sizeof(mName));

		if ( StrEqual( mName, LUMA_MDL, false))
		{
			DropRandomWeapon1( client );
		}
	}
}
DropRandomWeapon1( client )
{
	if ( IsValidClient( client ))
	{
		new rewardmoney;
		new Chose;
		new NoZeroItemCount=0;
		new NoZeroZBItem[ITEM_ZB_MAX];
		new rewardrandom = GetRandomInt(0, 100);
		new s_lv = GetTeamLvCount(2, 1);
		if(rewardrandom <= 5 && s_lv >= 3){
			for(new i = 0; i < ITEM_ZB_MAX -1; i++)
			{
				if(Item_ZB_Radio[i] > 0.0)
				{
					NoZeroZBItem[NoZeroItemCount]=i;
					NoZeroItemCount++;
				}
			}
			Chose = GetRandomInt(0, NoZeroItemCount - 1);
			Chose = NoZeroZBItem[Chose];
			GivePlayerItems(client, "item", Chose);
		}else if(rewardrandom <= 20)	{
			rewardmoney = GetRandomInt(1, 3);
			GivePlayerItems(client, "honor", rewardmoney);
		}else if(rewardrandom > 20 && rewardrandom <= 25){
			rewardmoney = GetRandomInt(1, 1);
			GivePlayerItems(client, "bossxy", rewardmoney);
		}else if(rewardrandom > 25 && rewardrandom <= 60){
			rewardmoney = GetRandomInt(300, 800);
			GivePlayerItems(client, "money", rewardmoney);
		}else if(rewardrandom > 60 && rewardrandom <= 70){
			rewardmoney = GetRandomInt(200, 500);
			GivePlayerItems(client, "jingyan", rewardmoney);
		}else{
			GivePlayerItems(client, "random", 0);
		}
	}
}

GivePlayerItems( client, const String:item[], money)
{
	if ( IsValidClient( client ))
	{
		if(IsValidPlayer(client))
		{
			EmitSoundToClient( client, REWARD_SOUND );
			if(StrEqual(item, "item", false))
			{
				if(money > 0 && money <= ITEM_ZB_MAX)
				{
					SetZBItemTime(client, money, 1, true, false);
					AttachParticle1(client, "achieved", 10.0);
					CPrintToChatAll("\x03[盒子]\x05 %N \x03捡到了一个宝箱,幸运的获得\x04%s[1天]\x03装备!", client, ItemName_ZB[money]);
				}
			}else if(StrEqual(item, "money", false)){
				if(money > 0)
				{
					Cash[client]+=money;
					AttachParticle1(client, "achieved", 10.0);
					CPrintToChatAll("\x03[盒子]\x05%N\x03捡到了一个宝箱,获得了\x04%d$\x03金币!", client, money);
				}
			}else if(StrEqual(item, "honor", false)){
				if(money > 0)
				{
					Qhs[client] +=money;
					AttachParticle1(client, "achieved", 10.0);
					CPrintToChatAll("\x03[盒子]\x05 %N \x03捡到了一个宝箱,获得了\x04 %d个 \x03强化石!", client, money);
				}
			}else if(StrEqual(item, "bossxy", false)){
				if(money > 0)
				{
					BSXY[client] +=money;
					AttachParticle1(client, "achieved", 20.0);
					CPrintToChatAll("\x03[盒子]\x05 %N \x03捡到了一个宝箱,获得了\x04 %d个 \x03boss的心愿!", client, money);
				}
			}else if(StrEqual(item, "jingyan", false)){
				if(money > 0)
				{
					EXP[client] +=money;
					AttachParticle1(client, "achieved", 10.0);
					CPrintToChatAll("\x03[盒子]\x05 %N \x03捡到了一个宝箱,获得了\x04 %d点的经验书", client, money);
				}
			}else{
				new random = GetRandomInt(1, 4);
				switch(random)
				{
					case 1:
					{
						CheatCommand(client, "give", "vomitjar");
						CPrintToChatAll("\x03[盒子]\x05%N\x03捡到了一个宝箱,获得了\x04 一瓶boomer的呕吐物!", client);
					}
					case 2:
					{
						RewardTeleport(client, "tank");
					}
					case 3:
					{
						new Float:_pos[3];
						GetClientAbsOrigin(client, _pos);
						LittleFlower(_pos, EXPLODE, client);
						CPrintToChatAll("\x01[礼盒]\x04%N\x01捡到了一个宝箱,\x04打开盒子被炸弹坑了", client);
					}
					case 4:
					{
						new Float:_pos[3];
						GetClientAbsOrigin(client, _pos);
						FreezePlayer(client,  _pos, 3.0);
						CPrintToChatAll("\x01[礼盒]\x04%N\x01捡到了一个宝箱,\x04被冰冻3秒，看你还抢不抢。[人品不行]", client);
					}
				}
			}
		}
	}
}

GetEmptySlot()
{
	new max = LuckyMax;
	if ( max >= SLOT_NUM ) max = SLOT_NUM - 1;
	if ( max < 1 ) max = 1;
	
	for( new i = 0; i <=  max; i++ )
	{
		if ( g_ItemSlot[i] == -1 )
		{
			return i;
		}
	}
	return -1;
}
/*
GetEmptyWepon()
{
	for( new i = 0; i < WEPN_NUM; i++ )
	{
		if ( g_WepnSlot[i] == -1 )
		{
			return i;
		}
	}
	return -1;
}
*/
GetIndex( index )
{
	new max = LuckyMax;
	if ( max >= SLOT_NUM ) max = SLOT_NUM - 1;
	if ( max < 1 ) max = 1;
	
	for( new i = 0; i <=  max; i++ )
	{
		if ( index == g_ItemSlot[i] )
		{
			return i;
		}
	}
	return -1;
}
stock RotateAdvance( index, Float:value, axis )
{
	if ( IsValidEntity( index ))
	{
		decl Float:rotate_[3];
		GetEntPropVector( index, Prop_Data, "m_angRotation", rotate_ );
		rotate_[axis] += value;
		TeleportEntity( index, NULL_VECTOR, rotate_, NULL_VECTOR);
	}
}

RewardTeleport( client, const String:who[] )
{
	if ( IsValidClient( client ))
	{
		if ( StrContains( curMap, "c5m2", false ) != -1 )
		{
			if ( StrEqual( who, "Witch", false ) || StrEqual( who, "Tank", false ))
			{
				EmitSoundToClient( client, REWARD_SOUND );
				CPrintToChatAll("\x03[礼物]\x05%N\x03倒霉孩子踩到了一坨屎!", client);
				return;
			}
		}
		
		new other = FindTeleportEntity( client, who );
		if ( other != 0 )
		{
			EmitSoundToClient( client, TELEPOT_SOUND );
			TeleportMeTo( client, other );
			CPrintToChatAll( "\x03[提示]\x05%N\x03真幸运!! 获得了\x04%s\x03传送.", client, who );
		}
	}
}

stock FindTeleportEntity( client, const String:_findWhatTele[] )
{
	new scan = 0;
	if ( StrEqual( _findWhatTele, "Tank", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidInfected( i ) && IsPlayerAlive( i ))
			{
				if ( GetEntProp( i, Prop_Send, "m_zombieClass") == 8 )
				{
					scan = i;
					break;
				}
			}
		}
	}
	else if ( StrEqual( _findWhatTele, "Witch", false ))
	{
		decl String:_name[64];
		new _max	= GetEntityCount();
		for ( new i = MaxClients; i <= _max; i++ )
		{
			if ( IsValidEntity( i ))
			{
				GetEdictClassname( i, _name, sizeof( _name ));
				if ( StrContains( _name, "witch", false) != -1 )
				{
					if ( GetEntProp( i, Prop_Data, "m_iHealth" ) > 1 )
					{
						scan = i;
						break;
					}
				}
			}
		}
	}
	else if ( StrEqual( _findWhatTele, "Survivor", false ))
	{
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsValidClient( i ) && i != client )
			{
				scan = i;
				break;
			}
		}
	}
	return scan;
}

stock TeleportMeTo( caller, subject )
{
	if ( IsValidClient( caller ))
	{
		decl Float:_location[3];
		GetEntPropVector( subject, Prop_Send, "m_vecOrigin", _location );
		_location[2] += 5.0;
		TeleportEntity( caller, _location, NULL_VECTOR, NULL_VECTOR );
		EmitSoundToClient( caller, TELEPOT_SOUND );
	}
}

ToggleGlowEnable( entity, bool:on=false )
{
	if ( IsValidEntity( entity ))
	{
		new m_iGlowType	= 0;
		new m_glowColor	= 0;
		
		if ( on )
		{
			new select;
			new glowType = 1;
			if ( glowType > 0 && glowType <= 6 )
			{
				m_iGlowType = 3;
				new colorRGB[3] = { 0, 0, 0 };
				
				if ( glowType == 6 ) select = GetRandomInt( 1, 5 );
				else select = glowType;
				
				switch( select )
				{
					case 1:
					{
						colorRGB[1] = 128;
						colorRGB[2] = 255;
					}
					case 2:
					{
						colorRGB[0] = 255;
						colorRGB[2] = 255;
					}
					case 3:
					{
						colorRGB[0] = 255;
						colorRGB[1] = 255;
					}
					case 4:
					{
						colorRGB[0] = 255;
					}
					case 5:
					{
						colorRGB[2] = 255;
					}
				}
				m_glowColor = colorRGB[0] + ( colorRGB[1] * 256 ) + ( colorRGB[2] * 65536 );
			}
			else
			{
				m_glowColor = 0;
			}
		}
		SetEntProp( entity, Prop_Send, "m_iGlowType", m_iGlowType );
		SetEntProp( entity, Prop_Send, "m_nGlowRange", 0 );
		SetEntProp( entity, Prop_Send, "m_glowColorOverride", m_glowColor );
	}
}

stock Item_Destroy( entity )
{
	if ( entity != -1 && IsValidEntity( entity ))
	{
		decl Float:desPos[3];
		GetEntPropVector( entity, Prop_Send, "m_vecOrigin", desPos );

		desPos[2] += 5000.0;
		
		TeleportEntity( entity, desPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput( entity, "Kill" );
	}
}

stock bool:IsValidInfected( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 3 ) return false;
	return true;
}

stock bool:IsValidClient( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	if ( !IsPlayerAlive( client )) return false;
	return true;
}

/*
public EVENT_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	//if ( GetConVarInt( g_LuffyEnable ) == 0 ) return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidClient( client ))
	{
		decl String:NamePuckUp[128];
		
		new item = GetEventInt( event, "targetid" );
		for ( new i = 0; i < WEPN_NUM; i++ )
		{
			if ( g_WepnSlot[i] == item )
			{
				
				GetEdictClassname( item, NamePuckUp, sizeof( NamePuckUp ));
				if ( StrEqual( NamePuckUp, "upgrade_laser_sight", false ) || StrEqual( NamePuckUp, "weapon_ammo_spawn", false ))
				{
					ToggleGlowEnable( item, false );
					Item_Destroy( item );
				}
				else
				{
					RestockAmmo( client, NamePuckUp, item );
				}
				
				item = -1;
				g_WepnSlot[i] = -1;
				break;
			}
		}
	}
}
*/