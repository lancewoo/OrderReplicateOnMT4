//+------------------------------------------------------------------+
//|                                        OrderFollowingWuliang.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

// Imports from the QuickChannel library
#import "FXBlueQuickChannel.dll"
   int QC_StartReceiverW(string, int);
   int QC_ReleaseReceiver(int);
   int QC_GetMessages5W(int, uchar&[], int);
#import

// Kernel logging function whose output can be viewed in Dbgview
// (http://technet.microsoft.com/en-us/sysinternals/bb896647). 
// Easy way of checking how quickly messages are being transmitted.
#import "kernel32.dll"
   void OutputDebugStringA(string msg);
#import

// External, user-configurable properties
extern string  ChannelName = "OrderMonitor";
extern bool    ReverseOrder = true; // reverse orders by default
extern double  DupLots = 1; // how many lots do you want to replicate each time?
extern double  StopLoss = 0.0; // StopLoss for each order
extern int  Slippage = 3;
extern bool    LogMessagesToDbgView = true;


// Handle which is acquired during start() and freed during deinit()
int glbHandle = 0;

#define QC_BUFFER_SIZE  10000

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("-----------OnInit---------------");
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // EventKillTimer();
    if (glbHandle) {
        QC_ReleaseReceiver(glbHandle);
    }
    glbHandle = 0;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Print("-----------OnTick---------------");

    // Initialise receiving via QuickChannel. Return value is 1 if successful, or 0
    // if initialisation fails. This handle gets stored in a global variable
    // for later use in start()
    if (glbHandle == 0) {
        glbHandle = QC_StartReceiverW(ChannelName, WindowHandle(Symbol(), Period()));

        if (glbHandle == 0) {
            Alert("Failed to get a QuickChannel receiver handle");
            return;
        }
    }

    uchar buffer[];
    ArrayResize(buffer, QC_BUFFER_SIZE);
    int res = QC_GetMessages5W(glbHandle, buffer, QC_BUFFER_SIZE);

    if (res == -1) {
        Alert("QuickChannel encountered an error:" + GetLastError());
        return;
    } else if (res == 0) {
        // No pending messages 
        return;
    }
    
    string strMsgList;
    if (res > 0) {
        strMsgList = CharArrayToString(buffer, 0, res);
        // If we get a message from the sender, then
        // we simply log it.
        if (LogMessagesToDbgView) OutputDebugStringA("QuickChannel message received:" + strMsgList);
        Print("QuickChannel message received:" + strMsgList);
    }

    if (strMsgList == "") {
        return;
    }

    // There may be either one message, or multiple messages 
    // separated by tabs.
    //
    // The list is in the order that the messages were sent.
    // In some scenarios you may need to process it
    // in REVERSE ORDER, e.g. because the list includes 
    // two prices for the same symbol and you only want
    // to use the more recent report.

    string msg[];
    string sep = "\t";                // A separator as a character
    ushort u_sep;                  // The code of the separator character 
    u_sep = StringGetCharacter(sep, 0); //--- Get the separator code 

    StringSplit(strMsgList, u_sep, msg);

    sep = "|"; // order properties are separated by '|'
    u_sep = StringGetCharacter(sep, 0); 
    for (int i = 0; i < ArraySize(msg); i++) {
        string strMsg = msg[i];
        // Comment(strMsg);
        // Print(i + ":" +strMsg);

        string prop[];
        // a message is like :
        // 355072|GOLD|Close|0|17:05:59|1250.50|0.10
        // which are properties in sequence:
        // OrderTicket()|OrderSymbol()|"Open" or "Close"|OrderType() 0 or 1|OrderOpenTime() or OrderCloseTime()
        // |OrderOpenPrice() or OrderClosePrice()|OrderLots()
        int k = StringSplit(strMsg, u_sep, prop);
        if (k != 7) {
            Print("" + i + ". message [" + strMsg + "] was not properly split.");
            continue;
        }

        int err;
        string symbol;
        if (ReverseOrder) {
            // reverse the order
            if (prop[2] == "Open") {
                // open an order
                if (prop[1] == "LLG") {
                    symbol = "XAUUSD";
                }
                // we use the original ticket number as the new order's magic number
                if (prop[3] == "0") {
                    k = OrderSend(symbol, OP_SELL, DupLots, Bid, Slippage, StopLoss, 0
                        , "Reverse-Sell|"+strMsg, StringToInteger(prop[0]));

                    Print( "Reverse-Sell, k=" + k );
                    if (k<0) {
                        err = GetLastError();
                        Print( "ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
                } else {
                    k = OrderSend(symbol, OP_BUY, DupLots, Ask, Slippage, StopLoss, 0
                        , "Reverse-Buy|"+strMsg, StringToInteger(prop[0]));

                    Print( "Reverse-Buy, k=" + k );
                    if (k<0) {
                        err = GetLastError();
                        Print( "ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
                }
            } else {
                // close an order
                bool r;
                int magic = StringToInteger(prop[0]);
                int total = OrdersTotal();
                if (total == 0) {
                    // no open orders
                    return;
                }

                // find the order which has the magic number
                // and get its ticket number for later use
                int ticket = -1;
                for (int pos=0; pos<total; pos++) {
                    if (OrderSelect(pos, SELECT_BY_POS) == false)
                        continue;
                    if (magic == OrderMagicNumber()) {
                        ticket = OrderTicket();
                        break;
                    }
                }
                if (ticket < 0) {
                    return;
                }

                // close the order now
                if (prop[3] == "0") {
                    r = OrderClose(ticket, DupLots, Ask, Slippage);
                } else {
                    r = OrderClose(ticket, DupLots, Bid, Slippage);
                }
                if (!r) {
                    err = GetLastError();
                    Print("OrderClose() failed ErrorCode:" + err + "," + ErrorDescription(err));
                    return;
                }

            }
        }
    }

}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+ 
//| OnTimer event handler                                            | 
//+------------------------------------------------------------------+ 
void OnTimer() 
{ 
    //--- 
    Print(" __FUNCTION__ = ", __FUNCTION__, "  __LINE__ = ", __LINE__); 

} 
