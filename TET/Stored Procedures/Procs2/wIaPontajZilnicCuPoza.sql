
CREATE procedure wIaPontajZilnicCuPoza @sesiune VARCHAR(50), @parXML XML
as
declare @datajos datetime, @datasus datetime, @marca varchar(6), @calePoze varchar(300), @_refersh int

set @datajos = @parXML.value('(/*/@datajos)[1]', 'datetime')
set @datasus = @parXML.value('(/*/@datasus)[1]', 'datetime')
set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
set @_refersh =  isnull(@parXML.value('(/*/@_refresh)[1]', 'int'),0)

select @calePoze=rtrim(ltrim(val_alfanumerica))+'/formulare/uploads/'
from par where Tip_parametru='AR' and Parametru='URL'

if @calePoze not like'http%'
	set @calePoze='http://'+@calePoze

select rtrim(pe.Marca) marca, rtrim(p.nume) as densalariat, 'PZ' as subtip, 'Pontaj zilnic' as densubtip, pe.idPontajElectronic,
	CONVERT(char(10),pe.data_ora_intrare,101) as dataintrare, CONVERT(char(8),pe.data_ora_intrare,108) as oraintrare, 
	CONVERT(char(10),pe.data_ora_iesire,101) as dataiesire, CONVERT(char(8),pe.data_ora_iesire,108) as oraiesire, 
	replace(str(floor(DATEDIFF(MINUTE,data_ora_intrare,data_ora_iesire)/60.00),2),' ','0')+':'
		+replace(str(DATEDIFF(Minute,data_ora_intrare,data_ora_iesire)-floor(DATEDIFF(MINUTE,data_ora_intrare,data_ora_iesire)/60.00)*60,2),' ','0') as orelucrate, 
	pe.detalii, pe.idJurnalPE, 
	'<a href="' + @calePoze +rtrim(pe.detalii.value('(/row/@pozaintrare)[1]','varchar(1000)')) + '" target="_blank" /><u> Click aici </u></a>' AS linkpozaintrare, 
	'<a href="' + @calePoze +rtrim(pe.detalii.value('(/row/@pozaiesire)[1]','varchar(1000)')) + '" target="_blank" /><u> Click aici </u></a>' AS linkpozaiesire, 
	0 as _nemodificabil
from PontajElectronic pe
	left outer join personal p on p.Marca=pe.Marca
where convert(char(10),pe.data_ora_intrare,101) between @datajos and @datasus
for xml raw, root('Date')

if @_refersh=0
	SELECT 'Introducere salariat' nume, 'PZCAM' codmeniu, 'D' tipmacheta, 'PZ' tip,'PM' subtip,'O' fel,
		(SELECT @parXML ) dateInitializare FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

select '1' AS areDetaliiXml
for xml raw, root('Mesaje')
