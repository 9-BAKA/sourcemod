/************************************************************************
*	头衔系统
***********************************************************************/

//头衔系统
public Action:Menu_TXK(Client,args)
{
	MenuFunc_TOUXIAN(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_TOUXIAN(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:JJQS[16];	   
	if(TXXT1[Client] == 0)			Format(JJQS, sizeof(JJQS), "无");   
	else if(TXXT1[Client] == 1)	    Format(JJQS, sizeof(JJQS), "绝境求生");
	else if(TXXT1[Client] == 2)	    Format(JJQS, sizeof(JJQS), "环境保护");
	else if(TXXT1[Client] == 3)	    Format(JJQS, sizeof(JJQS), "禁止呕吐"); 
	else if(TXXT1[Client] == 4)	    Format(JJQS, sizeof(JJQS), "僵尸歼灭者");	
	else if(TXXT1[Client] == 5)	    Format(JJQS, sizeof(JJQS), "僵尸猎手");
	else if(TXXT1[Client] == 6)	    Format(JJQS, sizeof(JJQS), "杀鸟达人");
	else if(TXXT1[Client] == 7)	    Format(JJQS, sizeof(JJQS), "新人上手");	
	else if(TXXT1[Client] == 8)	    Format(JJQS, sizeof(JJQS), "贵族");
	else if(TXXT1[Client] == 9)	    Format(JJQS, sizeof(JJQS), "求生老兵");
	else if(TXXT1[Client] == 10)	    Format(JJQS, sizeof(JJQS), "超级土豪");
	else if(TXXT1[Client] == 11)	    Format(JJQS, sizeof(JJQS), "技术达人");
	else if(TXXT1[Client] == 12)	    Format(JJQS, sizeof(JJQS), "冲出重围");	
	else if(TXXT1[Client] == 13)	    Format(JJQS, sizeof(JJQS), "医疗师");		
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"═══头衔系统═══ \n当前头衔:%s \n获得头衔:%d/13个 \n头衔系统是我们专门推出的一款新系统\n玩家可完成任务获得头衔从而提升自身的属性 ", JJQS,TXXT7[Client]);    
	SetPanelTitle(menu, line);	   	
	
	Format(line, sizeof (line), "装备头衔");  
	DrawPanelItem(menu, line); 
	
	Format(line, sizeof (line), "荣誉头衔");  
	DrawPanelItem(menu, line);
	
	Format(line, sizeof (line), "普通头衔");  
	DrawPanelItem(menu, line);
	
	Format(line, sizeof (line), "卸下头衔");  
	DrawPanelItem(menu, line);
	
	DrawPanelItem(menu, "返回RPG菜单");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_TOUXIAN, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_TOUXIAN(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:MenuFunc_ZBTX(Client);
			case 2:
			{
                if(RYRWK[Client] == 0)
                {
                    MenuFunc_RYRW(Client);
                }
                if(RYRWK[Client] == 1)
                {
                    MenuFunc_RYRWKS(Client);
                }				
            }
			case 3:MenuFunc_PTTX(Client);
			case 4:MenuFunc_XXTX(Client);
			case 5:MenuFunc_RPG(Client);
		}
	}
}

