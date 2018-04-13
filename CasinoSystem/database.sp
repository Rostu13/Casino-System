#include <sourcemod>
void Casino_DBConnect()
{
    Database.Connect(Connect_CallBack,"CasinoSystem");
}
public void Connect_CallBack(Database hDatabase, const char[] sError, any data) 
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError); 
		return;
	}

	g_hDB = hDatabase; 

    SQL_LockDatabase(g_hDB);

    DB_TQueryEx(	"CREATE TABLE IF NOT EXISTS `casino_players` (\
															`id` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,\
															`auth` VARCHAR(32) NOT NULL,\
															`name` VARCHAR(32) DEFAULT 'N/A',\
															`total` INTEGER default '0',\
															`win` INTEGER default '0',\
															`lost` INTEGER default '0',\
															`totalgames` INTEGER  default '0',\
															`totalwingames` INTEGER default '0',\
                                                            `totallostgames` INTEGER  default '0',\
                                                            `settings` VARCHAR(128) DEFAULT 'N/A');");
															
	DB_TQueryEx(	"CREATE TABLE IF NOT EXISTS `casino_modules` (\
															`id` INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,\
															`name_unique` VARCHAR(32) DEFAULT 'N/A',\
															`name_normal` VARCHAR(32) DEFAULT 'N/A');");		

    SQL_UnlockDatabase(g_hDB);
    
	g_hDB.SetCharset("utf8"); 

	

}
void DB_TQuery(SQLQueryCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
	g_hDB.Query(callback, query, data, prio);
}
//CheckError
void DB_TQueryEx(const char[] query, DBPriority prio = DBPrio_Normal)
{
	
	g_hDB.Query(DB_ErrorCheck, query, _, prio);
}
public void DB_ErrorCheck(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
		LogError("SQL_Callback_CheckError: %s", szError);
}
public void ClientConnect_CallBack(Database hDatabase, DBResultSet hResults, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("ClientConnect_CallBack: %s", szError);
		return;
	}
}
public void MyStats_CallBack(Database hDatabase, DBResultSet hResults, const char[] szError, int iUserId)
{
	if(szError[0])
    {
		LogError("MyStats_CallBack: %s", szError);
        //delete hPack;
        return;
    }
   // hPack.Reset();

   // int iClient = GetClientOfUserId(hPack.ReadCell());
   // int iTargetId = hPack.ReadCell();
   // delete hPack;
    int iClient = GetClientOfUserId(iUserId);
    if(iClient)
    {
        if(hResults.FetchRow())
        {
            char sName[32];
            hResults.FetchString(0,sName,sizeof sName);
            int iTotal =                 hResults.FetchInt(1);
            int iWin =                   hResults.FetchInt(2);
            int iLost =                  hResults.FetchInt(3);
            int iTotalGames =            hResults.FetchInt(4);
            int iTotalWinGames =         hResults.FetchInt(5);
            int iTotalLostGames =        hResults.FetchInt(6);

            Menu menu = new Menu(Stats_);
            menu.ExitButton = false;

            menu.SetTitle("----------Статистика игрока----------\nИгрок: %s\nВсего поставлено фишек: %d\nВыиграл: %d\nПроиграл: %d\nВсего игр: %d\nВыиграл: %d\nПроиграл: %d",
            sName, iTotal,iWin,iLost,iTotalGames,iTotalWinGames,iTotalLostGames);

            //char sId[8];
            //IntToString(iTargetId,sId,sizeof sId);

            //menu.AddItem(sId,"Статистика по играм");
            menu.AddItem("","Статистика других игроков");
            menu.AddItem("","Назад");

            menu.Display(iClient, 0);

        }
    }
}