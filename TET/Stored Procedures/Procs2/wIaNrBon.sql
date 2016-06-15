--***
/* procedura returneaza urmatorul nr de bon din bp/bt */
create procedure wIaNrBon @sesiune varchar(50), @parXML xml
as
declare @returnValue int
if exists(select * from sysobjects where name='wIaNrBonSP' and type='P')      
begin
	exec @returnValue = wIaNrBonSP @sesiune,@parXML
	return @returnValue 
end

set nocount on
set transaction isolation level read uncommitted

declare @casaM int, @data datetime, @numar int

select	@casaM = @parXML.value('(/row/@casaM)[1]', 'int'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime')

select @numar = isnull(MAX(Numar_bon),0)
from antetBonuri a
where chitanta=1
and casa_de_marcat=@casaM
and Data_bon=@data

select isnull(@numar,0)+1 as numar
for xml raw

