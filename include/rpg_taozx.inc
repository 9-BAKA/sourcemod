/************************************************************************
*	��װװ����ش���
************************************************************************/

/* װ������ */
new EpStr[MAXPLAYERS+1]; //����
new EpAgi[MAXPLAYERS+1]; //����
new EpHealth[MAXPLAYERS+1]; //����
new EpEndurance[MAXPLAYERS+1]; //����
new EpIntelligence[MAXPLAYERS+1]; //����

new Touke[MAXPLAYERS+1]; //ͷ��
new Jiake[MAXPLAYERS+1]; //����
new Xieke[MAXPLAYERS+1]; //Ь��
new Kuke[MAXPLAYERS+1]; //����
new Wuqi[MAXPLAYERS+1]; //����
#define JBC[%1] JD[%1]	

//������װ���
new EpStrdan[MAXPLAYERS+1]; //��ҩר�Ҽ����˺�
new Xizlv[MAXPLAYERS+1]; //������װ�ȼ�

//װ����������and����
public Zbtouke(Client)
{
	if (Touke[Client] == 1)
	{
		EpHealth[Client] += 10;	    
		EpEndurance[Client] += 10;
	}
}
public Zbjiake(Client)
{
	if (Jiake[Client] == 1)
	{   
		EpStr[Client] += 100;
		EpEndurance[Client] += 50;
	}
}
public Zbxieke(Client)
{
	if (Xieke[Client] == 1)
	{   
		EpStr[Client] += 15;
	}
}
public Zbkuke(Client)
{
	if (Kuke[Client] == 1)
	{   
		EpHealth[Client] += 50;
	}
}
public Zbwuqi(Client)
{
	if (Wuqi[Client] == 1)
	{   
		EpStr[Client] += 100;
	}
}
public Zbtaozb(Client)
{
	if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)
	{   		
		if (Xizlv[Client] >= 1)    
		{		    
			EpStrdan[Client] += 10*Xizlv[Client];		    
			EpStr[Client] += 10*Xizlv[Client];	    		    
			EpAgi[Client] += 10*Xizlv[Client];	    		    
			EpHealth[Client] += 10*Xizlv[Client];	    		    
			EpEndurance[Client] += 10*Xizlv[Client];	    		    
			EpIntelligence[Client] += 10*Xizlv[Client];    
		} 		
		else		
		{		    
			EpStrdan[Client] += 10;		    
			EpStr[Client] += 10;	    	    
			EpAgi[Client] += 10;	    		    
			EpHealth[Client] += 10;	    	    
			EpEndurance[Client] += 10;	    		    
			EpIntelligence[Client] += 10;	
		}
	}
}
public Pandushu(Client)
{
	if (Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)
	{   		
		StatusPoint[Client]++;
	}
}	

/* װ����ʾ�˵�*/
public Action:Menu_Zhuang(Client,args)
{
	MenuFunc_Zhuang(Client);
	return Plugin_Handled;
}
public Action:MenuFunc_Zhuang(Client)
{ 
	new Handle:menu = CreatePanel();
    
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "��");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "����ͷ��");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "��");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "���黤��");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "��");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "����Ь��");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "��"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "�������");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "��");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "����ǹ");
	  
	decl String:line[256];   
	Format(line, sizeof(line),    
	"�T�T�T�ҵ�����װ���T�T�T \n ͷ��:%s \n ����:%s \n Ь��:%s \n ����:%s \n ����:%s", ZBEET, ZBXXT, ZBNNT, ZBJJT, ZBCCT);    
	SetPanelTitle(menu, line);	
	if(JBC[Client] == 6)
	{    
		if(Touke[Client] == 1 && Jiake[Client] == 1 && Xieke[Client] == 1 && Kuke[Client] == 1 && Wuqi[Client] == 1)	    
		{        
			Format(line, sizeof(line),           
			"�T�T�T�ҵ�����װ��[������װ LV.%d]�T�T�T \n ͷ��:%s \n ����:%s \n Ь��:%s \n ����:%s \n ����:%s", Xizlv[Client], ZBEET, ZBXXT, ZBNNT, ZBJJT, ZBCCT);           
			SetPanelTitle(menu, line);    
		}
	}
	   
	Format(line, sizeof(line), "�鿴װ��");  
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "װ������");  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "װ���������");  
	DrawPanelItem(menu, line); 
	DrawPanelItem(menu, "����RPGѡ��");   
	DrawPanelItem(menu, "�뿪", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Zhuang, MENU_TIME_FOREVER);     
	return Plugin_Handled;
}

