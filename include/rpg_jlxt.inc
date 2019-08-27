/************************************************************************
*	精灵系统
************************************************************************/

//精灵背包
public Action:Menu_MYJL(Client,args)
{
	MenuFunc_JLBAG(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_JLBAG(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:ZBEET[16];	   
	if(JLXT1[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "无精灵");   
	else if(JLXT1[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "水灵[精灵]");
	   
	decl String:ZBXXT[16];	   
	if(JLXT2[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "无精灵");   
	else if(JLXT2[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "时空[精灵]");
   
	decl String:ZBNNT[16];	  
	if(JLXT3[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "无精灵");  
	else if(JLXT3[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "枪师[精灵]");
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"═══[J键]精灵背包═══ \n %s \n %s \n %s ", ZBEET, ZBXXT, ZBNNT);    
	SetPanelTitle(menu, line);	   	
	
	Format(line, sizeof (line), "进入精灵商店");  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "使用精灵技能");  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "恢复精灵");  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "精灵系统介绍");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回RPG菜单");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_JLBAG, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_JLBAG(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:MenuFunc_JRSD(Client);
			case 2:MenuFunc_SYJLJN(Client);
			case 3:MenuFunc_HFJL(Client);
			case 4:MenuFunc_JLXTJS(Client);
			case 5:MenuFunc_RPG(Client);
		}
	}
}

//精灵系统说明
public Action:MenuFunc_JLXTJS(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "精灵系统说明:\n精灵系统是我们特意开发的一款系统 \n玩家可以用精灵来恢复自己的MP或者HP等 \n不过精灵需要购买才能获得\n还要给精灵吃体力药水.");
	DrawPanelText(menu, line);
	
	Format(line, sizeof (line), "水灵精灵介绍");  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "时空精灵介绍");  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "枪师精灵介绍");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_JLXTJS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_JLXTJS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 4: MenuFunc_JLBAG(Client); //精灵背包
			case 1: MenuFunc_JL1JS(Client); //
			case 2: MenuFunc_JL2JS(Client); //
			case 3: MenuFunc_JL3JS(Client); //
		}
	}
}

//水灵介绍
public Action:MenuFunc_JL1JS(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "水灵精灵说明:\n扣除相应的体力来恢复主人血量和MP\n售价是:120000永久.");
	DrawPanelText(menu, line);
	
	Format(line, sizeof (line), "购买水灵");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_JL1JS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_JL1JS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 2: MenuFunc_JLXTJS(Client); //精灵背包
			case 1: MenuFunc_GMSL(Client);//购买水灵
		}
	}
}

//时空介绍
public Action:MenuFunc_JL2JS(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "时空精灵说明:\n扣除相应的体力来帮助主人到达终点或者起点\n售价是:1500000永久.");
	DrawPanelText(menu, line);
	
	Format(line, sizeof (line), "购买时空");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_JL2JS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_JL2JS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 2: MenuFunc_JLXTJS(Client); //精灵背包
			case 1: MenuFunc_GMSK(Client);//购买时空
		}
	}
}

//枪师介绍
public Action:MenuFunc_JL3JS(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	
	Format(line, sizeof(line), "枪师精灵说明:\n扣除相应的体力获得枪支\n售价是:140000永久.");
	DrawPanelText(menu, line);
	
	Format(line, sizeof (line), "购买枪师");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_JL3JS, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}
public MenuHandler_JL3JS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 2: MenuFunc_JLXTJS(Client); //精灵背包
			case 1: MenuFunc_GMQS(Client);//购买枪师
		}
	}
}

//使用精灵技能
public Action:MenuFunc_SYJLJN(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【使用精灵技能】");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "使用精灵技能!");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "极品戒指停止购买");
    //DrawPanelItem(menu, line);
	Format(line, sizeof(line), "使用精灵水灵技能");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "使用精灵时空技能");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "使用精灵枪师技能");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_SYJLJN, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_SYJLJN(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: 
			{
                if(JLXT1[Client] == 1)
                {
                    MenuFunc_SJLN(Client);
                } else PrintHintText(Client, "【提示】你没有水灵精灵无法进入!");
			}
			case 2: 
			{
                if(JLXT2[Client] == 1)
                {
                    MenuFunc_SKJL(Client);
                } else PrintHintText(Client, "【提示】你没有时空精灵无法进入!");
			}
			case 3: 
			{
                if(JLXT3[Client] == 1)
                {
                    MenuFunc_QSJN(Client);
                } else PrintHintText(Client, "【提示】你没有枪师精灵无法进入!");
			}
			case 4: MenuFunc_JLBAG(Client);
		}
	}
}

