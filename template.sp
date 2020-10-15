#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "获取及设置管理员权限",
	description = "",
	author = "BAKA",
	version = "1.0",
	url = "https://baka.cirno.cn"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_votecvar", Command_VoteCvar, "投票更改服务器参数");
	RegServerCmd("sm_restore", Command_Restore, "恢复默认值");
	RegAdminCmd("sm_vote_no", Command_VotesNo, ADMFLAG_ROOT, "管理员一键否决投票");
}