public MenuHandler_Zhuang(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chakan(Client);
            case 2: MenuFunc_Ghuang(Client);
			case 3: MenuFunc_RPG(Client);				
		}
	}
}

/* װ����ʾ�˵�*/
public Action:MenuFunc_Ghuang(Client)
{ 
	new Handle:menu = CreatePanel();
    
	  
	decl String:line[256];   
	Format(line, sizeof(line), "�T�T�T�ҵ�����װ�����ܨT�T�T");    
	SetPanelTitle(menu, line);	
	   
	Format(line, sizeof(line), "����װ��");  
	DrawPanelItem(menu, line);
	Format(line, sizeof(line), "ж��װ��");  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "����װ��");  
	DrawPanelItem(menu, line);
	DrawPanelItem(menu, "����RPGѡ��");   
	DrawPanelItem(menu, "�뿪", ITEMDRAW_DISABLED);
    
	SendPanelToClient(menu, Client, MenuHandler_Ghuang, MENU_TIME_FOREVER);     
	return Plugin_Handled;
}

public MenuHandler_Ghuang(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chadiuq(Client);
            case 2: MenuFunc_Xiadiuq(Client);
			case 3: MenuFunc_Xiadiuq(Client);
			case 4: MenuFunc_RPG(Client);				
		}
	}
}

/* װ���鿴�˵�*/
public Action:MenuFunc_Chakan(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "��");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "����ͷ��");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "��");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "���黤��");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "��");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "����Ь��");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "��"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "�������");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "��");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "����ǹ");
	
	decl String:line[256];  
	Format(line, sizeof(line), "�T�T�Tӵ�е�����װ���T�T�T");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "�鿴�ҵ�ͷ��: %s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�鿴�ҵĻ���: %s", ZBXXT);   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�鿴�ҵ�Ь��: %s", ZBNNT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�鿴�ҵĿ���: %s", ZBJJT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�鿴�ҵ�����: %s", ZBCCT);   
	DrawPanelItem(menu, line);  
		   	
	DrawPanelItem(menu, "����װ��ѡ��");   
	DrawPanelItem(menu, "�뿪", ITEMDRAW_DISABLED);  
	
	SendPanelToClient(menu, Client, MenuHandler_Chakan, MENU_TIME_FOREVER);      	
	return Plugin_Handled;
}

public MenuHandler_Chakan(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: MenuFunc_Chash(Client);
			case 2: MenuFunc_Chasq(Client);
			case 3: MenuFunc_Chasa(Client);
			case 4: MenuFunc_Chasz(Client);
			case 5: MenuFunc_Chasw(Client);
			case 6: MenuFunc_Zhuang(Client);				
		}
	}
}