/* 普通头衔 */
public Action:MenuFunc_PTTX(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:JJQS[16];	   
	if(TXXT1[Client] == 0)			Format(JJQS, sizeof(JJQS), "无");   
	else if(TXXT1[Client] == 1)	    Format(JJQS, sizeof(JJQS), "绝境求生");
	else if(TXXT1[Client] == 2)	    Format(JJQS, sizeof(JJQS), "环境保护");
	else if(TXXT1[Client] == 3)	    Format(JJQS, sizeof(JJQS), "禁止呕吐"); 
	else if(TXXT1[Client] == 4)	    Format(JJQS, sizeof(JJQS), "僵尸歼灭者");	
	else if(TXXT1[Client] == 5)	    Format(JJQS, sizeof(JJQS), "僵尸猎手");
	else if(TXXT1[Client] == 6)	    Format(JJQS, sizeof(JJQS), "杀鸟达人");
	else if(TXXT1[Client] == 7)	    Format(JJQS, sizeof(JJQS), "新人上手");	
	else if(TXXT1[Client] == 8)	    Format(JJQS, sizeof(JJQS), "贵族");
	else if(TXXT1[Client] == 9)	    Format(JJQS, sizeof(JJQS), "求生老兵");
	else if(TXXT1[Client] == 10)	    Format(JJQS, sizeof(JJQS), "超级土豪");
	else if(TXXT1[Client] == 11)	    Format(JJQS, sizeof(JJQS), "技术达人");
	else if(TXXT1[Client] == 12)	    Format(JJQS, sizeof(JJQS), "冲出重围");
	else if(TXXT1[Client] == 13)	    Format(JJQS, sizeof(JJQS), "医疗师");	
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"═══普通头衔═══ \n当前头衔:%s \n获得头衔:%d/13个 \n头衔系统是我们专门推出的一款新系统\n玩家可完成任务获得头衔从而提升自身的属性 ", JJQS,TXXT7[Client]);    
	SetPanelTitle(menu, line);	    
    
	Format(line, sizeof(line), "新人上手头衔");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "贵族头衔");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "求生老兵头衔");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "超级土豪头衔");    
	DrawPanelItem(menu, line);
	
	Format(line, sizeof(line), "技术达人头衔");    
	DrawPanelItem(menu, line);
	    	
	DrawPanelItem(menu, "返回头衔系统");    	
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
	
	SendPanelToClient(menu, Client, MenuHandler_PTTX, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_PTTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: MenuFunc_XRSSTX(Client);
			case 2: MenuFunc_GZTX(Client);
			case 3: MenuFunc_QSLBTX(Client);
			case 4: MenuFunc_CJTHTX(Client);
			case 5: MenuFunc_JSDRTX(Client);
			case 6: MenuFunc_TOUXIAN(Client);
		}
	}
}

/*技术达人头衔 */
public Action:MenuFunc_JSDRTX(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【技术达人头衔】");
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "当你的等级达到300级 \n时可获取此称号!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认获取");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回普通头衔表列");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_JSDRTX, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_JSDRTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: JSDRTXS(Client);
			case 2: MenuFunc_PTTX(Client);
		}
	}
}

public JSDRTXS(Client)
{   
	if(Lv[Client] >= 300 && WDTX11[Client] == 0)    
	{       		
		WDTX11[Client] += 1;
		TXXT7[Client] +=1		
		CPrintToChat(Client, "\x03【提示】你成功获得此头衔! ");	   
	} else CPrintToChat(Client, "\x03【提示】你没有达到条件或者你已经拥有此头衔!");
}


/* 新人上手头衔 */
public Action:MenuFunc_XRSSTX(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【新人上手头衔】");
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "获得此头衔你的等级需要达到\n:30级!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "获得头衔");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回普通头衔表列");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_XRSSTX, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_XRSSTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: XRSSTXS(Client);
			case 2: MenuFunc_PTTX(Client);
		}
	}
}

public XRSSTXS(Client)
{
    if(Lv[Client] >= 30 && WDTX7[Client] == 0)
    {
        WDTX7[Client] += 1;
        TXXT7[Client] +=1		
        CPrintToChat(Client, "\x03【系统】你成功获取了此头衔!");	 
    } else CPrintToChat(Client, "\x03【提示】你没有达到要求或者你已经有了这个头衔!");
}

/* 贵族头衔 */
public Action:MenuFunc_GZTX(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【贵族头衔】");
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "你需要成为至尊会员 \n才能获得此头衔!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认获取");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回普通头衔表列");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_GZTX, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_GZTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: GZTXS(Client);
			case 2: MenuFunc_PTTX(Client);
		}
	}
}

public GZTXS(Client)
{   
	if(VIP[Client] == 4 && WDTX8[Client] == 0)    
	{       	
		WDTX8[Client] += 1;
		TXXT7[Client] +=1
		CPrintToChat(Client, "\x03【提示】你成功获得贵族头衔!");	 	 
	} else CPrintToChat(Client, "\x03【提示】你没有达到条件或者你已经有此头衔!");
}

/* 求生老兵头衔 */
public Action:MenuFunc_QSLBTX(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【求生老兵头衔】");
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "你需要等级达到120级才能获得 \n此头衔!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认获得");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回普通头衔表列");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_QSLBTX, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_QSLBTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: HQCCCSS(Client);
			case 2: MenuFunc_PTTX(Client);
		}
	}
}