public Action:MenuFunc_QSJN(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【枪师技能】\n当前体力:%d点", JLXT6[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "枪师的技能!");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "极品戒指停止购买");
    //DrawPanelItem(menu, line);
	Format(line, sizeof(line), "获得榴弹发射器[-4点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得AK47[-2点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得战术散弹[-2点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得M16[-2点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得沙漠之鹰[-3点体力]");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回技能背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_QSJN, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_QSJN(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			//case 1: VIPJPJZ(Client);
			case 1: HDLD(Client);
			case 2: HDAK(Client);
			case 3: HDSD(Client);
			case 4: HDM16(Client);
			case 5: HDSMZY(Client);
			case 6: MenuFunc_SYJLJN(Client);
		}
	}
}

//public VIPJPJZ(Client)//戒指
//{   
	//if(Qcash[Client] >= 0)    
	//{       
		//Qcash[Client] -= 0;		
		//ServerCommand("set_setitem \"%N\" \"1\" \"5\" \"15\"", Client);       
		//CPrintToChat(Client, "\x03[系统]\04%N本商品\x05停止购买!", Client);	    
	//} else CPrintToChat(Client, "{green}【提示】你没有足够的求生币!");
//}
public HDLD(Client)//鞋子
{   
	if(JLXT6[Client] >= 4)    
	{         
		JLXT6[Client] -= 4;		
		CheatCommand(Client, "give", "weapon_grenade_launcher");	
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己获得榴弹发射器！");		  
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_QSJN(Client)
}

public HDAK(Client)//血盾
{   
	if(JLXT6[Client] >= 2)    
	{       
		JLXT6[Client] -= 2;		
		CheatCommand(Client, "give", "rifle_ak47");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己获得了AK47!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_QSJN(Client)
}

public HDSD(Client)//血盾
{   
	if(JLXT6[Client] >= 2)    
	{       
		JLXT6[Client] -= 2;		
		CheatCommand(Client, "give", "autoshotgun");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己获得了战术散弹!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_QSJN(Client)
}

public HDM16(Client)//血盾
{   
	if(JLXT6[Client] >= 2)    
	{       
		JLXT6[Client] -= 2;		
		CheatCommand(Client, "give", "rifle");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己获得了M16!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_QSJN(Client)
}

public HDSMZY(Client)//血盾
{   
	if(JLXT6[Client] >= 3)    
	{       
		JLXT6[Client] -= 3;		
		CheatCommand(Client, "give", "pistol_magnum");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己获得了沙漠之鹰!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_QSJN(Client)
}


public Action:MenuFunc_SKJL(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【时空技能】\n当前体力:%d点", JLXT7[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "时空的技能!");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "极品戒指停止购买");
    //DrawPanelItem(menu, line);
	Format(line, sizeof(line), "直接到终点[-50点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "回到起点[-13点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "全体召唤[-10点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "召唤队友[-8点体力]");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回技能背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_SKJL, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_SKJL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			//case 1: VIPJPJZ(Client);
			case 1: ZJDZD(Client);
			case 2: HDSS(Client);
			case 3: QTZHSS(Client);
			case 4: DYZY(Client);
			case 5: MenuFunc_SYJLJN(Client);
		}
	}
}

//public VIPJPJZ(Client)//戒指
//{   
	//if(Qcash[Client] >= 0)    
	//{       
		//Qcash[Client] -= 0;		
		//ServerCommand("set_setitem \"%N\" \"1\" \"5\" \"15\"", Client);       
		//CPrintToChat(Client, "\x03[系统]\04%N本商品\x05停止购买!", Client);	    
	//} else CPrintToChat(Client, "{green}【提示】你没有足够的求生币!");
//}
public ZJDZD(Client)//鞋子
{   
	if(JLXT7[Client] >= 50)    
	{         
		JLXT7[Client] -= 50;		
		CheatCommand(Client, "warp_all_survivors_to_checkpoint", "");	
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己直接到达终点！");		  
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SKJL(Client)
}

public HDSS(Client)//血盾
{   
	if(JLXT7[Client] >= 13)    
	{       
		JLXT7[Client] -= 13;		
		CheatCommand(Client, "warp_to_start_area", "");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让自己回到了起点!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SKJL(Client)
}

public QTZHSS(Client)//血盾
{   
	if(JLXT7[Client] >= 10)    
	{       
		JLXT7[Client] -= 10;		
		CheatCommand(Client, "warp_all_survivors_here", "");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量让队友回到身边!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SKJL(Client)
}

public DYZY(Client)//血盾
{   
	if(JLXT7[Client] >= 8)    
	{       
		JLXT7[Client] -= 8;		
		CheatCommand(Client, "warp_far_survivor_here", "");				
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量召唤了一位队友!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SKJL(Client)
}

public Action:MenuFunc_SJLN(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【水灵技能】\n当前体力:%d点", JLXT5[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "水灵的技能!");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "极品戒指停止购买");
    //DrawPanelItem(menu, line);
	Format(line, sizeof(line), "恢复所有血量[-10点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "恢复所有MP[-20点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得医疗包[-4点体力]");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "获得电击器[-8点体力]");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回技能背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_SJLN, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_SJLN(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			//case 1: VIPJPJZ(Client);
			case 1: HFXL(Client);
			case 2: HFMP(Client);
			case 3: HDYB(Client);
			case 4: HDDJ(Client);
			case 5: MenuFunc_SYJLJN(Client);
		}
	}
}

//public VIPJPJZ(Client)//戒指
//{   
	//if(Qcash[Client] >= 0)    
	//{       
		//Qcash[Client] -= 0;		
		//ServerCommand("set_setitem \"%N\" \"1\" \"5\" \"15\"", Client);       
		//CPrintToChat(Client, "\x03[系统]\04%N本商品\x05停止购买!", Client);	    
	//} else CPrintToChat(Client, "{green}【提示】你没有足够的求生币!");
//}
public HFXL(Client)//鞋子
{   
	if(JLXT5[Client] >= 10)    
	{         
		JLXT5[Client] -= 10;		
		CheatCommand(Client, "give", "health");	
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量恢复自身所有HP！");		  
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SJLN(Client)
}

public HFMP(Client)//血盾
{   
	if(JLXT5[Client] >= 20)    
	{       
		JLXT5[Client] -= 20;		
		MP[Client] = MaxMP[Client]; 			
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量恢复自身所有MP!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SJLN(Client)
}

public HDYB(Client)//血盾
{   
	if(JLXT5[Client] >= 4)    
	{       
		JLXT5[Client] -= 4;		
		CheatCommand(Client, "give", "first_aid_kit");		
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量获得一个医药包!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SJLN(Client)
}

public HDDJ(Client)//血盾
{   
	if(JLXT5[Client] >= 8)    
	{       
		JLXT5[Client] -= 8;		
		CheatCommand(Client, "give", "defibrillator");		
		CPrintToChat(Client,"\x03[系统]\04你\x04发动了精灵能量获得一个电击器!");
	} else CPrintToChat(Client, "\x05【提示】你的精灵没有足够的体力!");
	MenuFunc_SJLN(Client)
}

//恢复精灵
public Action:MenuFunc_HFJL(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024];
	Format(line, sizeof(line), "【恢复精灵】\n当前拥有药水:%d", JLXT4[Client]);
	SetPanelTitle(menu, line);
	Format(line, sizeof(line), "恢复精灵!");
	DrawPanelText(menu, line);
	//Format(line, sizeof(line), "极品戒指停止购买");
    //DrawPanelItem(menu, line);
	Format(line, sizeof(line), "恢复精灵水灵1瓶体力药水");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "恢复精灵时空1瓶体力药水");
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "恢复精灵枪师1瓶体力药水");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回精灵背包");
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_HFJL, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public MenuHandler_HFJL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			//case 1: VIPJPJZ(Client);
			case 1: HFSL(Client);
			case 2: HFSK(Client);
			case 3: HFQS(Client);
			case 4: MenuFunc_JLBAG(Client);
		}
	}
}

//public VIPJPJZ(Client)//戒指
//{   
	//if(Qcash[Client] >= 0)    
	//{       
		//Qcash[Client] -= 0;		
		//ServerCommand("set_setitem \"%N\" \"1\" \"5\" \"15\"", Client);       
		//CPrintToChat(Client, "\x03[系统]\04%N本商品\x05停止购买!", Client);	    
	//} else CPrintToChat(Client, "{green}【提示】你没有足够的水晶币!");
//}
public HFSL(Client)//鞋子
{   
	if(JLXT4[Client] >= 1 && JLXT1[Client] == 1)    
	{         
		JLXT5[Client] += 100;		
		JLXT4[Client] -= 1;	
		CPrintToChat(Client,"\x03[系统]\04你\x04恢复了精灵水灵100点体力!");		  
	} else CPrintToChat(Client, "\x05【提示】你没有体力药水或者你没有这个精灵");
	MenuFunc_HFJL(Client)
}

public HFSK(Client)//血盾
{   
	if(JLXT4[Client] >= 1 && JLXT2[Client] == 1)    
	{       
		JLXT7[Client] += 100;			
		JLXT4[Client] -= 1; 		
		CPrintToChat(Client,"\x03[系统]\04你\x04恢复精灵时空100点体力!");		  	    
	} else CPrintToChat(Client, "\x05【提示】你没有体力药水或者你没有这个精灵!");
	MenuFunc_HFJL(Client)
}

public HFQS(Client)//风衣
{   
	if(JLXT4[Client] >= 1 && JLXT3[Client] == 1)    
	{       
		JLXT6[Client] += 100;			
		JLXT4[Client] -= 1;   	
		CPrintToChat(Client,"\x03[系统]\04你\x04恢复精灵枪师100点体力!");		      
	} else CPrintToChat(Client, "\x05【提示】你没有体力药水或者你没有这个精灵!");
	MenuFunc_HFJL(Client)
}


/* 精灵商店 */
public Action:MenuFunc_JRSD(Client)
{    
	new Handle:menu = CreatePanel();
	   
	decl String:line[1024];	   
	Format(line, sizeof(line), "【精灵商店】\n拥有的求生币:%d个", Qcash[Client]);   
	SetPanelTitle(menu, line);   
	
	Format(line, sizeof(line), "购买精灵专区!");    
	DrawPanelText(menu, line);
    
	Format(line, sizeof(line), "购买精灵水蓝");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "购买精灵时空");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "购买精灵枪师");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "购买体力药水");
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回精灵背包");    	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	SendPanelToClient(menu, Client, MenuHandler_JRSD, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_JRSD(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_GMSL(Client);
			case 2: MenuFunc_GMSK(Client);
			case 3: MenuFunc_GMQS(Client);
			case 4: MenuFunc_GMTL(Client);
			case 5: MenuFunc_JLBAG(Client);
		}
	}
}

/* 购买体力药水 */
public Action:MenuFunc_GMTL(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【购买体力药水】\n拥有的金币:%d个", Cash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "购买体力药水可恢复100点体力\n所需50000个金币!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回精灵购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_GMTL, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_GMTL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: GMTL(Client);
			case 2: MenuFunc_JRSD(Client);
		}
	}
}

