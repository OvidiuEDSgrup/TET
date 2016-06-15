--***
create function coloanaTVACumparari (@CotaTVA float, @Exonerat int, @VanzCump char(1), 
 @CtCoresp varchar(40), @ListaCtNeimpoz char(200), @TipTert int, @Teritoriu char(1), @TipNom char(1), 
 @Tert char(13), @Factura char(20), @TipDoc char(2), @NrDoc char(20), @DataDoc datetime, @NrPoz int, 
 @ContPI varchar(40), @TipPI char(2), @Cod char(20)) 
returns int
as begin

if @TipNom is null set @TipNom=''
if @TipTert is null set @TipTert=0

declare @Bunuri int, @Comunitar int, @Export int

set @Bunuri = (case when @TipNom not in ('R', 'S') and (@TipNom<>'' or @TipNom='' and left(@CtCoresp, 2) in ('30', '34', '35', '37')) then 1 else 0 end)
set @Comunitar = (case when @Teritoriu is null and @TipTert=1 or @Teritoriu='U' then 1 else 0 end)
set @Export = (case when @Teritoriu is null and @TipTert=2 or @Teritoriu<>'U' then 1 else 0 end)

if @Comunitar = 0 and (@CotaTVA = 0 or @Exonerat = 0 or @VanzCump = 'V')
 return (case @CotaTVA when 0 then 10 when 9 then 8 else 6 end)
if @Comunitar = 1 and (@Bunuri = 1 or 1 = 1) -- chiar daca nu sunt bunuri, intracomunitarele le pun in 11-14, pentru ca la Oblig. la plata taxei (2) sunt doar interne si import, iar la (1) exceptii
 return (case when @CotaTVA<>0 then (case when @bunuri=0 then 21 else 11 end) when CharIndex(RTrim(@CtCoresp), RTrim(@ListaCtNeimpoz)) > 0 then 14 
	else (case when @bunuri=0 then 23 else 13 end) end)
if 1 = 0 --conditie pentru Oblig. la plata taxei cf. art. 150 - exceptii (gaze naturale, etc.)
 return 15
return 17

end