public HQCCCSS(Client)
{   
	if(Lv[Client] >= 120 && WDTX9[Client] == 0)    
	{       		
		WDTX9[Client] += 1;
		TXXT7[Client] +=1 		
		CPrintToChat(Client, "\x03【提示】你成功获取此头衔!");	 
	} else CPrintToChat(Client, "\x03【提示】你没有达到条件或者你已经拥有此头衔!");
}

/* 超级土豪头衔 */
public Action:MenuFunc_CJTHTX(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];	
    Format(line, sizeof(line), "【超级土豪头衔】");
    SetPanelTitle(menu, line);
    Format(line, sizeof(line), "当你的求生币达到90000! \n时可获取此称号!");
    DrawPanelText(menu, line);

    Format(line, sizeof(line), "确认获取");
    DrawPanelItem(menu, line);
    DrawPanelItem(menu, "返回普通头衔表列");
    DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);

    SendPanelToClient(menu, Client, MenuHandler_CJTHTX, MENU_TIME_FOREVER);
    return Plugin_Handled;
}
public MenuHandler_CJTHTX(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
			case 1: CJTHTXs(Client);
			case 2: MenuFunc_PTTX(Client);
		}
	}
}

public CJTHTXs(Client)
{   
	if(Qcash[Client] >= 90000 && WDTX10[Client] == 0)    
	{       		
		WDTX10[Client] += 1; 
		TXXT7[Client] +=1
		CPrintToChat(Client, "\x03【提示】你成功获得此头衔! ");	   
	} else CPrintToChat(Client, "\x03【提示】你没有达到条件或者你已经拥有此头衔!");
}


