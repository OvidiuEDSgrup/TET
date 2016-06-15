	--***
Create procedure wStergCatProprietati @sesiune varchar(50)=null, @parxml xml=null
as

declare @eroare varchar(max)
begin try  
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @cod_proprietate varchar(100)
	
	select	@cod_proprietate=@parxml.value('(row/@cod_proprietate)[1]','varchar(100)')
	
	if @cod_proprietate is null
		or not exists (select 1 from catproprietati c where c.cod_proprietate=@cod_proprietate)
		raiserror('Nu s-a identificat proprietatea de modificat! Modificarile nu s-au salvat!',16,1)

	declare @tipproprietate varchar(100)
	
	select top 1 @tipproprietate=rtrim(tip) from proprietati p where p.Cod_proprietate=@cod_proprietate
	select @eroare='Proprietatea este folosita in proprietati (tipul '+@tipproprietate+')! Nu e permisa stergerea in aceasta situatie!'
	if @eroare is not null
		raiserror(@eroare,16,1)
		
	select top 1 @tipproprietate=rtrim(tip) from tipproprietati p where p.Cod_proprietate=@cod_proprietate
		select @eroare='Proprietatea este folosita in tipuri proprietati (tipul '+@tipproprietate+')! Nu e permisa stergerea in aceasta situatie!'
	if @eroare is not null
		raiserror(@eroare,16,1)
	
	delete c from catproprietati c where c.cod_proprietate=@cod_proprietate
	
end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@eroare)>0 raiserror(@eroare, 16,1)
