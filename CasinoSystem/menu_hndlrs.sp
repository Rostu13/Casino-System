#include <sourcemod>
public int MainMenu_(Menu menu, MenuAction action, int param1, int param2)
{
    // case - лучше для глаз - хуже для сервера
    if(action == MenuAction_End) delete menu;
    else if(action == MenuAction_Select)
    {
        char sBuffer[4];
        menu.GetItem(param2,sBuffer,sizeof sBuffer);
        switch(sBuffer[0])
        {
            case 'a':
            {
                OpenSelectTypeGame(param1);
            }
            case 'b':
            {
                ConvectorChips(param1);
            }
            case 'c':
            {
                OpenPlayerStats(param1,param1);
            }
            case 'd':
            {
                //OpenSettings(param1);
            }
            case 'e':
            {
                CreateAdminMenu(param1);
            }
        }
    }

    return 0;
}
public int SelectTypeGame_(Menu menu, MenuAction action, int param1, int param2)
{

    if(action == MenuAction_End) delete menu;
    else if(action == MenuAction_Select)
    {
        SelectGame(param1,param2);
    }

    return 0;
}
public int SelectGame_(Menu menu, MenuAction action, int param1, int param2)
{

    if(action == MenuAction_End) delete menu;
    else if(action == MenuAction_Select)
    {
        char sName[32];
        menu.GetItem(param2,sName,sizeof sName);

        Call_StartForward(g_hForwardGameOnMenuChoose);
        Call_PushCell(param1);
        Call_PushString(sName);
        Call_Finish();
    }

    return 0;
}
public int ConvectorChips_ (Menu menu, MenuAction action, int param1, param2)
{
    if(action == MenuAction_End) delete menu;
    else if (action == MenuAction_Select)
    {
        char sName[32];
        menu.GetItem(param2,sName,sizeof sName);

        Call_StartForward( g_hForwardClientChooseConvector );
        Call_PushCell(param1);
        Call_PushString(sName);
        Call_Finish();
    }
}
public int Stats_(Menu menu, MenuAction action, int param1, int param2)
{

    if(action == MenuAction_End) delete menu;
    else if(action == MenuAction_Select)
    {
        /*
        if(param2 == 0)
        {
            char sId[8];
            menu.GetItem(param2,sId,sizeof sId);
            OpenOtherGameStats(param1,StringToInt(sId));
        }
        */
        if(param2 == 0)
        {
            OpenListPlayerForStats(param1);
        }
        else 
        {
            OpenMainMenu(param1);
        }
    }
}
public int SelectPlayerStats_(Menu menu, MenuAction action, int param1, int param2)
{

    if(action == MenuAction_End) delete menu;
    else if(action == MenuAction_Select)
    {
        char sUserId[16];
        menu.GetItem(param2,sUserId,sizeof sUserId);

        int iTarget = GetClientOfUserId(StringToInt(sUserId));
        if(iTarget)
        {
            OpenPlayerStats(param1,iTarget);
        }
        else 
        {
            CGOPrintToChat(param1,"Игрок больше недоступен!");
        }
    }
}