--***
CREATE procedure wmSituatieComenziTerti @sesiune varchar(50), @parXML xml
as

declare @tert varchar(100), @datajos datetime, @datasus datetime, @searchText varchar(100), @denTert varchar(100),
		@idpunctlivrare varchar(30), @punctlivrare varchar(100), @subunitate varchar(100), @utilizator varchar(50)

select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), ''),
		@datajos=dateadd(M,-2,getdate()),
		@datasus=getdate()
		
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

set @searchText=(case when @searchText='' then ' ' else @searchText end)
set @searchText=REPLACE(@searchText, ' ', '%')

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

set @punctlivrare=rtrim((select max(descriere) from infotert where rtrim(tert)=@tert and identificator=rtrim(@idpunctlivrare) 
							and subunitate=rtrim(@subunitate)))
set @punctlivrare=(case when isnull(@punctlivrare,'')<>'' then ' - '+@punctlivrare else '' end)
set @denTert=''
select @denTert=rtrim(max(t.Denumire)) from terti t where t.Tert=@tert

select top 100 
	rtrim(c.idContract) as cod, '0xffffff' as culoare, rtrim(max(c.numar))+' ('+convert(varchar(10),max(c.Data),103)+')' as denumire,
	'Val='+convert(varchar(20),CONVERT(money,sum(p.Cantitate*p.Pret),1))+' ('+rtrim(max(c.Explicatii))+')' as info
from Contracte c inner join PozCOntracte p
	on c.idContract=p.idContract and c.tip='CL'
where 
	c.Data between @datajos and @datasus
	and (@tert is not null and @tert=c.Tert)
	and (@idpunctlivrare='' or c.Punct_livrare=@idpunctlivrare)
group by c.tert, c.idcontract
order by max(c.data) desc
for xml raw

select 'Comenzi pe ultima luna'+char(10)+rtrim(@denTert)+rtrim(isnull(@punctlivrare,'')) as titlu,0 as areSearch, null as detalii
for xml raw,Root('Mesaje')
