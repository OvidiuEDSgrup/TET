--***
create function  contVenitAP (@Gestiune char(9), @Cod char(20), @CtStoc varchar(40), @CtInterm varchar(40)) returns varchar(40)
as begin

declare @CtVenit varchar(40), @TipNom char(1), @GrNom char(13), @AnCtStoc varchar(40), @VenFact8033 int

set @TipNom=''
set @GrNom=''

select @TipNom=tip, @GrNom=grupa 
from nomencl 
where cod=@Cod

set @VenFact8033=0
select @VenFact8033=convert(int, val_logica) from par where tip_parametru='GE' and parametru='CONTV8'

if @CtVenit is null and (@TipNom='S' or left(@CtStoc, 1)='8' and @VenFact8033=0)
	set @CtVenit=@CtStoc

set @AnCtStoc=isnull((select max(case when cont_parinte<>'' then substring(@CtStoc, len(cont_parinte)+1, 40) else '' end)
	from conturi where cont=@CtStoc), '')

if @CtVenit is null and (left(@CtStoc, 3)='354' or left(@CtStoc, 2) in ('33', '34', '36'))
begin
	if left(@CtStoc, 3)='346'
		set @CtVenit='703'
	if @CtVenit is null and left(@CtStoc, 3)='341' and @CtInterm=''
	begin
		declare @CtVenitSemif varchar(40)
		
		set @CtVenitSemif=''
		select @CtVenitSemif=val_alfanumerica from par where tip_parametru='GE' and parametru='CONTVSEMI'
		
		set @CtVenit=@CtVenitSemif
	end
	if @CtVenit is null
	begin
		declare @Ct701 varchar(40), @AnGest701 int
		
		set @AnGest701=0
		set @Ct701=''
		select @AnGest701=convert(int, val_logica), @Ct701=val_alfanumerica from par where tip_parametru='GE' and parametru='CONTVP'
		
		set @CtVenit=RTrim(@Ct701)+(case when @AnGest701=1 then '.'+RTrim(@Gestiune) else '' end)
	end
end
if @CtVenit is null
begin
	declare @CtVenMat varchar(40), @CtVenAmb varchar(40)
	
	set @CtVenMat=''
	set @CtVenAmb=''
	select @CtVenMat=val_alfanumerica from par where tip_parametru='GE' and parametru='CVENVMAT'
	select @CtVenAmb=val_alfanumerica from par where tip_parametru='GE' and parametru='CVENAMB'
	
	if left(@CtStoc, 3)='381' or @TipNom='M' and left(@CtStoc, 1)='8' and @VenFact8033=1
		set @CtVenit=(case when @CtVenMat='' or left(@CtStoc, 3)='381' then @CtVenAmb else @CtVenMat end)
	if @CtVenit is null and @CtVenMat<>'' and (left(@CtStoc, 3) in ('301', '302') or @TipNom='F')
		set @CtVenit=@CtVenMat
end
if @CtVenit is null
begin
	declare @Ct707 varchar(40), @AnGest707 int, @AnGr707 int, @AnCtStocChVenMarf int
	
	set @Ct707=''
	set @AnGest707=0
	set @AnGr707=0
	set @AnCtStocChVenMarf=0
	select @Ct707=val_alfanumerica from par where tip_parametru='GE' and parametru='CVMARFA'
	select @AnGest707=convert(int, val_logica), @AnGr707=val_numerica from par where tip_parametru='GE' and parametru='CONTVV'
	select @AnCtStocChVenMarf=convert(int, val_logica) from par where tip_parametru='GE' and parametru='ANCSTMRF'
	
	set @CtVenit=RTrim(@Ct707)+(case when @AnGest707=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGr707=1 then '.'+RTrim(@GrNom) else '' end)+(case when @AnCtStocChVenMarf=1 then RTrim(@AnCtStoc) else '' end)
end

return @CtVenit
end
