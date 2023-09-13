//+------------------------------------------------------------------+
//|                                                 OrderMonitor.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

// DLL imports from the QuickChannel library. Requires "Allow DLL imports"
// to be turned on
#import "FXBlueQuickChannel.dll"
   int QC_StartSenderW(string);
   int QC_ReleaseSender(int);
   int QC_SendMessageW(int, string&, int);
#import

// Kernel logging function whose output can be viewed in Dbgview
// (http://technet.microsoft.com/en-us/sysinternals/bb896647). 
// Easy way of checking how quickly messages are being transmitted.
#import "kernel32.dll"
   void OutputDebugStringA(string msg);
#import

// External, user-configurable properties
extern string  ChannelName = "OrderMonitor";
extern bool    ReverseOrder = true; // set it true to reverse orders, otherwise false
extern bool    LogMessagesToDbgView = true;

// Handle which is acquired during init() and freed during deinit()
int glbHandle = 0;
// log file handler
int logFile = 0;

// number of orders currently held
int gOrdersTotal = 0;
// number of history orders
int gOrdersHistoryTotal = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //Print( "Year():" + Year() + ",Month():" +Month() + ",Day():" + Day() + ",Hour():" + Hour() + ":" + Minute());
    // if (Year()==2016 && Month()>6 || Year()>2016) {
    //     // a stupid license control
    //     return INIT_FAILED;
    // }
    logFile = FileOpen("OrderMonitor-" + AccountInfoInteger(ACCOUNT_LOGIN) + ".txt"
            , FILE_READ|FILE_WRITE|FILE_TXT|FILE_UNICODE|FILE_SHARE_READ|FILE_SHARE_WRITE); 
    if (logFile == INVALID_HANDLE) {
        return INIT_FAILED;
        Print("-----------OnInit FileOpen failed!---------------");
    }
    FileSeek(logFile, 0, SEEK_END);
    FileWrite(logFile, TimeLocal(), ",", "-----------OnInit---------------");
    FileFlush(logFile);

    // Initialise sending via QuickChannel.
    glbHandle = QC_StartSenderW(ChannelName);
   
    if (glbHandle == 0) {
        FileWrite(logFile, TimeLocal(), ",", "Failed to get a QuickChannel sender handle");
        FileFlush(logFile);
        Alert("Failed to get a QuickChannel sender handle");
        return INIT_FAILED;
    }

    gOrdersTotal = OrdersTotal();
    if (gOrdersTotal > 0) {
        FileWrite(logFile, TimeLocal(), ",", "OnInit(): There are " + gOrdersTotal + " open orders in total.");
        Print( "OnInit(): There are " + gOrdersTotal + " open orders in total." );
    } else {
        FileWrite(logFile, TimeLocal(), ",", "OnInit(): There are no open orders.");
        Print( "OnInit(): There are no open orders." );
    }
    gOrdersHistoryTotal = OrdersHistoryTotal();
    if (gOrdersHistoryTotal > 0) {
        FileWrite(logFile, TimeLocal(), ",", "OnInit(): There are " + gOrdersHistoryTotal + " history orders in total.");
        Print( "OnInit(): There are " + gOrdersHistoryTotal + " history orders in total." );
    } else {
        FileWrite(logFile, TimeLocal(), ",", "OnInit(): There are no history orders.");
        Print( "OnInit(): There are no history orders." );
    }
    FileFlush(logFile);

    EventSetMillisecondTimer(50);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    // Release resources associated with the sending which was
    // initialised earlier
    QC_ReleaseSender(glbHandle);
    glbHandle = 0;

    FileWrite(logFile, TimeLocal(), ",", "-----------OnDeinit---------------");
    FileFlush(logFile);
    FileClose(logFile);
}


