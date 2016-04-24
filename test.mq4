//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
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
      int err = GetLastError();
      Print("OrderSend failed with error #", err);
      Print(ErrorDescription(err)); 
     } 
   else 
      Print("OrderSend placed successfully"); 
//--- 

   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
