--***
CREATE procedure wmSituatieProduseTerti @sesiune varchar(50), @parXML xml
as

declare @tert varchar(100), @datajos datetime, @datasus datetime, @searchText varchar(100), @denTert varchar(100),
		@idpunctlivrare varchar(30), @punctlivrare varchar(100), @subunitate varchar(100), @utilizator varchar(50)

select	@searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(100)'), ''),
		@datajos=dateadd(M,-2,getdate()),
		@datasus=getdate()
		
set @searchText=(case when @searchText='' then ' ' else @searchText end)
set @searchText=REPLACE(@searchText, ' ', '%')

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
if @utilizator is null 
	return -1

-- identificare tert din par xml
select @tert=f.tert, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

set @punctlivrare=rtrim((select max(descriere) from infotert where rtrim(tert)=@tert and identificator=rtrim(@idpunctlivrare) 
							and subunitate=rtrim(@subunitate)))
set @punctlivrare=(case when isnull(@punctlivrare,'')<>'' then ' - '+@punctlivrare else '' end)
set @denTert=''
select @denTert=rtrim(max(t.Denumire)) from terti t where t.Tert=@tert

select top 100 rtrim(n.Cod) as cod, '0xffffff' as culoare, rtrim(max(n.Denumire)) as denumire,
	convert(varchar(20),CONVERT(money,sum(p.Cantitate),1))+' '+max(n.UM)+' '+
	convert(varchar(20),CONVERT(money,sum(p.Cantitate*p.Pret),1))+' '+max(case when isnull(c.Valuta,'')='' then 'RON' else c.Valuta end)
	as info
from con c inner join pozcon p on c.Contract=p.Contract and c.tip=p.tip
	inner join nomencl n on p.Cod=n.Cod
where p.Tip='BK' and
	c.Data between @datajos and @datasus
	and (@tert is not null and @tert=c.Tert)
	and (@idpunctlivrare='' or c.Punct_livrare=@idpunctlivrare)
	--and (p.Contract like @searchText)
group by n.cod
order by rtrim(max(n.Denumire))
for xml raw

select 'Produse pe ultima luna'+char(10)+rtrim(@denTert)+rtrim(isnull(@punctlivrare,'')) as titlu,0 as areSearch, null as detalii
for xml raw,Root('Mesaje')
