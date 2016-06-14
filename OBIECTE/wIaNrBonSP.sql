--***
if exists (select * from sysobjects where name ='wIaNrBonSP')
drop procedure wIaNrBonSP
go
--***
/* procedura returneaza urmatorul nr de bon din bp/bt */
create procedure wIaNrBonSP @sesiune varchar(50), @parXML xml
as
declare @returnValue int

set nocount on
set transaction isolation level read uncommitted

declare @casaM int, @data datetime, @numarBP int, @numarBT int

select	@casaM = @parXML.value('(/row/@casaM)[1]', 'int'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime')
		

select @numarBP=isnull(MAX(Numar_bon),0)
from bp
where factura_chitanta=1
and casa_de_marcat=@casaM
--and data= @data

select @numarBT=isnull(MAX(Numar_bon),0)
from bt
where factura_chitanta=1
and casa_de_marcat=@casaM
--and data= @data

select (case when @numarBP>@numarbT then @numarBP else @numarBT end)+1 as numar
for xml raw

