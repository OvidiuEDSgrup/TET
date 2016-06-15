--***
create procedure wScriuCpv_Nomenclator (@sesiune varchar(50) = null, @parxml xml = null)
as
declare @eroare varchar(2000)
select @eroare=''
begin try
	declare @idcpv int, @cod varchar(50), @o_cod varchar(50)
	select @idcpv=@parxml.value('(row/@id)[1]','int')
		,@cod=@parxml.value('(row/row/@cod)[1]','varchar(50)')
		,@o_cod=@parxml.value('(row/row/@o_cod)[1]','varchar(50)')
	--> nu ar trebui sa apara niciodata aceasta eroare:
	if @idcpv is null raiserror('Nu a fost identificat cpv-ul parinte!',16,1)
	
	if not exists (select 1 from nomencl n where n.cod=@cod)
		select @eroare='Nu exista codul de nomenclator specificat - "'+rtrim(@cod)+'" !'
		
	if len(@eroare)>0 raiserror(@eroare,16,1)
	
	select @eroare='Codul este deja alocat pe cpv-ul'+char(10)+rtrim(c.cod)+' - "'+rtrim(c.denumire)+'" !'+char(10)+'Nu este permisa alocarea simultana pe cpv-uri multiple!'
	from legCpvNomencl l inner join cpv c on l.idcpv=c.id
	where l.cod=@cod
	if len(@eroare)>0 raiserror(@eroare,16,1)
	
	if exists (select 1 from cpv c where c.idparinte=@idcpv)
	raiserror('Nu este permisa alocarea unui cod cpv care are subalterni!',16,1)	--> presupunere, trebuie confirmare pt verificarea asta
	
	if @o_cod is null
	insert into legcpvnomencl(idcpv, cod)
	select @idcpv, @cod
	else
	update legcpvnomencl set cod=@cod
	where idcpv=@idcpv and cod=@o_cod
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' ('+ OBJECT_NAME(@@PROCID)+')'
end catch
if object_id('tempdb..#sisteme') is not null drop table #sisteme
if len(@eroare)>0 raiserror(@eroare, 16,1)