/* װ�������˵�*/
public Action:MenuFunc_Chadiuq(Client)
{ 
	new Handle:menu = CreatePanel();
    	
	decl String:ZBEET[1024];	   
	if(Touke[Client] == 0)			Format(ZBEET, sizeof(ZBEET), "��");   
	else if(Touke[Client] == 1)	    Format(ZBEET, sizeof(ZBEET), "����ͷ��");
	   
	decl String:ZBXXT[1024];	   
	if(Jiake[Client] == 0)			Format(ZBXXT, sizeof(ZBXXT), "��");   
	else if(Jiake[Client] == 1)	    Format(ZBXXT, sizeof(ZBXXT), "���黤��");
   
	decl String:ZBNNT[1024];	  
	if(Xieke[Client] == 0)			Format(ZBNNT, sizeof(ZBNNT), "��");  
	else if(Xieke[Client] == 1)	    Format(ZBNNT, sizeof(ZBNNT), "����Ь��");
   
	decl String:ZBJJT[1024];	  
	if(Kuke[Client] == 0)			Format(ZBJJT, sizeof(ZBJJT), "��"); 
	else if(Kuke[Client] == 1)	    Format(ZBJJT, sizeof(ZBJJT), "�������");
   
	decl String:ZBCCT[1024];	   
	if(Wuqi[Client] == 0)			Format(ZBCCT, sizeof(ZBCCT), "��");   
	else if(Wuqi[Client] == 1)	    Format(ZBCCT, sizeof(ZBCCT), "����ǹ");
	
	decl String:line[256];  
	Format(line, sizeof(line), "�T�T�Tӵ�е�����װ���T�T�T");    
	SetPanelTitle(menu, line);   
	Format(line, sizeof(line), "�����ҵ�ͷ��: %s", ZBEET);    
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�����ҵĻ���: %s", ZBXXT);   
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�����ҵ�Ь��: %s", ZBNNT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�����ҵĿ���: %s", ZBJJT);  
	DrawPanelItem(menu, line);   
	Format(line, sizeof(line), "�����ҵ�����: %s", ZBCCT);   
	DrawPanelItem(menu, line);  
		   	
	DrawPanelItem(menu, "����װ��ѡ��");   
	DrawPanelItem(menu, "�뿪", ITEMDRAW_DISABLED);  
	
	SendPanelToClient(menu, Client, MenuHandler_Chadiuq, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_Chadiuq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) {
		switch (param)
		{
            case 1: ZBDIUK(Client);
			case 2: ZBDIUQ(Client);
			case 3: ZBDIUA(Client);
			case 4: ZBDIUR(Client);
			case 5: ZBDIUY(Client);
			case 6: MenuFunc_Zhuang(Client);				
		}
	}
}
public ZBDIUK(Client)
{
	if (Touke[Client] == 1)
	{
		Touke[Client] = 0;
		EpHealth[Client] -= 10;	    
		EpEndurance[Client] -= 10;
		CPrintToChat(Client, "{green}��װ�����㶪��������ͷ��!"); 
	}
}
public ZBDIUQ(Client)
{
	if (Jiake[Client] == 1)
	{   
		Jiake[Client] = 0;
		EpStr[Client] -= 100;
		EpEndurance[Client] -= 50;
		CPrintToChat(Client, "{green}��װ�����㶪�������黤��!"); 
	}
}
public ZBDIUA(Client)
{
	if (Xieke[Client] == 1)
	{   
		Xieke[Client] = 0;
		EpStr[Client] -= 15;
		CPrintToChat(Client, "{green}��װ�����㶪��������Ь��!"); 
	}
}
public ZBDIUR(Client)
{
	if (Kuke[Client] == 1)
	{   
		Kuke[Client] = 0;
		EpHealth[Client] -= 50;
		CPrintToChat(Client, "{green}��װ�����㶪�����������!"); 
	}
}
public ZBDIUY(Client)
{
	if (Wuqi[Client] == 1)
	{   
		Wuqi[Client] = 0;
		EpStr[Client] -= 100;
		CPrintToChat(Client, "{green}��װ�����㶪��������ǹ!"); 
	}
}

