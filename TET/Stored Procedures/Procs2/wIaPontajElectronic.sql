
CREATE procedure wIaPontajElectronic @sesiune VARCHAR(50), @parXML XML
as
declare @data datetime, @datajos datetime, @datasus datetime, @marca varchar(6)

set @data = @parXML.value('(/*/@data)[1]', 'datetime')
set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')

set @datajos = dbo.BOM(@data)
set @datasus = @data

select rtrim(pe.Marca) marca, 'DC' as subtip, 'Date citite' as densubtip, pe.idPontajElectronic,
	CONVERT(char(10),pe.data_ora_intrare,101) as dataintrare, CONVERT(char(8),pe.data_ora_intrare,108) as oraintrare, 
	CONVERT(char(10),pe.data_ora_iesire,101) as dataiesire, CONVERT(char(8),pe.data_ora_iesire,108) as oraiesire, 
	replace(str(floor(DATEDIFF(MINUTE,data_ora_intrare,data_ora_iesire)/60.00),2),' ','0')+':'
		+replace(str(DATEDIFF(Minute,data_ora_intrare,data_ora_iesire)-floor(DATEDIFF(MINUTE,data_ora_intrare,data_ora_iesire)/60.00)*60,2),' ','0') as orelucrate, 
	pe.detalii, pe.idJurnalPE, (case when jpe.operatie='Preluare' then 1 else 0 end) as _nemodificabil
from PontajElectronic pe
	left outer join JurnalPontajElectronic jpe on jpe.idJurnalPE=pe.idJurnalPE
where convert(char(10),pe.data_ora_intrare,101) between @datajos and @datasus	and pe.Marca = @marca
union all
select marca, tip as subtip, denumire, 0 as idPontajElectronic,
	CONVERT(char(10),data_inceput,101) as dataintrare, ora_inceput as oraintrare, 
	CONVERT(char(10),data_sfarsit,101) as dataiesire, ora_sfarsit as oraiesire, '' as orelucrate, 
	'', 0 as idJurnalPE, 1 as _nemodificabil
from dbo.fDate_pontaj_automat (@datajos, @datasus, @datasus, 'TC', isnull(@marca,''), 0, 1)
order by dataintrare
for xml raw, root('Date')

select '1' AS areDetaliiXml
for xml raw, root('Mesaje')
