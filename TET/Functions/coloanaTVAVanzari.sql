--***
create function coloanaTVAVanzari (@CotaTVA float, @DreptDed char(1), @Exonerat int, @VanzCump char(1), 
	@CtCoresp varchar(40), @ListaCtNeimpoz char(200), @TipTert int, @Teritoriu char(1), @TipNom char(1), 
	@Tert char(13), @Factura char(20), @TipDoc char(2), @NrDoc char(20), @DataDoc datetime, @NrPoz int, 
	@ContPI varchar(40), @TipPI char(2), @Cod char(20)) 
returns int
as begin

if @TipNom is null set @TipNom=''
if @TipTert is null set @TipTert=0

declare @Bunuri int, @Comunitar int, @Export int

if 1 = 0 --conditie pentru aplicare regim special art. 152 (agentii de turism, obiecte de arta, second-hand-uri)
	return 11

if @CotaTVA<>0 and /*@Exonerat > 0 */ @Exonerat = 2 and @VanzCump='V'
	return 10

if @CotaTVA <> 0 and @Exonerat=1 and @VanzCump='C'
	return 21

if @CotaTVA <> 0
	return (case @CotaTVA when 9 then 8 when 5 then 19 else 6 end)

--am ajuns la scutite/neimpozabile
if CharIndex(RTrim(@CtCoresp), RTrim(@ListaCtNeimpoz)) > 0
	return 18

set @Bunuri = (case when @TipNom not in ('R', 'S') and (@TipNom<>'' or @TipNom='' and left(@CtCoresp, 2) in ('30', '34', '35', '37')) or @TipDoc='AP' and @CtCoresp='418' then 1 else 0 end)
set @Comunitar = (case when @Teritoriu is null and @TipTert=1 or @Teritoriu='U' then 1 else 0 end)
set @Export = (case when @Teritoriu is null and @TipTert=2 or @Teritoriu<>'U' then 1 else 0 end)

if @Export = 1 or @Comunitar = 1 and @Bunuri = 0 -- Lucian: 21.05.2013 - dus pe coloana 16 si vanzarile de servicii in UE (sesizarea 236595)
	return 16
if @Comunitar = 1 and @Bunuri = 1
begin
	declare @CodFiscal char(20)
	set @CodFiscal = isnull((select max(cod_fiscal) from terti where tert=@Tert), '')
	return (case when @CodFiscal='' then 15 else 14 end)
end

/* -- acuma am scos cu totul - pare ca doar prin exceptie locul prestarii este in afara Romaniei
--deocamdata pun la Locul livrarii/prestarii in afara Romaniei doar prestarile de servicii intracomunitare
if @Comunitar = 1 and @Bunuri = 0
	return (case when @DreptDed='C' then 12 else 13 end)
*/
return (case when @DreptDed='C' then 16 else 17 end)

end
