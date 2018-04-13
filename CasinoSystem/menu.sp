#include <sourcemod>
void OpenMainMenu(int iClient)
{
	char errormsg[128];

	Action res; // 0 - Plugin_Continue
	Call_StartForward(g_hForwardClientOpenMainMenu);
    Call_PushCell(iClient);
	Call_PushStringEx( errormsg, sizeof( errormsg ), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK );
    Call_PushCell( sizeof( errormsg ) );

	int error = Call_Finish( res );
    
    if ( error != SP_ERROR_NONE )
    {
        LogError( "Error occured when finishing Casino_ClientOpenMainMenu forward!" );
    }
    
    if ( res != Plugin_Continue )
    {
        if ( errormsg[0] == '\0' )
        {
            strcopy( errormsg, sizeof( errormsg ), "Что-то блокирует доступ и не пишется ошибку. Обратитесь к Создателю сервера!" );
        }
        
		CGOPrintToChat(iClient, errormsg );
        
		return;
    }
	


    Menu menu = new Menu (MainMenu_);
    menu.SetTitle ("------------Casino System------------\n%s",GetBalanse(iClient));

    menu.AddItem("a","Игры");
    menu.AddItem("b","Управление балансом", g_bUsedConverter ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    menu.AddItem("c","Моя статистика");
    menu.AddItem("d","Настройки");
    if(g_bUsedAdminSystem && (GetUserFlagBits(iClient) & g_iAdminFlag) )
	{
		menu.AddItem("e","Админ Меню");
	}
    menu.Display(iClient, MENU_TIME_FOREVER);
	
}
void  OpenSelectTypeGame (int iClient)
{
    Menu menu = new Menu(SelectTypeGame_);

    menu.SetTitle("%sВыберите тип игры:",GetBalanse(iClient));

    menu.AddItem("","Одиночные игры");
    menu.InsertItem(3,"","Игры на двоих");

    menu.Display(iClient, MENU_TIME_FOREVER);
}
void SelectGame (int iClient, int iTypeGame)
{
    Menu menu = new Menu(SelectGame_);

    menu.SetTitle("%sВыберите игру:",GetBalanse(iClient));

    Call_StartForward(g_hForwardGameOnMenuCreate);
    Call_PushCell(view_as<int>(menu));
    Call_PushCell(iTypeGame);
    Call_PushCell(iClient);
    Call_Finish();

    menu.Display(iClient, MENU_TIME_FOREVER);
}
void ConvectorChips(int iClient)
{
    Menu menu = new Menu (ConvectorChips_);

    menu.SetTitle("%sУправление балансом\nВыберите через что хотите пополнить фишки:",GetBalanse(iClient));

    Call_StartForward(g_hForwardGameOnMenuCreate);
    Call_PushCell(view_as<int>(menu));
    Call_PushCell(iClient);
    Call_Finish();

    menu.Display(iClient, MENU_TIME_FOREVER);

}
void OpenPlayerStats(int iClient, int iTarget)
{
    char sQuery[128];
    FormatEx(sQuery,sizeof sQuery,"SELECT `name`,`total`, `win`, `lost`,`totalgames`, `totalwingames`, `totallostgames` WHERE `id` = %d",g_iId[iTarget]);
    DB_TQuery(MyStats_CallBack,sQuery,GetClientOfUserId(iClient),DBPrio_High);
}
void OpenListPlayerForStats(int iClient)
{
    Menu menu = new Menu(SelectPlayerStats_);

    ListPlayer(menu,false) // Генерируем "готовых" игроков

    menu.Display(iClient, 0);
}
// ==============================================================================================================================
// >>> Админ меню
// ==============================================================================================================================
void CreateAdminMenu(int iClient)
{
    Menu menu = new Menu(Admin_);

    menu.SetTitle("------------------Администратирование------------------\nВыберите что хотите сделать:");

    // >>> Стандартные пункты
    menu.AddItem("a","Прибавить фишек");
    menu.AddItem("b","Отнять фишки");
    menu.AddItem("c","Установить фишки");

    Call_StartForward(g_hForwardGameOnMenuCreate);
    Call_PushCell(view_as<int>(menu));
    Call_PushCell(iClient);
    Call_Finish();

    menu.Display(iClient,MENU_TIME_FOREVER);
}