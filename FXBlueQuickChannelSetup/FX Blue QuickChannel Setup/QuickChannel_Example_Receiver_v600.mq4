#import "FXBlueQuickChannel.dll"
   int QC_StartReceiverW(string, int);
   int QC_ReleaseReceiver(int);
   int QC_GetMessages5W(int, uchar&[], int);
#import

#define QC_BUFFER_SIZE     10000

int glbHandle = 0;

void OnInit()
{
   // Do initialisation in OnTick (or OnStart), not in OnInit()
}

void OnDeinit(const int reason)
{
   if (glbHandle) QC_ReleaseReceiver(glbHandle);
   glbHandle = 0;
}

void OnTick()
{
   if (!glbHandle) glbHandle = QC_StartReceiverW("TestChannel", WindowHandle(Symbol(), Period()));
   
   if (glbHandle) {
      uchar buffer[];
      ArrayResize(buffer, QC_BUFFER_SIZE);
      int res = QC_GetMessages5W(glbHandle, buffer, QC_BUFFER_SIZE);
      if (res > 0) {
         string strMsg = CharArrayToString(buffer, 0, res);
         Print(strMsg);
      }
   } else {
      Print("No handle");
   }
}