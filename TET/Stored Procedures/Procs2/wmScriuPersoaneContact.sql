--***
CREATE procedure wmScriuPersoaneContact @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmScriuPersoaneContactSP' and type='P')
begin
	exec wmScriuPersoaneContactSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(1000), @utilizator varchar(50), @tert varchar(100), @id varchar(100), @nume varchar(100), @functie varchar(100), @yahoomess varchar(100),
		@telefon varchar(100), @email varchar(100), @ptupdate int
set @eroare='(wmScriuPersoaneContact)'+char(10)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	if @utilizator is null 
		return -1

	-- identificare tert din par xml
	select @tert=f.tert--, @idPunctLivrare=f.idPunctLivrare
	from dbo.wmfIaDateTertDinXml(@parXML) f

	select	@id=@parXML.value('(row/@id)[1]','varchar(100)'),
			@nume=@parXML.value('(row/@nume)[1]','varchar(100)'),
			@functie=@parXML.value('(row/@functie)[1]','varchar(100)'),
			@yahoomess=@parXML.value('(row/@yahoomess)[1]','varchar(100)'),
			@telefon=@parXML.value('(row/@telefon)[1]','varchar(100)'),
			@email=@parXML.value('(row/@email)[1]','varchar(100)')
	
---------- tratare erori de operare (obiecte care nu exista in BD, greseli de formatare, etc):
	if charindex('@',@email)=0  and LEN(@email)>0
	begin
		set @eroare=rtrim(@eroare)+'Adresa de email nu este valida!'
		raiserror (@eroare,16,1)
	end
---------- scriere propriu-zisa:
	declare @xmlScriere xml
	set @ptupdate=(case when @id is null then 0 else 1 end)

	set @xmlScriere=
	(select @ptupdate as '@update', @tert as '@tert', @id as '@identificator', --@id as '@o_identificator',
				@nume as '@nume', @yahoomess as '@info7', @telefon as '@telefon', @email as '@email'
		 for xml path, type)
	exec wScriuPersoaneContact @sesiune, @xmlScriere
	
	select 'back(1)' as actiune
	for xml raw,Root('Mesaje')

end try

begin catch
	set @eroare=error_message()
	raiserror (@eroare,16,1)
end catch
