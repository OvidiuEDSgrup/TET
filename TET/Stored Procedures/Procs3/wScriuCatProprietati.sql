	--***
Create procedure wScriuCatProprietati @sesiune varchar(50)=null, @parxml xml=null
as

declare @eroare varchar(max)
begin try  
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	declare @cod_proprietate varchar(100),
			@descriere varchar(100),
			@validare varchar(100),
			@catalog varchar(100),
			@proprietate_parinte varchar(100),
			@update int,
			@o_cod_proprietate varchar(100)

	select	@cod_proprietate=@parxml.value('(row/@cod_proprietate)[1]','varchar(100)'),
			@descriere=@parxml.value('(row/@descriere)[1]','varchar(100)'),
			@validare=@parxml.value('(row/@validare)[1]','varchar(100)'),
			@catalog=@parxml.value('(row/@catalog)[1]','varchar(100)'),
			@proprietate_parinte=@parxml.value('(row/@proprietate_parinte)[1]','varchar(100)'),
			@update=@parxml.value('(row/@update)[1]','int'),
			@o_cod_proprietate=@parxml.value('(row/@o_cod_proprietate)[1]','varchar(100)')

	select @update=isnull(@update,0)
	if @update=1 and (@o_cod_proprietate is null
		or not exists (select 1 from catproprietati c where c.cod_proprietate=@o_cod_proprietate))
		raiserror('Nu s-a identificat proprietatea de modificat! Modificarile nu s-au salvat!',16,1)

	if (@cod_proprietate<>@o_cod_proprietate or @update=0) and
		exists (select 1 from catproprietati c where c.cod_proprietate=@cod_proprietate)
		raiserror('Exista deja o proprietate cu codul completat! Modificarile nu s-au salvat!',16,1)

	if @cod_proprietate<>@o_cod_proprietate
	begin
		declare @tipproprietate varchar(100)
		
		select top 1 @tipproprietate=rtrim(tip) from proprietati p where p.Cod_proprietate=@o_cod_proprietate
		select @eroare='Proprietatea este folosita in proprietati (tipul '+@tipproprietate+')! Nu e permisa modificarea codului in aceasta situatie!'
		if @eroare is not null
			raiserror(@eroare,16,1)
			
		select top 1 @tipproprietate=rtrim(tip) from tipproprietati p where p.Cod_proprietate=@o_cod_proprietate
			select @eroare='Proprietatea este folosita in tipuri proprietati (tipul '+@tipproprietate+')! Nu e permisa modificarea codului in aceasta situatie!'
		if @eroare is not null
			raiserror(@eroare,16,1)
	end


	if @update=0
	insert into catproprietati(Cod_proprietate, Descriere, Validare, Catalog, Proprietate_parinte)
		select upper(@Cod_proprietate), @Descriere, @Validare, @Catalog, @Proprietate_parinte

	if @update=1
	update c
		set Cod_proprietate=upper(@cod_proprietate), Descriere=@descriere, Validare=@validare,
			Catalog=@catalog, Proprietate_parinte=@proprietate_parinte
	from catproprietati c
	where c.cod_proprietate=@o_cod_proprietate

end try
begin catch
	set @eroare=ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
end catch

if len(@eroare)>0 raiserror(@eroare, 16,1)
