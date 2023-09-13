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
extern string  SymbolIn = "XAUUSD"; // Symbol to be copied
extern string  SymbolTrading = "XAUUSD"; // Symbol to be traded
extern bool    SymbolInCheck = false; // 是否检查交易品种代码，如果不检查，不管什么品种每来一个单子都会跟。 如果检查，会严格按照指定的品种交易。
                                      // Whether the symbol to be copied should be checked
extern double  DupLots = 1; // Number of lots you want to copy each time
extern double  StopLoss = 0.0; // Stoploss for each order
extern int  Slippage = 99; // Slippage pips
extern bool    LogMessagesToDbgView = true;


// Handle which is acquired during start() and freed during deinit()
int glbHandle = 0;
// log file handler
int logFile = 0;

#define QC_BUFFER_SIZE  10000

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    logFile = FileOpen("OrderReplicate.txt"
            , FILE_READ|FILE_WRITE|FILE_TXT|FILE_UNICODE|FILE_SHARE_READ|FILE_SHARE_WRITE); 
    if (logFile == INVALID_HANDLE) {
        return INIT_FAILED;
        Print("-----------OnInit FileOpen failed!---------------");
    }
    FileSeek(logFile, 0, SEEK_END);
    FileWrite(logFile, TimeLocal(), ",", "-----------OnInit---------------");
    FileFlush(logFile);
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
    FileWrite(logFile, TimeLocal(), ",", "-----------OnDeinit---------------");
    FileFlush(logFile);
    if (logFile) {
        FileClose( logFile );
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
            FileWrite(logFile, TimeLocal(), ",", "Failed to get a QuickChannel receiver handle");
            FileFlush(logFile);
            Alert("Failed to get a QuickChannel receiver handle");
            return;
        }
    }

    uchar buffer[];
    ArrayResize(buffer, QC_BUFFER_SIZE);
    int res = QC_GetMessages5W(glbHandle, buffer, QC_BUFFER_SIZE);

    if (res == -1) {
        string errMsg = "QuickChannel encountered an error:" + GetLastError();
        FileWrite(logFile, TimeLocal(), ",", errMsg);
        FileFlush(logFile);
        Alert(errMsg);
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
        FileWrite(logFile, TimeLocal(), ",", "QuickChannel message received:" + strMsgList);
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
        // 355072|GOLD|Close|0|R|17:05:59|1250.50|0.10
        // which are properties in sequence:
        // OrderTicket()
        // |OrderSymbol()
        // |"Open" or "Close"
        // |OrderType() 0 or 1
        // |"R" or "F"
        // |OrderOpenTime() or OrderCloseTime()
        // |OrderOpenPrice() or OrderClosePrice()
        // |OrderLots()
        int k = StringSplit(strMsg, u_sep, prop);
        if (k != 8) {
            FileWrite(logFile, TimeLocal(), ",", "" + i + ". message [" + strMsg + "] was not properly split.");
            Print("" + i + ". message [" + strMsg + "] was not properly split.");
            continue;
        }

        string symbol = prop[1];

        // if the incoming symbol is not checked,
        // we assume that symbol is the same as this one to be traded.
        if (SymbolInCheck) {
            if (prop[1] != SymbolIn) {
                FileWrite(logFile, TimeLocal(), ",", "" + i + ". 跟踪品种 [" + prop[1] + "] 与指定品种[" + SymbolIn + "]不同，不跟单。");
                Print("" + i + ". 跟踪品种 [" + prop[1] + "] 与指定品种[" + SymbolIn + "]不同，不跟单。");
                continue;
            } else {
                symbol = SymbolTrading;
            }
        }

        int err;
        bool reverseOrder;
        if (prop[4] == "R") {
            reverseOrder = true;
        } else {
            reverseOrder = false;
        }
        // reverse the order
        if (prop[2] == "Open") {
            // open an order
            if (reverseOrder) {
                // reverse the original order
                // we use the original ticket number as the new order's magic number
                if (prop[3] == "0") {
                    Print( "Reverse-Sell, before OrderSend");
                    k = OrderSend(symbol, OP_SELL, DupLots, Bid, Slippage, StopLoss, 0
                        , "Reverse-Sell|"+strMsg, StringToInteger(prop[0]));

                    FileWrite(logFile, TimeLocal(), ",", "Reverse-Sell, ticket=" + k);
                    Print( "Reverse-Sell, ticket=" + k );
                    if (k<0) {
                        err = GetLastError();
                        FileWrite(logFile, TimeLocal(), ",", "Reverse-Sell, ErrorCode:" + err + "," + ErrorDescription(err));
                        Print( "Reverse-Sell, ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
                } else {
                    Print( "Reverse-Buy, before OrderSend");
                    k = OrderSend(symbol, OP_BUY, DupLots, Ask, Slippage, StopLoss, 0
                        , "Reverse-Buy|"+strMsg, StringToInteger(prop[0]));

                    FileWrite(logFile, TimeLocal(), ",", "Reverse-Buy, ticket=" + k);
                    Print( "Reverse-Buy, ticket=" + k );
                    if (k<0) {
                        err = GetLastError();
                        FileWrite(logFile, TimeLocal(), ",", "Reverse-Buy failed, ErrorCode:" + err + "," + ErrorDescription(err));
                        Print( "Reverse-Buy failed, ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
                }
            } else {
                // simply follow the original order
                if (prop[3] == "1") {
                    Print( "Forward-Sell, before OrderSend");
                    k = OrderSend(symbol, OP_SELL, DupLots, Bid, Slippage, StopLoss, 0
                        , "Forward-Sell|"+strMsg, StringToInteger(prop[0]));

                    FileWrite(logFile, TimeLocal(), ",", "Forward-Sell, ticket=" + k);
                    Print( "Forward-Sell, ticket=" + k );
                    if (k<0) {
                        err = GetLastError();
                        FileWrite(logFile, TimeLocal(), ",", "Forward-Sell, ErrorCode:" + err + "," + ErrorDescription(err));
                        Print( "Forward-Sell, ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
                } else {
                    Print( "Forward-Buy, before OrderSend");
                    k = OrderSend(symbol, OP_BUY, DupLots, Ask, Slippage, StopLoss, 0
                        , "Forward-Buy|"+strMsg, StringToInteger(prop[0]));

                    FileWrite(logFile, TimeLocal(), ",", "Forward-Buy, ticket=" + k);
                    Print( "Forward-Buy, ticket=" + k );
                    if (k<0) {
                        err = GetLastError();
                        FileWrite(logFile, TimeLocal(), ",", "Forward-Buy failed, ErrorCode:" + err + "," + ErrorDescription(err));
                        Print( "Forward-Buy failed, ErrorCode:" + err + "," + ErrorDescription(err) );
                    }
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
            for (int pos=0; pos<10; pos++) {
                FileWrite(logFile, TimeLocal(), ",", "OrderClose("+ticket+") begins.");
                Print("OrderClose("+ticket+") begins.");

                if (prop[3] == "0") {
                    if (reverseOrder) {
                        r = OrderClose(ticket, DupLots, Ask, Slippage);
                    } else {
                        r = OrderClose(ticket, DupLots, Bid, Slippage);
                    }
                } else {
                    if (reverseOrder) {
                        r = OrderClose(ticket, DupLots, Bid, Slippage);
                    } else {
                        r = OrderClose(ticket, DupLots, Ask, Slippage);
                    }
                }
                FileWrite(logFile, TimeLocal(), ",", "OrderClose("+ticket+") returned:" + r);
                Print("OrderClose("+ticket+") returned:" + r);

                if (!r) {
                    err = GetLastError();
                    FileWrite(logFile, TimeLocal(), ",", "OrderClose("+ticket+") failed ErrorCode:" + err + "," + ErrorDescription(err) + ", try:" + pos);
                    Print("OrderClose("+ticket+") failed ErrorCode:" + err + "," + ErrorDescription(err) + ", try:" + pos);
                    Sleep( 1000 ); // sleep for 1 second and have another try
                    continue;
                }
                break;
            }
        }
    }
    FileFlush(logFile);
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
