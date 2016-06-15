--***
CREATE procedure [dbo].[wmAfiseazaBon] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmAfiseazaBonSP' and type='P')
begin
	exec wmAfiseazaBonSP @sesiune, @parXML 
	return -1
end

declare @nrbon char(10), @datacasa varchar(30),@data char(10),@lm varchar(10),@indexsep int
set @datacasa=@parXML.value('(/row/@wmIaBonuri.cod)[1]','varchar(30)')
set @indexsep=charindex('|',@datacasa)
set @data=LEFT(@datacasa,@indexsep-1)
set @lm=SUBSTRING(@datacasa,@indexsep+1,100)
set @nrbon=@parXML.value('(/row/@wmDetBonuri.cod)[1]','varchar(10)')

select top 100 rtrim(n.denumire) as cod, 
rtrim(n.denumire) as denumire,
LTRIM(str(bp.Cantitate))+' '+RTRIM(n.UM)+' x '+LTRIM(convert(decimal(15,2),bp.Pret))+' lei = '+
ltrim(convert(varchar(20),convert(money,convert(decimal(15,2), bp.Total)),1))+ ' lei'
	 as info
from bp
inner join nomencl n on bp.Cod_produs=n.Cod
where bp.tip='21'
and bp.Data=CONVERT(datetime,@data,103) and bp.Numar_bon=@nrbon and bp.Loc_de_munca=@lm
order by 1 desc
for xml raw

select 'Bonul '+@nrbon+' din:'+@data as titlu,0 as areSearch
for xml raw,Root('Mesaje')


