// ####################################################################
//
// Example sender EA for the QuickChannel library. Transmits the 
// current bid and ask prices for the chart symbol. A receiver 
// in another instance of MT4 could then parse the message and
// place a trade if its prices were better.
//
// The sender and receiver must use the same "channel" name,
// defined in these examples by the ChannelName parameter.
// You can safely have multiple senders on the same channel, e.g.
// EAs running on lots of different charts, all sending their latest
// prices to a single receiver. However, there should only ever
// be more than one receiver using a channel. If there is more 
// than one, then each receiver will only see some of the messages 
// because retrieving the list of available messages from 
// a channel also clears the list of messages.
//
// A single EA can send on multiple channels by calling QC_StartSender()
// more than once, and storing the different handle values for 
// later use with QC_SendMessage(). A single EA can also act as both
// sender and receiver.
//
// ####################################################################

// DLL imports from the QuickChannel library. Requires "Allow DLL imports"
// to be turned on
#import "FXBlueQuickChannel.dll"
   int QC_StartSender(string);
   int QC_ReleaseSender(int);
   int QC_SendMessage(int SenderHandle, string Message, int Flags);
#import

// Kernel logging function whose output can be viewed in Dbgview
// (http://technet.microsoft.com/en-us/sysinternals/bb896647). 
// Easy way of checking how quickly messages are being transmitted.
#import "kernel32.dll"
   void OutputDebugStringA(string msg);
#import


// External, user-configurable properties
extern string  ChannelName = "QuickChannelTest";
extern bool    LogMessagesToDbgView = true;


// Handle which is acquired during init() and freed during deinit()
int glbHandle = 0;


// EA initialisation. The sender will typically do QC_StartSender() here.
void init()
{
   // Initialise sending via QuickChannel. Return value is 1 if successful, or 0
   // if initialisation fails. This handle gets stored in a global variable
   // for later use in start()
   glbHandle = QC_StartSender(ChannelName);
   
   if (glbHandle == 0) {
      Alert("Failed to get a QuickChannel sender handle");
   }
}


// EA termination. The sender will typically do QC_ReleaseSender() here.
void deinit()
{
   // Release resources associated with the sending which was
   // initialised earlier
   QC_ReleaseSender(glbHandle);
   glbHandle = 0;
}


// EA per-tick function. 
void start()
{
   // Don't do anything unless initialisation was successful...
   if (glbHandle != 0) {

      // Build the message to send: the current local time, and 
      // the bid and ask prices on this chart's symbol
      string strMsg = StringConcatenate(TimeToStr(TimeLocal(), TIME_SECONDS), ": " , Symbol() , "," , DoubleToStr(Bid, MarketInfo(Symbol(), MODE_DIGITS)) , "," , DoubleToStr(Ask, MarketInfo(Symbol(), MODE_DIGITS)));

      // Optional message logging
      if (LogMessagesToDbgView) OutputDebugStringA("Message " + strMsg);
      
      // Sends the message. The third parameter specifies whether or not
      // to discard any messages which have not yet been collected by 
      // the receiver. Messages can be any text, except that the library 
      // itself uses tabs to delimit multiple messages 
      int result = QC_SendMessage(glbHandle, strMsg, 0);
      if (result == 0) Alert("QuickChannel message failed");
   }     
}   

