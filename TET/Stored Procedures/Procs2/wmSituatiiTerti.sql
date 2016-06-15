--***
CREATE procedure wmSituatiiTerti @sesiune varchar(50), @parXML xml
as
declare @tert varchar(100), @denTert varchar(100), @idpunctlivrare varchar(30), @punctlivrare varchar(100), @subunitate varchar(100), @utilizator varchar(50)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

set @denTert=''
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
select @denTert=rtrim(max(t.Denumire)) from terti t where t.Tert=@tert

set @punctlivrare=rtrim((select max(descriere) from infotert where rtrim(tert)=@tert and identificator=rtrim(@idpunctlivrare) 
							and subunitate=rtrim(@subunitate)))
set @punctlivrare=(case when isnull(@punctlivrare,'')<>'' then ' - '+@punctlivrare else '' end)

select 'TF' as cod, '0xffffff' as culoare, 'Facturi' as denumire, 'Sit facturi' as titlu,
	'wmSituatieFacturiTerti' as procdetalii, 'C' as tipdetalii
union all
select 'TC' as cod, '0xffffff' as culoare, 'Comenzi' as denumire, 'Sit facturi' as titlu,
	'wmSituatieComenziTerti' as procdetalii, 'C' as tipdetalii
union all
select 'TP' as cod, '0xffffff' as culoare, 'Produse' as denumire, 'Sit facturi' as titlu,
	'wmSituatieProduseTerti' as procdetalii, 'C' as tipdetalii
union all
select 'TP' as cod, '0xffffff' as culoare, 'Chitante' as denumire, 'Sit chitante' as titlu,
	'wmSituatieChitanteTerti' as procdetalii, 'C' as tipdetalii
for xml raw

select 'Situatii'+char(10)+rtrim(@denTert)+@punctlivrare as titlu
for xml raw,Root('Mesaje')
