/************************************************************************
*	Bot功能
************************************************************************/

//玩家进入游戏,创建一个bot
public Action:GiveBotClient(Handle:timer, any:client)
{
	if (!IsClientConnected(client) || IsFakeClient(client))
		return;
		
	new surv_l = GetConVarInt(cv_survivor_limit);
	KickAllDeathFakeClient();
	if (IsValidPlayer(client, false))
	{
		if (CountPlayersTeam(2, true) < surv_l)
		{
			if (GetBotCount() < 1)
				SpawnFakeClient(), CreateTimer(0.1, ClientTakeTheBot, client, TIMER_REPEAT);
			else
				CreateTimer(0.1, ClientTakeTheBot, client, TIMER_REPEAT);
		}
		else
			CreateTimer(0.1, ClientTakeTheBot, client, TIMER_REPEAT);
			
		KillTimer(timer);
	}
}

public GetNotBotCount()
{
	new count;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			count++;
	}
	
	return count;
}

public GetBotCount()
{
	new count;
	KickAllDeathFakeClient();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			count++;
	}
	
	return count;
}

//踢出一个电脑bot
public KickFakeClient()
{
	for (new i =1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			KickClient(i, "kick");
			break;
		}
	}
}

//踢出所有电脑bot
public KickAllFakeClient()
{
	for (new i =1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			KickClient(i, "kick");
	}
}

//踢出所有死亡电脑bot
public KickAllDeathFakeClient()
{
	for (new i =1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
			KickClient(i, "kick");
	}
}

//回合开始清理电脑bot
public Action:RoundStartKickAllBot(Handle:timer)
{
	new fake;
	new notfake;
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			fake++;
		else if (IsValidPlayer(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			notfake++;
	}
		
	if (fake > 0 && notfake > 0 && fake + notfake > 4)
		KickAllFakeClient();
	else if (notfake > 0 && fake < 1)
	{
		KillTimer(Handle_BotTimer);
		Handle_BotTimer = INVALID_HANDLE;	
	}
}

//给予玩家电脑
public Action:ClientTakeTheBot(Handle:timer, any:client)
{	
	if (IsValidPlayer(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) != 2)
			ChangeTeam(client, 2);
		
		KickAllFakeClient();
		KillTimer(timer);
	}
}


//创建电脑bot
public SpawnFakeClient()
{
	new Bot = CreateFakeClient("SurvivorBot");
	new Float:pos[3];
	
	if (!IsValidPlayer(Bot))
		return;
		
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (IsFakeClient(i))
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos), TeleportEntity(Bot, pos, NULL_VECTOR, NULL_VECTOR);
			else
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos), TeleportEntity(Bot, pos, NULL_VECTOR, NULL_VECTOR);
				
			break;
		}
	}
	
	if (IsFakeClient(Bot))
		KickClient(Bot, "Kicking Fake Client.");
}

//管理员_创建电脑bot
public Admin_SpawnFakeClient(Client)
{
	new Bot = CreateFakeClient("SurvivorBot");
	new Float:pos[3];
	
	if (!IsValidPlayer(Bot) || !IsValidPlayer(Client))
		return;
		
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	
	GetEntPropVector(Client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(Bot, pos, NULL_VECTOR, NULL_VECTOR);
	
	if (IsFakeClient(Bot))
		KickClient(Bot, "Kicking Fake Client.");
}