public GMTL(Client)
{
    if(Cash[Client] >= 50000)
    {
        Cash[Client] -= 50000;
        JLXT4[Client] += 1;
        CPrintToChat(Client, "\x03【系统】你成功购买了体力药水 当前金币%d!", Cash[Client]);	   CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临0(*^__^*)0!");
    } else CPrintToChat(Client, "\x03【提示】你没有足够的金币!");
}

/* 购买精灵水蓝 */
public Action:MenuFunc_GMSL(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【购买精灵水蓝】\n拥有的金币:%d个", Cash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "购买精灵水蓝\n所需120000个金币!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回精灵购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_GMSL, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_GMSL(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: GMGMSL(Client);
			case 2: MenuFunc_JRSD(Client);
		}
	}
}

public GMGMSL(Client)
{
    if(Qcash[Client] >= 120000 && JLXT1[Client] == 0)
    {
        Cash[Client] -= 120000;
        JLXT1[Client] += 1;
        CPrintToChat(Client, "\x03【系统】你成功购买了精灵水灵 当前金币%d!", Cash[Client]);	   CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临0(*^__^*)0!");
    } else CPrintToChat(Client, "\x03【提示】你没有足够的求生币或者你有了这个精灵!");
}

/* 购买精灵时空 */
public Action:MenuFunc_GMSK(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【购买精灵时空】\n拥有的求金币:%d个", Cash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "购买精灵时空！\n所需金币:150000!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回精灵购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_GMSK, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_GMSK(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: GMGMSK(Client);
			case 2: MenuFunc_JRSD(Client);
		}
	}
}

