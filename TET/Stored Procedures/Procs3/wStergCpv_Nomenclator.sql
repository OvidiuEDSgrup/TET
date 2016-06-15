--***
create procedure wStergCpv_Nomenclator (@sesiune varchar(50) = null, @parxml xml = null)
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	declare @idcpv int, @cod varchar(50)
	select @idcpv=@parxml.value('(row/@id)[1]','int')
		,@cod=@parxml.value('(row/row/@cod)[1]','varchar(50)')
	--> nu ar trebui sa apara niciodata aceasta eroare:
	if @idcpv is null raiserror('Nu a fost identificat cpv-ul parinte!',16,1)
	if @cod is null raiserror('Nu a fost identificat codul de nomenclator!',16,1)
	
	delete legcpvnomencl where idcpv=@idcpv and cod=@cod
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
end catch
if object_id('tempdb..#sisteme') is not null drop table #sisteme
if len(@eroare)>0 raiserror(@eroare, 16,1)
