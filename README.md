# OrderReplicateOnMT4
An order replicate/dupliate EA(Expert Advisors) on MT4 using FXBlueQuickChannelSetup.

To use it, first install the FXBlueQuickChannelSetup library.
Then drop OrderMonitor.ex4 into the Experts folder of the trader account which is going
to be monitored and copied; drop OrderReplicate.ex4 into the Experts folder of the trader account
which is going to copy/duplicate/replicate orders from the other account.

You have to allow DLL imports on both MT4 terminals. Automatic trading should be allowed on the
receiver termial.

Folders should be like this:
D:\Trader-1\
<Trader-1>
©Àterminal.exe
©À<MQL4>
©¦  ©À<Experts>
©¦  ©¦  ©ÀMACD Sample.ex4
©¦  ©¦  ©ÀMACD Sample.mq4
©¦  ©¦  ©ÀMoving Average.ex4
©¦  ©¦  ©ÀMoving Average.mq4
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©ÀOrderMonitor.ex4
©¦  ©À<Libraries>
©¦  ©¦  ©ÀFXBlueQuickChannel.dll
©¦  ©¦  ©ÀFXBlueQuickChannel64.dll
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©Àstdlib.ex4
©¦  ©¦  ©¸stdlib.mq4


D:\Trader-2\
<Trader-2>
©Àterminal.exe
©À<MQL4>
©¦  ©À<Experts>
©¦  ©¦  ©ÀMACD Sample.ex4
©¦  ©¦  ©ÀMACD Sample.mq4
©¦  ©¦  ©ÀMoving Average.ex4
©¦  ©¦  ©ÀMoving Average.mq4
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©ÀOrderMonitor.ex4
©¦  ©À<Libraries>
©¦  ©¦  ©ÀFXBlueQuickChannel.dll
©¦  ©¦  ©ÀFXBlueQuickChannel64.dll
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©Àstdlib.ex4
©¦  ©¦  ©¸stdlib.mq4

......

D:\Trader-Receiver\
<Trader-Receiver>
©Àterminal.exe
©À<MQL4>
©¦  ©À<Experts>
©¦  ©¦  ©ÀMACD Sample.ex4
©¦  ©¦  ©ÀMACD Sample.mq4
©¦  ©¦  ©ÀMoving Average.ex4
©¦  ©¦  ©ÀMoving Average.mq4
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©ÀOrderReplicate.ex4
©¦  ©À<Libraries>
©¦  ©¦  ©ÀFXBlueQuickChannel.dll
©¦  ©¦  ©ÀFXBlueQuickChannel64.dll
©¦  ©¦  ©Àmqlcache.dat
©¦  ©¦  ©Àstdlib.ex4
©¦  ©¦  ©¸stdlib.mq4



