--***
Create
procedure wScriuProprietati @sesiune varchar(50), @parXML xml
as
	declare @ptupdate int, @Tip varchar(20), @Cod varchar(20), @Cod_proprietate varchar(20), @Valoare varchar(200), @Valoare_tupla varchar(200), 
	@Valoare_veche varchar(200), @Valoare_tupla_veche varchar(200), @fetch_crspropr int, 
	@stergere int, @mesaj varchar(254)

begin try
--	scriere
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsproprietati cursor for
	select ptupdate, tip, upper(cod) as cod, upper(cod_proprietate) as cod_proprietate, valoare, isnull(valoare_tupla,''), valoare_veche, isnull(valoare_tupla_veche,'')
	from OPENXML(@iDoc, '/row/row')
	WITH
	(
		ptupdate int '@update',
		tip char(20) '../@tip',
		cod char(20) '../@cod',
		cod_proprietate char(20) '@codproprietate',
		valoare char(200) '@valoare',
		valoare_tupla char(200) '@valoaretupla',
		valoare_veche char(200) '@o_valoare',
		valoare_tupla_veche char(200) '@o_valoaretupla'
	)

	open crsproprietati
	fetch next from crsproprietati into @ptupdate, @Tip, @Cod, @Cod_proprietate, @Valoare, @Valoare_tupla, 
	@Valoare_veche, @Valoare_tupla_veche
	set @fetch_crspropr=@@fetch_status

	while @fetch_crspropr= 0
	begin
		if @ptupdate=0 or not exists (select Valoare from proprietati where Tip=@Tip and Cod=@Cod and Cod_proprietate=@Cod_proprietate/* and Valoare=@Valoare*/)
			insert into proprietati (Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
			select @Tip, @Cod, @Cod_proprietate, @Valoare, @Valoare_tupla
		else
			update proprietati set Valoare=@Valoare, Valoare_tupla=@Valoare_tupla 
			where Tip=@Tip and Cod=@Cod and Cod_proprietate=@Cod_proprietate
			and Valoare=@Valoare_veche and Valoare_tupla=@Valoare_tupla_veche

		fetch next from crsproprietati into @ptupdate, @Tip, @Cod, @Cod_proprietate, @Valoare, @Valoare_tupla, 
		@Valoare_veche, @Valoare_tupla_veche
		set @fetch_crspropr=@@fetch_status	
	end

end try
begin catch
	--ROLLBACK TRAN
	set @mesaj =('wScriuProprietati:' )+ERROR_MESSAGE()
end catch

begin try 
	declare @cursorStatus int
	set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crsproprietati' and session_id=@@SPID )
	if @cursorStatus=1 
		close crsproprietati
	if @cursorStatus is not null 
		deallocate crsproprietati 
end try 
begin catch end catch

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch

if len(@mesaj)>0
	raiserror(@mesaj, 11, 1)

