--***
create function contCorespAP (@Gestiune char(9), @Cod char(20), @CtStoc varchar(40), @LM char(9)) returns varchar(40)
as begin

declare @CtCoresp varchar(40), @TipNom char(1), @GrNom char(13), @AnCtStoc varchar(40)

set @TipNom=''
set @GrNom=''

select @TipNom=tip, @GrNom=grupa 
from nomencl 
where cod=@Cod

if @TipNom='S'
	set @CtCoresp=''-- ar fi cont factura (@CtFact) - va fi tratat in procedurile chematoare
if @CtCoresp is null and left(@CtStoc, 1)='8'
	set @CtCoresp=''

set @AnCtStoc=isnull((select max(case when cont_parinte<>'' then substring(@CtStoc, len(cont_parinte)+1, 40) else '' end)
	from conturi where cont=@CtStoc), '')

if @CtCoresp is null and (left(@CtStoc, 3)='354' or left(@CtStoc, 2) in ('33', '34', '36'))
begin
	declare @Ct711 varchar(40), @AnLM711 int, @AnGest711 int, @AnCtStoc711 int
	
	set @AnLM711=0
	set @AnGest711=0
	set @Ct711=''
	set @AnCtStoc711=0
	select @AnLM711=convert(int, val_logica), @AnGest711=val_numerica, @Ct711=val_alfanumerica from par where tip_parametru='GE' and parametru='CONTP'
	select @AnCtStoc711=convert(int, val_logica) from par where tip_parametru='GE' and parametru='ANCTSPRD'
	
	set @CtCoresp=RTrim(@Ct711)+(case when @AnCtStoc711=1 then RTrim(@AnCtStoc) else '' end)+(case when @AnLM711=1 and @LM<>'' then '.'+RTrim(@LM) else '' end)+(case when @AnGest711 between 1 and 9 then '.'+RTrim(@Gestiune) else '' end)
end
if @CtCoresp is null and left(@CtStoc, 3)='381'
begin
	declare @CtChAmb varchar(40)
	
	set @CtChAmb=''
	select @CtChAmb=val_alfanumerica from par where tip_parametru='GE' and parametru='CCHAMBAL'
	
	if left(@CtChAmb, 3)<>'607'
		set @CtCoresp=@CtChAmb
end
if @CtCoresp is null 
begin
	declare @CtChMat varchar(40)
	
	set @CtChMat=''
	select @CtChMat=val_alfanumerica from par where tip_parametru='GE' and parametru='CCHVMAT'
	
	if @CtChMat<>'' and (left(@CtStoc, 3) in ('301', '302') or @TipNom='F')
		set @CtCoresp=@CtChMat
end
if @CtCoresp is null
begin
	declare @Ct607 varchar(40), @AnGest607 int, @AnGr607 int, @AnCtStocChVenMarf int
	
	set @Ct607=''
	set @AnGest607=0
	set @AnGr607=0
	set @AnCtStocChVenMarf=0
	select @Ct607=val_alfanumerica from par where tip_parametru='GE' and parametru='CCVMARFA'
	select @AnGest607=convert(int, val_logica), @AnGr607=val_numerica from par where tip_parametru='GE' and parametru='CONTVM'
	select @AnCtStocChVenMarf=convert(int, val_logica) from par where tip_parametru='GE' and parametru='ANCSTMRF'
	
	set @CtCoresp=RTrim(@Ct607)+(case when @AnGest607=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGr607=1 then '.'+RTrim(@GrNom) else '' end)+(case when @AnCtStocChVenMarf=1 then RTrim(@AnCtStoc) else '' end)
end

return @CtCoresp
end
