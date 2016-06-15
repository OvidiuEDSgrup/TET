--***
create function formezContStocFol (@Cod char(20)) returns varchar(40)
as begin

declare @ContStoc varchar(40), @ContNom varchar(40), @TipEchipamentNom char(1), @ContTFO varchar(40), @ContPFO varchar(40), @ContLFO varchar(40)

set @ContNom=''
set @TipEchipamentNom=''
select @ContNom=cont, @TipEchipamentNom=left(tip_echipament, 1)
from nomencl 
where cod=@Cod

set @ContTFO=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTTFO'), '')
set @ContPFO=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTPFO'), '')
set @ContLFO=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CONTLFO'), '')

set @ContStoc=(case @TipEchipamentNom when 'T' then @ContTFO when 'P' then @ContPFO else @ContLFO end)

return @ContStoc
end