void OnTimer()
{
    if (glbHandle == 0) {
        FileWrite(logFile, TimeLocal(), ",", "QuickChannel sender handle was not properly initialised!");
        Alert("QuickChannel sender handle was not properly initialised!");
        return;
    }
    /*
    // Build the message to send: the current local time, and 
    // the bid and ask prices on this chart's symbol
    string strMsg = StringConcatenate(TimeToStr(TimeLocal(), TIME_SECONDS), ": " , Symbol() , "," 
        , DoubleToStr(Bid, MarketInfo(Symbol(), MODE_DIGITS)) , "," , DoubleToStr(Ask, MarketInfo(Symbol(), MODE_DIGITS)));
    */
    //Print( "OrdersTotal()=" + OrdersTotal() );

    if (OrdersTotal() == gOrdersTotal) {
        return;
    }

    int err;
    string strMsg = "";
    // TODO: what if there is a pending order???
    // Only market orders are considered
    // The whole logic has to be reconsidered
    if (OrdersTotal() > gOrdersTotal) {
        // at least one new order was just generated
        // we'd only consider the one order case, and
        // if there are more, it's safe to leave them to later tick events.
        if (!OrderSelect(gOrdersTotal, SELECT_BY_POS)) {
            err = GetLastError();
            FileWrite(logFile, TimeLocal(), ",", "OrderSelect failed error code is: " + err + "," + ErrorDescription(err));
            Print("OrderSelect failed error code is: " + err + "," + ErrorDescription(err));
            return;
        }
        gOrdersTotal += 1;

        datetime ctm = OrderOpenTime();
        if (OrderType() > OP_SELL) {
            // Do not report pending orders
            return;
        }
        if (ctm>0) {
            FileWrite(logFile, TimeLocal(), ",", "Open order:" + OrderTicket() + ", OrderType:" + OrderType() + ", Open time:", ctm);
            Print("Open order:" + OrderTicket() + ", OrderType:" + OrderType() + ", Open time:", ctm);
        }
        // build a message like : 355072|GOLD|Open|0|R|17:05:59|1250.50|0.10
        // R is for Reverse, F is for Forward
        strMsg = StringConcatenate(IntegerToString(OrderTicket()), "|"
            , OrderSymbol(), "|"
            , "Open", "|"
            , IntegerToString(OrderType()), "|"
            , ReverseOrder ? "R" : "F", "|"
            , TimeToStr(ctm, TIME_SECONDS), "|"
            , DoubleToStr(OrderOpenPrice(), MarketInfo(OrderSymbol(), MODE_DIGITS)), "|"
            , DoubleToStr(OrderLots(), 2));


        /*
        ctm=OrderCloseTime();
        if(ctm>0) Print("Close time for the order :", ctm); 
        
        Print("Current time:", TimeCurrent());
        Print("TimeCurrent()>ctm:", (TimeCurrent()>ctm));
        Print("TimeCurrent()<ctm:", (TimeCurrent()<ctm));
        Print("Current seconds:", TimeSeconds(TimeCurrent()));
        */
        
    } else {
        // an open order was just closed
        gOrdersTotal = OrdersTotal();
    }

    if (OrdersHistoryTotal() > gOrdersHistoryTotal) {
        if (!OrderSelect(gOrdersHistoryTotal, SELECT_BY_POS, MODE_HISTORY)) {
            err = GetLastError();
            FileWrite(logFile, TimeLocal(), ",", "OrderSelect failed error code is: "+ err + "," + ErrorDescription(err));
            Print("OrderSelect failed error code is: " + err + "," + ErrorDescription(err));
            return;
        }
        datetime ctm = OrderCloseTime();
        if(ctm>0) {
            FileWrite(logFile, TimeLocal(), ",", "History order:" + OrderTicket() + ", OrderType:" + OrderType() + ", Close time :", ctm);
            Print("History order:" + OrderTicket() + ", OrderType:" + OrderType() + ", Close time :", ctm);
        }

        if (OrderType() > OP_SELL) {
            // Do not report pending orders
            return;
        }
        // build a message like : 355072|GOLD|Close|0|R|17:05:59|1250.50|0.10
        // R is for Reverse, F is for Forward
        strMsg = StringConcatenate(IntegerToString(OrderTicket()), "|"
            , OrderSymbol(), "|Close|"
            , IntegerToString(OrderType()), "|"
            , ReverseOrder ? "R" : "F", "|"
            , TimeToStr(ctm, TIME_MINUTES|TIME_SECONDS), "|"
            , DoubleToStr(OrderClosePrice(), MarketInfo(OrderSymbol(), MODE_DIGITS)), "|"
            , DoubleToStr(OrderLots(), 2));

        gOrdersHistoryTotal += 1;
    }

    // Optional message logging
    FileWrite(logFile, TimeLocal(), ",", "QuickChannel message sent:" + strMsg);
    Print("QuickChannel message sent:" + strMsg);
    if (LogMessagesToDbgView) OutputDebugStringA("QuickChannel message sent:" + strMsg);

    // Send the message. The third parameter specifies whether or not
    // to discard any messages which have not yet been collected by 
    // the receiver. Messages can be any text, except that the library 
    // itself uses tabs to delimit multiple messages 
    int result = QC_SendMessageW(glbHandle, strMsg, 0);
    if (result == 0) {
        FileWrite(logFile, TimeLocal(), ",", "QuickChannel message failed");
        Alert("QuickChannel message failed");
    }
    FileFlush(logFile);
}


void testOrder() {
//--- get minimum stop level 
   double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL); 
   Print("Minimum Stop Level=",minstoplevel," points"); 
   double price=Ask; 
//--- calculated SL and TP prices must be normalized 
   double stoploss=NormalizeDouble(Bid-minstoplevel*Point,Digits); 
   double takeprofit=NormalizeDouble(Bid+minstoplevel*Point,Digits); 
//--- place market order to buy 1 lot 
   int ticket=OrderSend(Symbol(),OP_BUY,1,price,3,stoploss,takeprofit,"My order",16384,0,clrGreen); 
   if(ticket<0) 
     { 
      Print("OrderSend failed with error #",GetLastError()); 
     } 
   else 
      Print("OrderSend placed successfully");
}