//使用头衔
public Action:MenuFunc_ZBPTX(Client)
{
	new Handle:menu = CreatePanel();
	
	decl String:ZBTX7S[16];	   
	if(WDTX7[Client] == 0)			Format(ZBTX7S, sizeof(ZBTX7S), "无");   
	else if(WDTX7[Client] == 1)	    Format(ZBTX7S, sizeof(ZBTX7S), "新人上手");
	
	decl String:ZBTX8S[16];	   
	if(WDTX8[Client] == 0)			Format(ZBTX8S, sizeof(ZBTX8S), "无");   
	else if(WDTX8[Client] == 1)	    Format(ZBTX8S, sizeof(ZBTX8S), "贵族");
	
	decl String:ZBTX9S[16];	   
	if(WDTX9[Client] == 0)			Format(ZBTX9S, sizeof(ZBTX9S), "无");   
	else if(WDTX9[Client] == 1)	    Format(ZBTX9S, sizeof(ZBTX9S), "求生老兵");
	
	decl String:ZBTX10S[16];	   
	if(WDTX10[Client] == 0)			Format(ZBTX10S, sizeof(ZBTX10S), "无");   
	else if(WDTX10[Client] == 1)	    Format(ZBTX10S, sizeof(ZBTX10S), "超级土豪");
	
	decl String:ZBTX11S[16];	   
	if(WDTX11[Client] == 0)			Format(ZBTX11S, sizeof(ZBTX11S), "无");   
	else if(WDTX11[Client] == 1)	    Format(ZBTX11S, sizeof(ZBTX11S), "技术达人");

	decl String:ZBTX12S[16];	   
	if(WDTX12[Client] == 0)			Format(ZBTX12S, sizeof(ZBTX12S), "无");   
	else if(WDTX12[Client] == 1)	    Format(ZBTX12S, sizeof(ZBTX12S), "冲出重围");		
	
	decl String:ZBTX13S[16];	   
	if(WDTX13[Client] == 0)			Format(ZBTX13S, sizeof(ZBTX13S), "无");   
	else if(WDTX13[Client] == 1)	    Format(ZBTX13S, sizeof(ZBTX13S), "医疗师");		
	  
	decl String:line[256];   
	Format(line, sizeof (line), "═══我的头衔═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof (line), "%s", ZBTX7S);   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "%s", ZBTX8S);  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "%s", ZBTX9S);  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "%s", ZBTX10S);   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "%s", ZBTX11S);  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "%s", ZBTX12S);  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "%s", ZBTX13S);  
	DrawPanelItem(menu, line); 	
	DrawPanelItem(menu, "返回头衔系统");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_ZBPTX, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_ZBPTX(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:ZBTX7(Client);
            case 2:ZBTX8(Client);
			case 3:ZBTX9(Client);
            case 4:ZBTX10(Client);
            case 5:ZBTX11(Client);
            case 6:ZBTX12(Client);			
            case 7:ZBTX13(Client);				
			case 8:MenuFunc_TOUXIAN(Client);
		}
	}
}
public ZBTX7(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX7[Client] == 1)        
		{            
			TXXT1[Client] = 7 	
			Health[Client] += 2 
			WDTX7[Client] -= 1
		} 	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX8(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX8[Client] == 1)        
		{            
			TXXT1[Client] = 8	
			Endurance[Client] += 2
			WDTX8[Client] -= 1 			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX9(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX9[Client] == 1)        
		{            
			TXXT1[Client] = 9
			Intelligence[Client] += 2
			WDTX9[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX10(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX10[Client] == 1)        
		{            
			TXXT1[Client] =10
			Agi[Client] += 2
			WDTX10[Client] -= 1			
		} 	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX11(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX11[Client] == 1)        
		{            
			TXXT1[Client] = 11 
			Agi[Client] += 8
			WDTX11[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX12(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX12[Client] == 1)        
		{            
			TXXT1[Client] = 12 
			Agi[Client] += 12
			WDTX12[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX13(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX13[Client] == 1)        
		{            
			TXXT1[Client] = 13 
			Agi[Client] += 10
			WDTX13[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}


//卸下头衔
public Action:MenuFunc_XXTXS(Client)
{
	new Handle:menu = CreatePanel();
	  
	decl String:line[256];   
	Format(line, sizeof (line), "═══卸下头衔═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof (line), "卸下新人上手");   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "卸下贵族");  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "卸下求生老兵");  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "卸下超级土豪");   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "卸下技术达人");  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "卸下冲出重围");  
	DrawPanelItem(menu, line);  	
	Format(line, sizeof (line), "卸下医疗师");  
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "返回头衔背包");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_XXTXS, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_XXTXS(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:XXTX7(Client);
            case 2:XXTX8(Client);
			case 3:XXTX9(Client);
			case 4:XXTX10(Client);
            case 5:XXTX11(Client);
            case 6:XXTX12(Client);
            case 7:XXTX13(Client);			
			case 8:MenuFunc_ZBPTX(Client);
		}
	}
}
public XXTX7(Client)
{   
	if(TXXT1[Client] == 7)    
	{	    
		if(TXXT1[Client] == 7)        
		{            
			TXXT1[Client] = 0
			Health[Client] -= 2
			WDTX7[Client] += 1 			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX8(Client)
{   
	if(TXXT1[Client] == 8)    
	{	    
		if(TXXT1[Client] == 8)        
		{            
			TXXT1[Client] = 0
			Endurance[Client] -= 2
			WDTX8[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX9(Client)
{   
	if(TXXT1[Client] == 9)    
	{	    
		if(TXXT1[Client] == 9)        
		{            
			TXXT1[Client] = 0  
			Intelligence[Client] -= 2
			WDTX9[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX10(Client)
{   
	if(TXXT1[Client] == 10)    
	{	    
		if(TXXT1[Client] == 10)        
		{            
			TXXT1[Client] = 0
			Agi[Client] -= 2
			WDTX10[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX11(Client)
{   
	if(TXXT1[Client] == 11)    
	{	    
		if(TXXT1[Client] == 11)        
		{            
			TXXT1[Client] = 0  
			Agi[Client] -= 8
			WDTX11[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX12(Client)
{   
	if(TXXT1[Client] == 12)    
	{	    
		if(TXXT1[Client] == 12)        
		{            
			TXXT1[Client] = 0 
			Agi[Client] -= 12
			WDTX12[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX13(Client)
{   
	if(TXXT1[Client] == 13)    
	{	    
		if(TXXT1[Client] == 13)        
		{            
			TXXT1[Client] = 0 
			Agi[Client] -= 10
			WDTX13[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}


//使用头衔
public Action:MenuFunc_ZBTX(Client)
{
	new Handle:menu = CreatePanel();

	decl String:ZBTX1S[16];	   
	if(WDTX1[Client] == 0)			Format(ZBTX1S, sizeof(ZBTX1S), "无");   
	else if(WDTX1[Client] == 1)	    Format(ZBTX1S, sizeof(ZBTX1S), "绝境求生");
	
	decl String:ZBTX2S[16];	   
	if(WDTX2[Client] == 0)			Format(ZBTX2S, sizeof(ZBTX2S), "无");   
	else if(WDTX2[Client] == 1)	    Format(ZBTX2S, sizeof(ZBTX2S), "僵尸歼灭者");
	
	decl String:ZBTX3S[16];	   
	if(WDTX3[Client] == 0)			Format(ZBTX3S, sizeof(ZBTX3S), "无");   
	else if(WDTX3[Client] == 1)	    Format(ZBTX3S, sizeof(ZBTX3S), "杀鸟达人");
	
	decl String:ZBTX4S[16];	   
	if(WDTX4[Client] == 0)			Format(ZBTX4S, sizeof(ZBTX4S), "无");   
	else if(WDTX4[Client] == 1)	    Format(ZBTX4S, sizeof(ZBTX4S), "僵尸猎手");
	
	decl String:ZBTX5S[16];	   
	if(WDTX5[Client] == 0)			Format(ZBTX5S, sizeof(ZBTX5S), "无");   
	else if(WDTX5[Client] == 1)	    Format(ZBTX5S, sizeof(ZBTX5S), "禁止呕吐");

	decl String:ZBTX6S[16];	   
	if(WDTX6[Client] == 0)			Format(ZBTX6S, sizeof(ZBTX6S), "无");   
	else if(WDTX6[Client] == 1)	    Format(ZBTX6S, sizeof(ZBTX6S), "环境保护");		
	
	decl String:line[256];   
	Format(line, sizeof (line), "═══我的头衔═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof (line), "%s", ZBTX1S);   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "%s", ZBTX2S);  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "%s", ZBTX3S);  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "%s", ZBTX4S);   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "%s", ZBTX5S);  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "%s", ZBTX6S);  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "下一页");  
	DrawPanelItem(menu, line); 	
	DrawPanelItem(menu, "返回头衔系统");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_ZBTX, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_ZBTX(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:ZBTX1(Client);
            case 2:ZBTX2(Client);
			case 3:ZBTX3(Client);
            case 4:ZBTX4(Client);
            case 5:ZBTX5(Client);
			case 6:ZBTX6(Client);
			case 7:MenuFunc_ZBPTX(Client);
			case 8:MenuFunc_TOUXIAN(Client);
		}
	}
}
public ZBTX1(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX1[Client] == 1)        
		{            
			TXXT1[Client] = 1
			Agi[Client] += 12
			WDTX1[Client] -= 1			
		} 	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX2(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX2[Client] == 1)        
		{            
			TXXT1[Client] = 4
			Str[Client] += 8
			WDTX2[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX3(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX3[Client] == 1)        
		{            
			TXXT1[Client] = 6
			Endurance[Client] += 8
			WDTX3[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX4(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX4[Client] == 1)        
		{            
			TXXT1[Client] = 5
			Intelligence[Client] += 8
			WDTX4[Client] -= 1			
		} 	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX5(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX5[Client] == 1)        
		{            
			TXXT1[Client] = 3
			Health[Client] += 8 
			WDTX5[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

public ZBTX6(Client)
{   
	if(TXXT1[Client] == 0)    
	{	    
		if(WDTX6[Client] == 1)        
		{            
			TXXT1[Client] = 2
			Str[Client] += 12
			WDTX6[Client] -= 1			
		}	
	} else PrintHintText(Client, "你已经装备了头衔!");	
}

//卸下头衔
public Action:MenuFunc_XXTX(Client)
{
	new Handle:menu = CreatePanel();
	  
	decl String:line[256];   
	Format(line, sizeof (line), "═══卸下头衔═══");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof (line), "卸下绝境求生");   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "卸下僵尸歼灭者");  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "卸下杀鸟达人");  
	DrawPanelItem(menu, line); 
	Format(line, sizeof (line), "卸下僵尸猎手");   
	DrawPanelItem(menu, line);	
	Format(line, sizeof (line), "卸下禁止呕吐");  
	DrawPanelItem(menu, line);  
	Format(line, sizeof (line), "卸下环境保护");  
	DrawPanelItem(menu, line);
	Format(line, sizeof (line), "下一页");  
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "返回头衔背包");  
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
  
	SendPanelToClient(menu, Client, MenuHandler_XXTX, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}
public MenuHandler_XXTX(Handle:menu, MenuAction:action, Client, param)
{
	if(action == MenuAction_Select)
	{
		switch(param)
		{
			case 1:XXTX1(Client);
            case 2:XXTX2(Client);
			case 3:XXTX3(Client);
			case 4:XXTX4(Client);
            case 5:XXTX5(Client);
			case 6:XXTX6(Client);
			case 7:MenuFunc_XXTXS(Client);			
			case 8:MenuFunc_ZBTX(Client);
		}
	}
}
public XXTX1(Client)
{   
	if(TXXT1[Client] == 1)    
	{	    
		if(TXXT1[Client] == 1)        
		{            
			TXXT1[Client] = 0
			Agi[Client] -= 12	
			WDTX1[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX2(Client)
{   
	if(TXXT1[Client] == 4)    
	{	    
		if(TXXT1[Client] == 4)        
		{            
			TXXT1[Client] = 0
			Str[Client] -= 8
			WDTX2[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX3(Client)
{   
	if(TXXT1[Client] == 6)    
	{	    
		if(TXXT1[Client] == 6)        
		{            
			TXXT1[Client] = 0 
			Endurance[Client] -= 8
			WDTX3[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX4(Client)
{   
	if(TXXT1[Client] == 5)    
	{	    
		if(TXXT1[Client] == 5)        
		{            
			TXXT1[Client] = 0
			Intelligence[Client] -= 8
			WDTX4[Client] += 1  			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX5(Client)
{   
	if(TXXT1[Client] == 3)    
	{	    
		if(TXXT1[Client] == 3)        
		{            
			TXXT1[Client] = 0
			Health[Client] -= 8
			WDTX5[Client] += 1 			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

public XXTX6(Client)
{   
	if(TXXT1[Client] == 2)    
	{	    
		if(TXXT1[Client] == 2)        
		{            
			TXXT1[Client] = 0
			Str[Client] -= 12	
			WDTX6[Client] += 1			
		}	
	} else PrintHintText(Client, "你没有装备这个头衔!");	
}

//荣誉头衔
public Action:Menu_RYRW(Client,args)
{
    if(RYRWK[Client] == 0)
    {
        MenuFunc_RYRW(Client);
    }
    if(RYRWK[Client] == 1)
    {
        MenuFunc_RYRWKS(Client);
    }	
    return Plugin_Handled;
}
public Action:MenuFunc_RYRW(Client)
{   
	new Handle:menu = CreatePanel();
	    
	decl String:RYRWSS[1024];	    
	if(RYRWS[Client] == 0)			Format(RYRWSS, sizeof(RYRWSS), "未接");
	    
	decl String:line[1024];    
	Format(line, sizeof(line), "【头衔列表 状态:%s】", RYRWSS);   
	SetPanelTitle(menu, line);    
	Format(line, sizeof(line), "═══绝境求生═══");    
	DrawPanelItem(menu, line);      
	Format(line, sizeof(line), "═══僵尸歼灭者═══");   
	DrawPanelItem(menu, line);      
	Format(line, sizeof(line), "═══杀鸟达人═══");   
	DrawPanelItem(menu, line);      
	Format(line, sizeof(line), "═══僵尸猎手═══");       
	DrawPanelItem(menu, line);		
	Format(line, sizeof(line), "═══禁止呕吐═══");   
	DrawPanelItem(menu, line);      
	Format(line, sizeof(line), "═══环境保护═══");       
	DrawPanelItem(menu, line);	
	Format(line, sizeof(line), "═══冲出重围═══");       
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "下一页");       
	DrawPanelItem(menu, line);	
	DrawPanelItem(menu, "返回头衔菜单"); 
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_RYRW, MENU_TIME_FOREVER);    
	return Plugin_Handled;
}

public MenuHandler_RYRW(Handle:menu, MenuAction:action, Client, param)
{    
	if (action == MenuAction_Select)     
	{
		switch (param)   
		{        
			case 1:
            {
				if(WDTX1[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 1;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}		
            case 2:
            {
				if(WDTX2[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 2;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}
            case 3:
            {
				if(WDTX3[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 3;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}
			case 4:
            {
				if(WDTX4[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 4;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}
			case 5:
            {
				if(WDTX5[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 5;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}
			case 6:
            {
				if(WDTX6[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 6;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}
			case 7:
            {
				if(WDTX12[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 7;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}	
			case 8:MenuFunc_RYRW2(Client);			
			case 9:MenuFunc_TOUXIAN(Client);
        }
    }
}

public Action:MenuFunc_RYRW2(Client)
{   
	new Handle:menu = CreatePanel();
	    
	decl String:RYRWSS[1024];	    
	if(RYRWS[Client] == 0)			Format(RYRWSS, sizeof(RYRWSS), "未接");
	    
	decl String:line[1024];    
	Format(line, sizeof(line), "【头衔列表 状态:%s】", RYRWSS);   
	SetPanelTitle(menu, line);    
	Format(line, sizeof(line), "═══医疗师═══");    
	DrawPanelItem(menu, line);      
      
	DrawPanelItem(menu, "返回头衔菜单"); 
	DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_RYRW2, MENU_TIME_FOREVER);    
	return Plugin_Handled;
}

public MenuHandler_RYRW2(Handle:menu, MenuAction:action, Client, param)
{    
	if (action == MenuAction_Select)     
	{
		switch (param)   
		{        
			case 1:
            {
				if(WDTX13[Client] == 0)
				{
					if(RYRWS[Client] == 0)
					{                        
						RYRWK[Client] += 1;						
						RYRWS[Client] += 8;						
						MenuFunc_RYRWKS(Client);	
					}
				} else CPrintToChat(Client, "\x03【任务】\x05你已经有了这个头衔!");            
			}				
			case 2:MenuFunc_TOUXIAN(Client);
        }
    }
}

public Action:MenuFunc_RYRWKS(Client)
{
    new Handle:menu = CreatePanel();
	
    decl String:line[1024];
    if (RYRWS[Client] == 1)
    {
        Format(line, sizeof(line), "═══【头衔】绝境求生═══ \n【任务需求: 击杀普通感染者!】\n【普通感染者:1000个】〤斩:%d个 \n【任务奖励: 绝境求生头衔】 \n══════════════", TXXT8[Client]);
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }	
    else if (RYRWS[Client] == 6)
    {
        Format(line, sizeof(line), "═══【头衔】环境保护═══ \n【任务需求: 击杀SMOKER!】 \n【任务奖励:环境保护头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【Smoker500个】〤斩:%d个\n══════════════", TXXT9[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
    else if (RYRWS[Client] == 5)
    {
        Format(line, sizeof(line), "═══【头衔】禁止呕吐═══ \n【任务需求: 击杀BOOMER!】 \n【任务奖励: 禁止呕吐头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【BOMMER500个】〤斩:%d个 \n══════════════", TXXTx[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (RYRWS[Client] == 2)
    {
        Format(line, sizeof(line), "═══【头衔】僵尸歼灭者═══ \n【任务需求: 击杀普通感染者!】 \n【任务奖励:僵尸歼灭者头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【普通僵尸2000个】〤斩:%d个 \n══════════════", TXXT8[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (RYRWS[Client] == 3)
    {
        Format(line, sizeof(line), "═══【头衔】杀鸟达人═══ \n【任务需求: 感染者克星!】 \n【任务奖励: 杀鸟达人头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【HUNTER500个】〤斩:%d个 \n══════════════", TXXT0[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (RYRWS[Client] == 4)
    {
        Format(line, sizeof(line), "═══【头衔】僵尸猎手═══ \n【任务需求: 击杀猎人】 \n【任务奖励: 僵尸猎手头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【HUNTER400个】〤斩:%d个 \n══════════════", TXXT0[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (RYRWS[Client] == 7)
    {
        Format(line, sizeof(line), "═══【头衔】冲出重围═══ \n【任务需求: 击杀击杀普通感染者与烟鬼!】 \n【任务奖励: 冲出重围头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【普通僵尸1000个】〤斩:%d个 【SMOKER1000个】〤斩:%d个  \n══════════════", TXXT8[Client], TXXT9[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }
	else if (RYRWS[Client] == 8)
    {
        Format(line, sizeof(line), "═══【头衔】医疗师═══ \n【任务需求: 帮助你的队友!】 \n【任务奖励: 医疗师头衔】 \n══════════════");
        SetPanelTitle(menu, line);
        Format(line, sizeof(line), "【拉起队友1000次】已拉起:%d次 【复活队友1000次】已复活:%d次  \n══════════════", TXXT3[Client], TXXT4[Client]);
        DrawPanelText(menu, line);
        Format(line, sizeof(line), "完成任务");
        DrawPanelItem(menu, line);
        Format(line, sizeof(line), "放弃任务");
        DrawPanelItem(menu, line);
        DrawPanelItem(menu, "返回头衔系统");
        DrawPanelItem(menu, "离开", ITEMDRAW_DISABLED);
    }	
	
    SendPanelToClient(menu, Client, MenuHandler_RYRWKS, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public MenuHandler_RYRWKS(Handle:menu, MenuAction:action, Client, param)
{
    if (action == MenuAction_Select) 
    {
        switch (param)
        {
	        case 1: RENWUWANS(Client);	
            case 2: RENWUQIS(Client);	
            case 3: MenuFunc_TOUXIAN(Client);			
        }
    }
}
public RENWUWANS(Client)
{	
    if(RYRWS[Client] == 1)
    {
        if(TXXT8[Client] >= 1000)
        {
            WDTX1[Client] += 1;
            TXXT7[Client] += 1;
            TXXT8[Client] = 0;
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了头衔绝境求生!");
            CPrintToChatAll("\x03【任务】玩家%N完成了荣誉任务: 绝境求生!", Client);
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 2)
    {
        if(TXXT8[Client] >= 2000)
        {
		    WDTX2[Client] += 1;
		    TXXT7[Client] += 1;
		    TXXT8[Client] = 0;
		    RYRWS[Client] = 0;
		    RYRWK[Client] = 0;
		    PrintHintText(Client, "【任务】完成任务,您获得了僵尸歼灭者头衔!");
		    CPrintToChatAll("\x03【任务】玩家%N完成了任务: 僵尸歼灭者!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 3)
    {
        if(TXXT0[Client] >= 500)
        {
            WDTX3[Client] += 1;
            TXXT7[Client] += 1;
            TXXT0[Client] = 0;
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了 杀鸟达人头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务:  杀鸟达人!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 4)
    {
        if(TXXT0[Client] >= 400)
        {
            WDTX4[Client] += 1;
            TXXT7[Client] += 1;
            TXXT0[Client] = 0
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了僵尸猎手头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务:僵尸猎手!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 5)
    {
        if(TXXTx[Client] >= 500)
        {
            WDTX5[Client] += 1;
            TXXT7[Client] += 1;
            TXXTx[Client] = 0;
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了禁止呕吐头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 禁止呕吐!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 6)
    {
        if(TXXT9[Client] >= 500)
        {
            WDTX5[Client] += 1;
            TXXT7[Client] += 1;
            TXXT9[Client] = 0;
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了环境保护头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 环境保护!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }
    if(RYRWS[Client] == 7)
    {
        if(TXXT9[Client] >= 1000 && TXXT9[Client] >= 1000)
        {
            WDTX12[Client] += 1;
            TXXT7[Client] += 1;
            TXXT9[Client] = 0;
            TXXT8[Client] = 0;			
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了冲出重围头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 冲出重围!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }	
    if(RYRWS[Client] == 8)
    {
        if(TXXT3[Client] >= 1000 && TXXT4[Client] >= 1000)
        {
            WDTX13[Client] += 1;
            TXXT7[Client] += 1;
            TXXT3[Client] = 0;
            TXXT4[Client] = 0;			
            RYRWS[Client] = 0;
            RYRWK[Client] = 0;
            PrintHintText(Client, "【任务】完成任务,您获得了医疗师头衔!");
            CPrintToChatAll("\x03【任务】玩家%N完成了任务: 医疗师!", Client);			
        } else PrintHintText(Client, "【任务】你没达到所需要求!");	
    }	
}	
public RENWUQIS(Client)
{	
    if(RYRWS[Client] == 1)
    {
        TXXT8[Client] = 0;
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 2)
    {
        TXXT8[Client] = 0;
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 3)
    {
        TXXT0[Client] = 0;
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 4)
    {
        TXXT0[Client] = 0
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 5)
    {
        TXXTx[Client] = 0;
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 6)
    {
        TXXT9[Client] = 0;
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }
    if(RYRWS[Client] == 7)
    {
        TXXT9[Client] = 0;
        TXXT8[Client] = 0;		
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }	
    if(RYRWS[Client] == 8)
    {
        TXXT3[Client] = 0;
        TXXT4[Client] = 0;		
        RYRWS[Client] = 0;
        RYRWK[Client] = 0;
        PrintHintText(Client, "【任务】你放弃了任务!");
    }	
}





