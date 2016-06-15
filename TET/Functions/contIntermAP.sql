--***
create function contIntermAP (@Gestiune char(9), @Cod char(20), @CtStoc varchar(40), @CtCoresp varchar(40)) returns varchar(40)
as begin

declare @CtInterm varchar(40), @TipNom char(1), @GrNom char(13)

set @TipNom=''
set @GrNom=''

select @TipNom=tip, @GrNom=grupa 
from nomencl 
where cod=@Cod

if @TipNom='S' or left(@CtStoc, 1)='8'
	set @CtInterm=''
if @CtInterm is null
begin
	declare @CtIntMat varchar(40), @AnGest371 int, @AnGr371 int
	
	set @CtIntMat=''
	set @AnGest371=0
	set @AnGr371=0
	select @CtIntMat=val_alfanumerica from par where tip_parametru='GE' and parametru='CINTMAT'
	select @AnGest371=convert(int, val_logica), @AnGr371=val_numerica from par where tip_parametru='GE' and parametru='CONTM'
	
	if (left(@CtCoresp, 3)='607' or @CtIntMat<>'' and @TipNom in ('M', 'F')) and left(@CtStoc, 2) not in ('33', '34', '36', '37') 
		set @CtInterm=(case when @CtIntMat<>'' then @CtIntMat else '371'+(case when @AnGest371=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGr371=1 then '.'+RTrim(@GrNom) else '' end) end)
end
if @CtInterm is null
begin
	declare @SemifProd int
	
	set @SemifProd=0
	select @SemifProd=convert(int, val_logica) from par where tip_parametru='GE' and parametru='SEMIPRODV'
	if @SemifProd=1 and left(@CtStoc, 3) in ('341', '354') and left(@CtCoresp, 3)='711'
		set @CtInterm='345'
	else
		set @CtInterm=''
end

return @CtInterm
end
