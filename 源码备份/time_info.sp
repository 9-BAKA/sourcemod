#include <sourcemod>
#include <sdktools>

#define UTC_BASE_YEAR 1970
#define MONTH_PER_YEAR 12
#define DAY_PER_YEAR 365
#define SEC_PER_DAY 86400
#define SEC_PER_HOUR 3600
#define SEC_PER_MIN 60

public Plugin:myinfo = 
{
	name = "服务器时间提示",
	author = "BAKA",
	description = "到达安全时间提示以及服务器事件提示",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()  // 或许应该使用sql存储时间？
{
	RegConsoleCmd("sm_time", Time, "获取当前时间");
	decl String:buffer[256];
	int utc_sec = GetTime() + 8 * SEC_PER_HOUR;
	utc_sec_2_mytime(utc_sec, false, buffer);
	PrintToChatAll("\x04[提示]\x01当前的服务器时间为: \x03%s", buffer);
	CreateTimer(600.0, PrintTime, 0, 1);  // 开始计时器
}

public Action:PrintTime(Handle:timer, any:client)
{
	decl String:buffer[256];
	int utc_sec = GetTime() + 8 * SEC_PER_HOUR;
	utc_sec_2_mytime(utc_sec, false, buffer);
	PrintToChatAll("\x04[提示]\x01当前的服务器时间为: \x03%s", buffer);
}

public Action:Time(client, agrs)
{
	decl String:buffer[256];
	int utc_sec = GetTime() + 8 * SEC_PER_HOUR;
	utc_sec_2_mytime(utc_sec, false, buffer);
	PrintToChatAll("\x04[提示]\x01当前的服务器时间为: \x03%s", buffer);
	return Plugin_Continue;
}

/* 每个月的天数 */
new Int:g_day_per_mon[MONTH_PER_YEAR] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

int applib_dt_is_leap_year(int year)
{
    if ((year % 400) == 0) {
        return 1;
    } else if ((year % 100) == 0) {
        return 0;
    } else if ((year % 4) == 0) {
        return 1;
    } else {
        return 0;
    }
}

int applib_dt_last_day_of_mon(int month, int year)
{
    if ((month == 0) || (month > 12)) {
        return g_day_per_mon[1] + applib_dt_is_leap_year(year);
    }

    if (month != 2) {
        return g_day_per_mon[month - 1];
    } else {
        return g_day_per_mon[1] + applib_dt_is_leap_year(year);
    }
}

int applib_dt_dayindex(int year, int month, int day)
{
    int century_code, year_code, month_code, day_code;
    int week = 0;

    century_code = year_code = month_code = day_code = 0;

    if (month == 1 || month == 2) {
        century_code = (year - 1) / 100;
        year_code = (year - 1) % 100;
        month_code = month + 12;
        day_code = day;
    } else {
        century_code = year / 100;
        year_code = year % 100;
        month_code = month;
        day_code = day;
    }

    /* 根据蔡勒公式计算星期 */
    week = year_code + year_code / 4 + century_code / 4 - 2 * century_code + 26 * ( month_code + 1 ) / 10 + day_code - 1;
    week = week > 0 ? (week % 7) : ((week % 7) + 7);

    return week;
}

/*
 * 功能：
 *     根据UTC时间戳得到对应的日期
 * 参数：
 *     utc_sec：给定的UTC时间戳
 *     result：计算出的结果
 *     daylightSaving：是否是夏令时
 *
 * 返回值：
 *     无
 */
void utc_sec_2_mytime(int utc_sec, bool daylightSaving=false, String:buffer[])
{
    int sec, day, y, m, d, dst, dayIndex;

    if (daylightSaving) {
        utc_sec += SEC_PER_HOUR;
    }

    /* hour, min, sec */
    /* hour */
    int nHour, nMin, nSec, nYear, nMonth, nDay;
    sec = utc_sec % SEC_PER_DAY;
    nHour = sec / SEC_PER_HOUR;

    /* min */
    sec %= SEC_PER_HOUR;
    nMin = sec / SEC_PER_MIN;

    /* sec */
    nSec = sec % SEC_PER_MIN;

    /* year, month, day */
    /* year */
    /* year */
    day = utc_sec / SEC_PER_DAY;
    for (y = UTC_BASE_YEAR; day > 0; y++) {
        d = (DAY_PER_YEAR + applib_dt_is_leap_year(y));
        if (day >= d)
        {
            day -= d;
        }
        else
        {
            break;
        }
    }

    nYear = y;

    for (m = 1; m < MONTH_PER_YEAR; m++) {
        d = applib_dt_last_day_of_mon(m, y);
        if (day >= d) {
            day -= d;
        } else {
            break;
        }
    }

    nMonth = m;
    nDay = day + 1;
    /* 根据给定的日期得到对应的星期 */
    dayIndex = applib_dt_dayindex(nYear, nMonth, nDay);

	//Format(buffer, 255, "%d-%d-%d %d时%d分%d秒 %i", nYear, nMonth, nDay, nHour, nMin, nSec, dayIndex);
	Format(buffer, 255, "%d-%d-%d %d时%d分%d秒", nYear, nMonth, nDay, nHour, nMin, nSec);
}