public GMGMSK(Client)
{   
	if(Qcash[Client] >= 150000 && JLXT2[Client] == 0)    
	{       
		Cash[Client] -= 150000;		
		JLXT2[Client] += 1;		
		CPrintToChat(Client, "\x03【提示】你成功购买精灵时空! 当前剩余金币:%d", Cash[Client]);	   CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临0(*^__^*)0!");		 
	} else CPrintToChat(Client, "\x03【提示】你没有足够的求生币或者你已经有了这个精灵!");
}

/* 购买精灵枪师 */
public Action:MenuFunc_GMQS(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【购买精灵枪师】\n拥有的金币:%d个", Cash[Client]);
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "购买精灵枪师\n所需金币:160000!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认购买");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回精灵购买");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_GMQS, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_GMQS(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: GMMGMQS(Client);
			case 2: MenuFunc_JRSD(Client);
		}
	}
}

public GMMGMQS(Client)
{   
	if(Qcash[Client] >= 160000 && JLXT3[Client] == 0)    
	{       
		Cash[Client] -= 160000;		
		JLXT3[Client] += 1;			
		CPrintToChat(Client, "\x03【提示】你成功购买购买精灵枪师! 当前剩余金币:%d", Cash[Client]);	   CPrintToChat(Client,"\x03[系统]\x04欢迎您下次光临0(*^__^*)0!");		 
	} else CPrintToChat(Client, "\x03【提示】你没有足够的求生币或者你已经有了这个精灵!");
}






