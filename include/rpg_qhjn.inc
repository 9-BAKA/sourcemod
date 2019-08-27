//强化系统
public Action:MenuFunc_Qhsx(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "==============强化技能系统==========");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line),"说明:强化技能强化1次需要1个强化石和10万元手术费");
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"物品：【强化石】目前拥有：%d个", Qhs[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"材料：【BOSS心愿】目前拥有：%d个", BSXY[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"=================================");
	DrawPanelText(menu, line);
	if(GetClientTeam(Client) == 2)
	{
		if (VIP[Client] <= 0)
			Format(line, sizeof(line), "[强化]治疗术 (强化Lv.%d )", Sxqh[Client]);
		else
			Format(line, sizeof(line), "[强化]高级治疗术 (强化Lv.%d )", Sxqh[Client]);
		DrawPanelItem(menu, line);
		Format(line, sizeof(line), "[强化]地震术 (强化Lv.%d )", Qhdz[Client]);
		DrawPanelItem(menu, line);
		if(JD[Client] == 1)
		{
			Format(line, sizeof(line), "[强化]卫星炮术 (强化Lv.%d )", Qhwx[Client]);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 2)
		{
			Format(line, sizeof(line), "[强化]加速冲刺术 (强化Lv.%d )", Qhjs[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[强化]无限子弹术 (强化Lv.%d )", Qhzd[Client]);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 3)
		{
			Format(line, sizeof(line), "[强化]无敌术 (强化Lv.%d )", Qhwd[Client]);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 4)
		{
			Format(line, sizeof(line), "[强化]审判光球术 (强化Lv.%d )", Qhsp[Client]);
			DrawPanelItem(menu, line);				
			Format(line, sizeof(line), "[强化]治疗光球术 (强化Lv.%d )", Qhzl[Client]);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 5)
		{
			Format(line, sizeof(line), "[强化]火球术 (强化Lv.%d )", Qhhq[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[强化]冰球术 (强化Lv.%d )", Qhbq[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[强化]连锁闪电术 (强化Lv.%d )", Qhls[Client]);
			DrawPanelItem(menu, line);
		}
		else if(JD[Client] == 6)
		{
			Format(line, sizeof(line), "[强化]破碎弹 (强化Lv.%d )", Qhps[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[强化]区域爆破 (强化Lv.%d )", Qhsd[Client]);
			DrawPanelItem(menu, line);
			Format(line, sizeof(line), "[强化]吸血弹 (强化Lv.%d )", Qhxx[Client]);
			DrawPanelItem(menu, line);
		}
	}
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Qhsx, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}
 
public MenuHandler_Qhsx(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1:
                if (Qhs[Client] > 0)
			    {
			        MenuFunc_qhhxs(Client);
				}else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 2:
                if (Qhs[Client] > 0)
			    {
			        MenuFunc_qhdzs(Client);
				}else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 3:
                if (Qhs[Client] > 0)
			    {    
			        if(JD[Client] == 1)	MenuFunc_qhwxs(Client);
			        else if(JD[Client] == 2)	MenuFunc_qhjss(Client);
			        else if(JD[Client] == 3)	MenuFunc_qhwds(Client);
			        else if(JD[Client] == 4)	MenuFunc_qhsps(Client);
			        else if(JD[Client] == 5)	MenuFunc_qhhqs(Client);
			        else if(JD[Client] == 6)	MenuFunc_qhpsd(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 4:
                if (Qhs[Client] > 0)
			    {    
			        if(JD[Client] == 2)	MenuFunc_qhwxzds(Client);
			        else if(JD[Client] == 4)	MenuFunc_qhzls(Client);
			        else if(JD[Client] == 5)	MenuFunc_qhbqs(Client);
			        else if(JD[Client] == 6)	MenuFunc_qhsdd(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 5:
                if (Qhs[Client] > 0)
			    {    
			        if(JD[Client] == 5)	MenuFunc_qhlss(Client);
			        else if(JD[Client] == 6)	MenuFunc_qhxxd(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
		}
	}
}

public Action:MenuFunc_psdx(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化失败达到100次可领取补偿");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "领取");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_psdx, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_psdx(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: psdx(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public psdx(Client)
{
    if(Sxcs[Client] > 100)   
	{
	    Sxcs[Client] -= 100;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Cash[Client] += 1000000;
	           PrintHintTextToAll("[安抚]:玩家%N强化失败100次，获得安抚基金100万", Client);           
			}
			case 2:           
			{   
				Cash[Client] += 500000;		
				PrintHintTextToAll("[安抚]:玩家%N强化失败100次，获得安抚基金50万", Client);           
			}
			case 3:           
			{   
				Lv[Client] += 10;			
				PrintHintTextToAll("[安抚]:玩家%N强化失败100次，获得等级10级", Client);           
			}
			case 4:           
			{     
				Lv[Client] += 15;			
				PrintHintTextToAll("[安抚]:玩家%N强化失败100次，获得等级15级", Client);           
			}
			case 5:           
			{    
				Lv[Client] += 20;			
				PrintHintTextToAll("[安抚]:玩家%N强化失败100次，获得等级20级", Client);           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04安抚\x01]\x03：\x05破碎的心愿未达标");
        
}

//强化治疗术
public Action:MenuFunc_qhhxs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化回血：治疗术回血量+强化等级");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhhxs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhhxs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhhxs(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhhxs(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1, WQXT[Client] = 1;  
	    JobChooseBool[Client] = true;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Sxqh[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[治疗术]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

//强化地震术
public Action:MenuFunc_qhdzs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化范围：强化等级*15");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhdzs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhdzs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhdzs(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhdzs(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhdz[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[地震术]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhwxs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*100");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhwxs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhwxs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhwxs(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhwxs(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhwx[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[卫星炮]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhjss(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化时间：强化等级*5");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhjss, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhjss(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhjss(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhjss(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhjs[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[加速冲剂]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhwxzds(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化时间：强化等级*5");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhwxzds, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhwxzds(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhwxzds(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhwxzds(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhzd[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[无限子弹]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhwds(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化时间：强化等级*5");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhwds, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhwds(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhwds(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhwds(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhwd[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[无敌术]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");       
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");      
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhsps(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化半径：强化等级*20");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhsps, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhsps(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhsps(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhsps(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhsp[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[审判光球]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");      
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");      
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhzls(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化半径：强化等级*50");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhzls, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhzls(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhzls(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhzls(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhzl[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[治疗光圈]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");        
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhhqs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*250");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhhqs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhhqs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhhqs(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhhqs(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhhq[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[火球术]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");         
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhbqs(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*150");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhbqs, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhbqs(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhbqs(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhbqs(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhbq[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[冰球术]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");         
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhlss(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化半径：强化等级*30");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhlss, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhlss(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhlss(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhlss(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhls[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[连锁闪电]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhpsd(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*6");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhpsd, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhpsd(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhpsd(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhpsd(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhps[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[破碎弹]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhsdd(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*50");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhsdd, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhsdd(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhsdd(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhsdd(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhsd[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[区域爆破]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

public Action:MenuFunc_qhxxd(Client)
{
	decl String:line[128];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "══════════════════");
	SetPanelTitle(menu, line);

	Format(line, sizeof(line), "强化伤害：强化等级*6");
	DrawPanelText(menu, line);
	Format(line, sizeof(line), "══════════════════");
	DrawPanelText(menu, line);
	DrawPanelItem(menu, "强化");
	DrawPanelItem(menu, "返回");
	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	SendPanelToClient(menu, Client, MenuHandler_qhxxd, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_qhxxd(Handle:menu, MenuAction:action, Client, param)//基础菜单	
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: qhxxd(Client);
			case 2: MenuFunc_Qhsx(Client);
		}
	}
}

public qhxxd(Client)
{
    if(Cash[Client] > 100000)   
	{
	    Cash[Client] -= 100000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           Qhxx[Client] ++;
	           PrintHintTextToAll("玩家[%N]强化[吸血弹]技能成功，大家一起祝贺他吧", Client);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");          
			}
			case 3:           
			{   
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     
				Sxcs[Client] ++			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足");
        
}

/*public Action:MenuFunc_Qhqz(Client)
{
	new ak47 = 5 * AK47[Client] + DMG_AK47;
	new m60 =  5 * M60[Client] + DMG_M60;
	new m16 =  5 * M16[Client] + DMG_M16;
	new spas = 3 * PZ[Client] + DMG_SPAS;
	new awp = 12 * AWP[Client] + DMG_AWP;
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "==============强化技能系统==========");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line),"说明：强化金币5万[当前金币：%d]", Cash[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"物品：【强化石】目前拥有：%d个", Qhs[Client]);
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"=================================");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "M16伤害强化【伤害%d】【强化LV%d】", m16, M16[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "AK47伤害强化【伤害%d】【强化LV%d】", ak47, AK47[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "AWP伤害强化【伤害%d】【强化LV%d】", awp, AWP[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "喷子伤害强化【伤害%d】【强化LV%d】", spas, PZ[Client]);
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "M60伤害强化【伤害%d】【强化LV%d】", m60, M60[Client]);
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_Qhqz, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}
public MenuHandler_Qhqz(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1:
			    if (Qhs[Client] > 0)
			    {  
			        qhm161(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 2:
			    if (Qhs[Client] > 0)
			    {  
			        qhak471(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 3:
			    if (Qhs[Client] > 0)
			    {  
			        qhawp1(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");	
			case 4:
			    if (Qhs[Client] > 0)
			    {  
			        qhpz1(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");
			case 5:
			    if (Qhs[Client] > 0)
			    {  
			        qhm601(Client);
			    }else CPrintToChat(Client, "你没有强化石，击杀特感有机会获得");				
		}
	}
}
*/
public qhm161(Client)
{
    if(Cash[Client] > 50000 && M16[Client] <= 20)   
	{
	    Cash[Client] -= 50000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           M16[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M16 \x05成功，\x04祝贺他吧", Client, M16[Client]);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M16 \x05失败，\x04获得\x031颗\x04失败的心", Client, M16[Client]);            
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }
    if(Cash[Client] > 80000 && M16[Client] > 20  && M16[Client] <= 40 && Qhs[Client] > 3)   
	{
	    Cash[Client] -= 80000;
	    Qhs[Client] -= 3;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           M16[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M16 \x05成功，\x04祝贺他吧", Client, M16[Client]);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M16 \x05失败，\x04获得\x031颗\x04失败的心", Client, M16[Client]);           
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 5:           
			{     
				M16[Client] --;			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05悲剧，你掉了一级");           
			}
	    }
    }
    if(M16[Client] > 40)   
	{
	    CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05已达上限无法强化");
    }
        
} 

public qhak471(Client)
{
    if(Cash[Client] > 50000 && AK47[Client] <= 20)   
	{
	    Cash[Client] -= 50000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           AK47[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AK47 \x05成功，\x04祝贺他吧", Client, AK47[Client]);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AK47 \x05失败，\x04获得\x031颗\x04失败的心", Client, AK47[Client]);           
			}
			case 3:           
			{   	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }
    if(Cash[Client] > 80000 && AK47[Client] > 20  && AK47[Client] <= 40 && Qhs[Client] > 3)   
	{
	    Cash[Client] -= 80000;
	    Qhs[Client] -= 3;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           AK47[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AK47 \x05成功，\x04祝贺他吧", Client, AK47[Client]);           
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AK47 \x05失败，\x04获得\x031颗\x04失败的心", Client, AK47[Client]);           
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 5:           
			{     
				AK47[Client] --;			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05悲剧，你掉了一级");           
			}
	    }
    }
    if(AK47[Client] > 40)   
	{
	    CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05已达上限无法强化");
    }
        
} 
//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");

public qhawp1(Client)
{
    if(Cash[Client] > 50000 && AWP[Client] <= 20)   
	{
	    Cash[Client] -= 50000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           AWP[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AWP \x05成功，\x04祝贺他吧", Client, AWP[Client]);          
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AWP \x05失败，\x04获得\x031颗\x04失败的心", Client, AWP[Client]);           
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }
    if(Cash[Client] > 80000 && AWP[Client] > 20  && AWP[Client] <= 40 && Qhs[Client] > 3)   
	{
	    Cash[Client] -= 80000;
	    Qhs[Client] -= 3;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           AWP[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AWP \x05成功，\x04祝贺他吧", Client, AWP[Client]);          
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】AWP \x05失败，\x04获得\x031颗\x04失败的心", Client, AWP[Client]);            
			}
			case 3:           
			{   	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 5:           
			{     
				AWP[Client] --;			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05悲剧，你掉了一级");           
			}
	    }
    }
    if(AWP[Client] > 40)   
	{
	    CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05已达上限无法强化");
    }
	//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");
        
} 
//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");

public qhpz1(Client)
{
    if(Cash[Client] > 50000 && PZ[Client] <= 20)   
	{
	    Cash[Client] -= 50000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           PZ[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】喷子 \x05成功，\x04祝贺他吧", Client, PZ[Client]);         
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】喷子 \x05失败，\x04获得\x031颗\x04失败的心", Client, PZ[Client]);            
			}
			case 3:           
			{   	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }
    if(Cash[Client] > 80000 && PZ[Client] > 20  && PZ[Client] <= 40 && Qhs[Client] > 3)   
	{
	    Cash[Client] -= 80000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           PZ[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】喷子 \x05成功，\x04祝贺他吧", Client, PZ[Client]);         
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】喷子 \x05失败，\x04获得\x031颗\x04失败的心", Client, PZ[Client]);          
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 5:           
			{     
				PZ[Client] --			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05悲剧，你掉了一级");           
			}
	    }
    }
    if(PZ[Client] > 40)   
	{
	    CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05已达上限无法强化");
    }
	//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");
        
} 
//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");

public qhm601(Client)
{
    if(Cash[Client] > 50000 && M60[Client] <= 20)   
	{
	    Cash[Client] -= 50000;
	    Qhs[Client] -= 1;
	    new Qhjl = GetRandomInt(1, 4);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           M60[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M6O \x05成功，\x04祝贺他吧", Client, M60[Client]);         
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M6O \x05失败，\x04获得\x031颗\x04失败的心", Client, M60[Client]);           
			}
			case 3:           
			{   	
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
	    }
    }
    if(Cash[Client] > 80000 && M60[Client] > 20  && M60[Client] <= 40 && Qhs[Client] > 3)   
	{
	    Cash[Client] -= 80000;
	    Qhs[Client] -= 3;
	    new Qhjl = GetRandomInt(1, 5);
		
	    switch (Qhjl)       
	    {    
		    case 1:           
			{               
	           M60[Client] ++;
	           CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M6O \x05成功，\x04祝贺他吧", Client, M60[Client]);         
			}
			case 2:           
			{   
				Sxcs[Client] ++			
				CPrintToChatAll("\x01[\x03枪械强化\x01]\x05玩家\x04 %N \x03【强化LV%d】M6O \x05失败，\x04获得\x031颗\x04失败的心", Client, M60[Client]);           
			}
			case 3:           
			{   		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 4:           
			{     		
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05失败");           
			}
			case 5:           
			{     
				M60[Client] --;			
				CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05悲剧，你掉了一级");           
			}
	    }
    }
    if(M60[Client] > 40)   
	{
	    CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05已达上限无法强化");
    }
	//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");
        
} 
//else CPrintToChat(Client, "\x01[\x04强化\x01]\x03：\x05金币不足或材料不足");

public Action:MenuFunc_CLbuy(Client)
{
	decl String:line[256];
	new Handle:menu = CreatePanel();
	Format(line, sizeof(line), "========材料换取系统======");
	SetPanelTitle(menu, line);
	Format(line, sizeof(line),"说明：一定数量的材料可以换取金币");
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"大量材料可以换取随机装备");
	DrawPanelText(menu, line);
	Format(line, sizeof(line),"====================");
	DrawPanelText(menu, line);
	
	Format(line, sizeof(line), "BOSS的心愿【拥有：%d】", BSXY[Client]);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "强化石【拥有%d】", Qhs[Client]);
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_CLbuy, MENU_TIME_FOREVER);

	CloseHandle(menu);

	return Plugin_Handled;
}
public MenuHandler_CLbuy(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select) {
		switch(param) {
			case 1:
			    if (BSXY[Client] > 0)
			    {  
			        MenuFunc_huodong(Client);
			    }else CPrintToChat(Client, "你没有BOSS心愿，无法进入");
			case 2:
			    if (Qhs[Client] > 0)
			    {  
			        MenuFunc_huodong1(Client);
			    }else CPrintToChat(Client, "你没有强化石，击无法进入");				
		}
	}
}

public Action:MenuFunc_huodong(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024], String:wq[1024], String:wq1[1024], String:wq2[1024];	    
	if (BSXY[Client] < 10)
		Format(wq, sizeof(wq), "未达到");
	else if (BSXY[Client] >= 10)
		Format(wq, sizeof(wq), "可领取");
	if (BSXY[Client] < 30)
		Format(wq, sizeof(wq1), "未达到");
	else if (BSXY[Client] >= 30)
		Format(wq1, sizeof(wq1), "可领取");
	if (BSXY[Client] < 50)
		Format(wq2, sizeof(wq2), "未达到");
	else if (BSXY[Client] >= 50)
		Format(wq2, sizeof(wq2), "可领取");
		
	Format(line, sizeof(line), "【BOSS心愿】 拥有:%d个", BSXY[Client]);
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "换取金币5万【%s】", wq);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "换取经验10万【%s】", wq1);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "换取神器随机7天【%s】", wq2);
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_huodong, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_huodong(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: huod(Client);
			case 2: huod1(Client);
			case 3: huod2(Client);
		}
	}
}

public huod(Client)//戒指
{   
	if(BSXY[Client] >= 10)    
	{       
		Cash[Client] += 50000;	
		BSXY[Client] -= 10		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x0510个\x04BOSS心愿，\x05获得5万金币", Client);	    
	} else CPrintToChat(Client, "你的材料不足10个");
}
public huod1(Client)//鞋子
{   
	if(BSXY[Client] >= 30)    
	{       
		EXP[Client] += 100000;
		BSXY[Client] -= 30		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x0530个\x04【BOSS心愿】，\x05获得10万经验", Client);	    
	} else CPrintToChat(Client, "你的材料不足30个");
}
public huod2(Client)//血盾
{   
	if(BSXY[Client] >= 50)    
	{   
		BSXY[Client] -= 50    
		new RandomGiv = GetRandomInt(0, 7);
		switch(RandomGiv)
		{
			case 0: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"17\" \"7\"", Client);
			}
			case 1: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"34\" \"7\"", Client);
			}
			case 2: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"35\" \"7\"", Client);
			}
			case 3: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"43\" \"7\"", Client);
			}
            case 4: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"44\" \"7\"", Client);
			}
            case 5: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"45\" \"7\"", Client);
			}
            case 6: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"42\" \"7\"", Client);
			}	
            case 7: 
			{
				ServerCommand("sm_JGZB \"%N\" \"1\" \"46\" \"7\"", Client);
			}	
        }			
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x0550个\x04【BOSS心愿】，\x05获得\x04随机神器7天", Client);	    
	} else CPrintToChat(Client, "你的材料不足50个");
}

