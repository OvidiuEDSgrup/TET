--***
create procedure wIaCpv_Nomenclator (@sesiune varchar(50) = null, @parxml xml = null)
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	declare @idcpv int
	select @idcpv=@parxml.value('(row/@id)[1]','int')
	--> nu ar trebui sa apara niciodata aceasta eroare:
	if @idcpv is null raiserror('Nu a fost identificat cpv-ul parinte!',16,1)

	select rtrim(n.cod) cod, rtrim(n.denumire) denumire, rtrim(n.grupa) grupa from legCpvNomencl l inner join nomencl n on l.cod=n.cod
		where l.idcpv=@idcpv
	for xml raw
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
end catch
if object_id('tempdb..#sisteme') is not null drop table #sisteme
if len(@eroare)>0 raiserror(@eroare, 16,1)
