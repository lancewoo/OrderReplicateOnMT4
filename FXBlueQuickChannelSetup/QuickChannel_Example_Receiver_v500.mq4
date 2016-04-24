// ####################################################################
//
// Example receiver EA for the QuickChannel library. Designed to 
// receive messages from the sender-example, and simply logs them.
// In real life, this receiver could parse the messages, e.g.
// looking for its prices being better than those in the other 
// MT4 instance, and exploiting any arbitrage opportunity.
//
// The sender and receiver must use the same "channel" name,
// defined in these examples by the ChannelName parameter.
// You can safely have multiple senders on the same channel, e.g.
// EAs running on lots of different charts, all sending their latest
// prices to a single receiver. However, there should only ever
// be one receiver using a channel. If there is more 
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

// Imports from the QuickChannel library
#import "FXBlueQuickChannel.dll"
   int QC_StartReceiver(string, int);
   int QC_ReleaseReceiver(int);
   int QC_GetMessages3(int, string & arr[], int);
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


// Handle which is acquired during start() and freed during deinit()
int glbHandle = 0;

// Buffer template
string glbReceiveBuffer = "";

// EA initialisation.
void init()
{
   // Create a buffer for subsequent use by QC_GetMessages3()
   glbReceiveBuffer = "01234567";
   for (int i = 0; i < 12; i++) glbReceiveBuffer = StringConcatenate(glbReceiveBuffer, glbReceiveBuffer);   

   // N.B. The QC_StartReceiver function needs a call to WindowHandle(). 
   // This can return zero during init() if an EA is loading while 
   // MT4 starts up. Therefore, the setup needs to be done in
   // start(), not in init(), so that WindowHandle() is guaranteed
   // to return a value.
}


// EA termination. The sender will typically do QC_ReleaseReceiver() here.
void deinit()
{
   QC_ReleaseReceiver(glbHandle);
   glbHandle = 0;
}



// EA per-tick function. 
void start()
{
   // Initialise receiving via QuickChannel. Return value is 1 if successful, or 0
   // if initialisation fails. This handle gets stored in a global variable
   // for later use in start()
   if (glbHandle == 0) {
      glbHandle = QC_StartReceiver(ChannelName, WindowHandle(Symbol(), Period()));
   
      if (glbHandle == 0) {
         Alert("Failed to get a QuickChannel receiver handle");
      }
   }

   // Don't do anything unless initialisation was successful...
   if (glbHandle != 0) {
      // Get all messages which have been sent since the last
      // check to QC_GetMessages3(). If there are multiple 
      // pending messages then this will return a tab-separated
      // list. The call to QC_GetMessages3() wipes the list while 
      // retrieving it.     

      // Create a string array, put a copy of our buffer into it, and 
      // call QC_GetMessages3()
      string arrBuffer[1];
      arrBuffer[0] = StringConcatenate(glbReceiveBuffer, ""); // Use copy of buffer template
      int res = QC_GetMessages3(glbHandle, arrBuffer, StringLen(arrBuffer[0]));
      
      if (res == 2) {
         // Buffer is not large enough. Shouldn't be possible, because we built a big buffer in init()
         Alert("QuickChannel buffer is not large enough!");
                     
      } else if (res == 1) {
         // No pending messages 
               
      } else {
         // Read the messages back out of the buffer
         string strMsgList = arrBuffer[0];

         // If we get a message from the example sender, then
         // we simply log it.
         if (strMsgList != "") {
         
            // There may either be one message, or multiple messages 
            // separated by tabs.
            //
            // The list is in the order that the messages were sent.
            // In some scenarios you may need to process it
            // in REVERSE ORDER, e.g. because the list includes 
            // two prices for the same symbol and you only want
            // to use the more recent report.
         
            string Messages[];
            StringSplit(strMsgList, "\t", Messages);
         
            for (int i = 0; i < ArraySize(Messages); i++) {
               string strMsg = Messages[i];

               if (LogMessagesToDbgView) OutputDebugStringA("..." + strMsg);
         
               Comment(strMsg);
               Print(strMsg);
            }
         }  
      
      }
   }
}   


// Function which splits a delimited piece of text into its
// component parts. Used to process the potentially
// tab-separated list from QC_GetMessages()
void StringSplit(string InputString, string Separator, string & ResultArray[])
{
   ArrayResize(ResultArray, 0);
   
   int lenSeparator = StringLen(Separator), NewArraySize;
   while (InputString != "") {
      int p = StringFind(InputString, Separator);
      if (p == -1) {
         NewArraySize = ArraySize(ResultArray) + 1;
         ArrayResize(ResultArray, NewArraySize);      
         ResultArray[NewArraySize - 1] = InputString;
         InputString = "";
      } else {
         NewArraySize = ArraySize(ResultArray) + 1;
         ArrayResize(ResultArray, NewArraySize);      
         ResultArray[NewArraySize - 1] = StringSubstr(InputString, 0, p);
         InputString = StringSubstr(InputString, p + lenSeparator);
         if (InputString == "") {
            ArrayResize(ResultArray, NewArraySize + 1);      
            ResultArray[NewArraySize] = "";
         }
      }     
   }
}