public Action:MenuFunc_huodong1(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:line[1024], String:wq[1024], String:wq1[1024], String:wq2[1024], String:wq3[1024];	    
	if (Qhs[Client] < 10)
		Format(wq, sizeof(wq), "未达到");
	else if (Qhs[Client] >= 10)
		Format(wq, sizeof(wq), "可领取");
	if (Qhs[Client] < 50)
		Format(wq, sizeof(wq1), "未达到");
	else if (Qhs[Client] >= 50)
		Format(wq1, sizeof(wq1), "可领取");
	if (Qhs[Client] < 100)
		Format(wq2, sizeof(wq2), "未达到");
	else if (Qhs[Client] >= 100)
		Format(wq2, sizeof(wq2), "可领取");
	if (Qhs[Client] < 200)
		Format(wq3, sizeof(wq3), "未达到");
	else if (Qhs[Client] >= 200)
		Format(wq3, sizeof(wq3), "可领取");
		
	Format(line, sizeof(line), "【强化石】 拥有:%d个", Qhs[Client]);
	SetPanelTitle(menu, line);
	
	Format(line, sizeof(line), "10000【%s】", wq);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "80000【%s】", wq1);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "150000【%s】", wq2);
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "250000【%s】", wq3);
	DrawPanelItem(menu, line);

	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

	SendPanelToClient(menu, Client, MenuHandler_huodong1, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_huodong1(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: huodq(Client);
			case 2: huod1q(Client);
			case 3: huod2q(Client);
			case 4: huod3q(Client);
		}
	}
}

