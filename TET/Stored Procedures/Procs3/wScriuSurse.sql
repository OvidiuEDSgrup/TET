--***
create procedure wScriuSurse @sesiune varchar(50), @parXML xml 
as
declare @cod varchar(8),@denumire varchar(200), @update int, @ocod varchar(8)
declare @iDoc int 
begin try
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select @cod=upper(Cod), @ocod=oCod, @denumire=upper(Denumire), @update=_upd
	 from OPENXML(@iDoc, '/row')
	WITH 
		(
			Cod varchar(8) './@cod', 
			oCod varchar(8) './@o_cod', 
			Denumire varchar(200)'./@denumire', 
			_upd int'./@update'
		 )
	if isnull(@cod,'')='' 
	begin
		--CRISTI CIUPE + ANDREI
		set @cod=(select ISNULL(max(convert(float,cod)),1)+1 from surse where ISNUMERIC(cod)=1)
	end 
		  
	if @denumire is null or @denumire='' 
	begin		
		raiserror ('Denumire necompletata',16,1)
	end 

	if isnull(@update,0)=0  --adaugare
		begin
		if exists (select 1 from surse where Cod=@cod) --or Denumire=@denumire)
			raiserror('Sursa introdusa exista deja in baza de date!',16,1)
		else 
			 if isnull(@cod,'')<>''
				insert into surse (Cod, Denumire) values(@cod, @denumire)	
		end
	else
		if @cod<>@ocod
			raiserror('Nu se poate modifica codul sursei!',16,1)
		else
			update surse set Denumire=@denumire where cod=@cod

	exec sp_xml_removedocument @iDoc 
end try
begin catch
	declare @mesaj varchar(255)
	set @mesaj = ERROR_MESSAGE() 
	raiserror(@mesaj, 11, 1)
end catch