/* ͷ������˵�� */
public Action:MenuFunc_Chash(Client)
{
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Touke[Client] == 1)
	{   
		Format(line, sizeof(line), "�T�T�T����ͷ��[����: ����+10 ����+10 ����Ч��: ÿ���Զ��ָ�1������ֵ]�T�T�T");      
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "����: ��˵��ңԶ��δ��, ɥʬ��Ű~��ѧ���о�����һ��ר�ŶԿ���ʬ����װ, ӵ��ǿ���ս��, ����ʱ�յĸ���, �����͵�������");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "������װ[������װ] ��δ��սʿר����");      
		DrawPanelText(menu, line);   
	}    
	
	DrawPanelItem(menu, "��������װ���˵�");  
	DrawPanelItem(menu, "����", ITEMDRAW_DISABLED);    
	SendPanelToClient(menu, Client, MenuHandler_Chasq, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chash(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* ���׽���˵�� */
public Action:MenuFunc_Chasq(Client)
{  
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Jiake[Client] == 1)
	{	    
		Format(line, sizeof(line), "�T�T�T���黤��[����: ����+100 ����+50 ����Ч��: �����˹�����ʱʱ��ȡ80%���˺�ת������������ֵ]�T�T�T");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "����: ��˵��ңԶ��δ��, ɥʬ��Ű~��ѧ���о�����һ��ר�ŶԿ���ʬ����װ, ӵ��ǿ���ս��, ����ʱ�յĸ���, �����͵�������");       
		DrawPanelText(menu, line);		
		Format(line, sizeof(line), "������װ[������װ] ��δ��սʿר����");       
		DrawPanelText(menu, line);   
	}
    	
	DrawPanelItem(menu, "��������װ���˵�");   
	DrawPanelItem(menu, "����", ITEMDRAW_DISABLED);   
	SendPanelToClient(menu, Client, MenuHandler_Chasq, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasq(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* Ь�ӽ���˵�� */
public Action:MenuFunc_Chasa(Client)
{   
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Xieke[Client] == 1)
	{	    
		Format(line, sizeof(line), "�T�T�T����Ь��[����: ����+15 ����Ч��: �ƶ��ٶ�����10%]�T�T�T");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "����: ��˵��ңԶ��δ��, ɥʬ��Ű~��ѧ���о�����һ��ר�ŶԿ���ʬ����װ, ӵ��ǿ���ս��, ����ʱ�յĸ���, �����͵�������");       
		DrawPanelText(menu, line);		
		Format(line, sizeof(line), "������װ[������װ] ��δ��սʿר����");       
		DrawPanelText(menu, line);   
	}
    	
	DrawPanelItem(menu, "��������װ���˵�");   
	DrawPanelItem(menu, "����", ITEMDRAW_DISABLED);  
	SendPanelToClient(menu, Client, MenuHandler_Chasa, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasa(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* ���ӽ���˵�� */
public Action:MenuFunc_Chasz(Client)
{   
	new Handle:menu = CreatePanel();
	   
	decl String:line[2024];   
	if(Kuke[Client] == 1)	
	{	    
		Format(line, sizeof(line), "�T�T�T�������[����: ����+50 ����Ч��: ��������100��������]�T�T�T");       
		SetPanelTitle(menu, line);      
		Format(line, sizeof(line), "����: ��˵��ңԶ��δ��, ɥʬ��Ű~��ѧ���о�����һ��ר�ŶԿ���ʬ����װ, ӵ��ǿ���ս��, ����ʱ�յĸ���, �����͵�������");      
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "������װ[������װ] ��δ��սʿר����");     
		DrawPanelText(menu, line);    
	}
    	
	DrawPanelItem(menu, "��������װ���˵�");   
	DrawPanelItem(menu, "����", ITEMDRAW_DISABLED);   
	SendPanelToClient(menu, Client, MenuHandler_Chasz, MENU_TIME_FOREVER);   
	return Plugin_Handled;
}

public MenuHandler_Chasz(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}

/* ��������˵�� */
public Action:MenuFunc_Chasw(Client)
{    
	new Handle:menu = CreatePanel();
	    
	decl String:line[2024];    
	if(Wuqi[Client] == 1)	
	{	    
		Format(line, sizeof(line), "�T�T�T����ǹ[����: ����+100  ����Ч��: ��������ʱ��ȡ10%���˺�ת������������ֵ]�T�T�T");       
		SetPanelTitle(menu, line);       
		Format(line, sizeof(line), "����: ��˵��ңԶ��δ��, ɥʬ��Ű~��ѧ���о�����һ��ר�ŶԿ���ʬ����װ, ӵ��ǿ���ս��, ����ʱ�յĸ���, �����͵�������");       
		DrawPanelText(menu, line);	
		Format(line, sizeof(line), "������װ[������װ] ��δ��սʿר����");      
		DrawPanelText(menu, line);    
	}
    	
	DrawPanelItem(menu, "��������װ���˵�");   
	DrawPanelItem(menu, "����", ITEMDRAW_DISABLED); 
	SendPanelToClient(menu, Client, MenuHandler_Chasw, MENU_TIME_FOREVER);  
	return Plugin_Handled;
}

public MenuHandler_Chasw(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select) 
	{
		switch (param)
		{
            case 1: MenuFunc_Zhuang(Client);			
		}
	}
}