public huodq(Client)//戒指
{   
	if(Qhs[Client] >= 10)    
	{       
		Cash[Client] += 10000;	
		Qhs[Client] -= 10		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x0510个\x04强化石，\x05获得1万金币", Client);	    
	} else CPrintToChat(Client, "你的材料不足10个");
}
public huod1q(Client)//鞋子
{   
	if(Qhs[Client] >= 50)    
	{       
		Cash[Client] += 80000;
		Qhs[Client] -= 50		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x0550个\x04【强化石】，\x05获得8万金币", Client);	    
	} else CPrintToChat(Client, "你的材料不足50个");
}
public huod2q(Client)//鞋子
{   
	if(Qhs[Client] >= 100)    
	{       
		Cash[Client] += 150000;
		Qhs[Client] -= 100		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x05100个\x04【强化石】，\x05获得15万金币", Client);	    
	} else CPrintToChat(Client, "你的材料不足100个");
}
public huod3q(Client)//鞋子
{   
	if(Qhs[Client] >= 200)    
	{       
		Cash[Client] += 250000;
		Qhs[Client] -= 200		
		CPrintToChatAll("\x02[\x04材料\x02],\x03玩家 \x04%N \x03出售\x05200个\x04【强化石】，\x05获得25万金币", Client);	    
	} else CPrintToChat(Client, "你的材料不足200个");
}
