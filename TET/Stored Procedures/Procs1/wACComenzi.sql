--***
create procedure wACComenzi @sesiune varchar(50), @parXML XML
as
set transaction isolation level read uncommitted

if exists (select * from sysobjects where name = 'wACComenziSP' and type = 'P')
begin
	exec wACComenziSP @sesiune = @sesiune, @parXML = @parXML
	return 0
end

declare @subunitate varchar(9)
select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
declare @codMeniu varchar(20), @searchText varchar(20)
select	@searchText=@parXML.value('(/row/@searchText)[1]','varchar(20)'),
		@codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(20)'),'')

select top 100 rtrim(comanda) as cod,
rtrim(left(descriere,30)) as denumire, 
isnull(rtrim(lm.denumire),'')+' ('+rtrim(tip_comanda)+')' as info
from Comenzi
left join lm on lm.cod=comenzi.loc_de_munca 
	where subunitate=@subunitate 
		  and (@codMeniu<>'M' or tip_comanda='T')		--> in macheta de masini apar doar comenzile de tip 'T'
		  and (comanda like replace(@searchText,' ','%')+'%' 
		  or descriere like '%'+replace(@searchText,' ','%')+'%')
order by comanda
for xml raw
