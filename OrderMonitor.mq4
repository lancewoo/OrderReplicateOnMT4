//+------------------------------------------------------------------+
//|                                                 OrderMonitor.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict


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
extern bool    LogMessagesToDbgView = true;

// Handle which is acquired during init() and freed during deinit()
int glbHandle = 0;

// number of orders currently held
int gOrdersTotal = 0;
// number of history orders
int gOrdersHistoryTotal = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialise sending via QuickChannel.
    glbHandle = QC_StartSenderW(ChannelName);
   
    if (glbHandle == 0) {
        Alert("Failed to get a QuickChannel sender handle");
        return INIT_FAILED;
    }

    gOrdersTotal = OrdersTotal();
    if (gOrdersTotal > 0) {
        Print( "OnInit(): There are " + gOrdersTotal + " open orders in total." );
    } else {
        Print( "OnInit(): There are no open orders." );
    }
    gOrdersHistoryTotal = OrdersHistoryTotal();
    if (gOrdersHistoryTotal > 0) {
        Print( "OnInit(): There are " + gOrdersHistoryTotal + " history orders in total." );
    } else {
        Print( "OnInit(): There are no history orders." );
    }


    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release resources associated with the sending which was
    // initialised earlier
    QC_ReleaseSender(glbHandle);
    glbHandle = 0;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if (glbHandle == 0) {
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
    string strMsg = "";
    // TODO: what if there is a pending order???
    // Only market orders are considered
    // The whole logic has to be reconsidered
    if (OrdersTotal() > gOrdersTotal) {
        // at least one new order was just generated
        // we'd only consider the one order case, and
        // if there are more, it's safe to leave them to later tick events.
        if (!OrderSelect(gOrdersTotal, SELECT_BY_POS)) {
            Print("OrderSelect failed error code is: ", GetLastError());
            return;
        }
        gOrdersTotal += 1;

        datetime ctm = OrderOpenTime();
        if (OrderType() > OP_SELL) {
            // Do not report pending orders
            return;
        }
        if (ctm>0) Print("Open time for the order :", ctm);
        // build a message like : 355072|GOLD|Open|0|17:05:59|1250.50|0.10
        strMsg = StringConcatenate(IntegerToString(OrderTicket()), "|"
            , OrderSymbol(), "|", "Open", "|"
            , IntegerToString(OrderType()), "|", TimeToStr(ctm, TIME_SECONDS), "|"
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
            Print("OrderSelect failed error code is: ", GetLastError());
            return;
        }
        datetime ctm = OrderCloseTime();
        if(ctm>0) Print("History order Close time for the order :", ctm);

        if (OrderType() > OP_SELL) {
            // Do not report pending orders
            return;
        }
        // build a message like : 355072|GOLD|Close|0|17:05:59|1250.50|0.10
        strMsg = StringConcatenate(IntegerToString(OrderTicket()), "|"
            , OrderSymbol(), "|Close|"
            , IntegerToString(OrderType()), "|", TimeToStr(ctm, TIME_MINUTES|TIME_SECONDS), "|"
            , DoubleToStr(OrderClosePrice(), MarketInfo(OrderSymbol(), MODE_DIGITS)), "|"
            , DoubleToStr(OrderLots(), 2));

        gOrdersHistoryTotal += 1;
    }

    // Optional message logging
    Print("QuickChannel message sent:" + strMsg);
    if (LogMessagesToDbgView) OutputDebugStringA("QuickChannel message sent:" + strMsg);

    // Send the message. The third parameter specifies whether or not
    // to discard any messages which have not yet been collected by 
    // the receiver. Messages can be any text, except that the library 
    // itself uses tabs to delimit multiple messages 
    int result = QC_SendMessageW(glbHandle, strMsg, 0);
    if (result == 0) {
        Alert("QuickChannel message failed");
    }
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---

}
//+------------------------------------------------------------------+

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