
CREATE PROCEDURE wOPScriuUtilizatorED @sesiune VARCHAR(50), @parXML XML
AS
DECLARE @utilizator VARCHAR(10), @numeprenume VARCHAR(30), @windows VARCHAR(100), @parola VARCHAR(100), @grupa varchar(5),
		@o_utilizator varchar(10), @o_parola varchar(100)

select	@utilizator = rtrim(@parXML.value('(/row/@utilizator)[1]', 'varchar(10)')),
		@numeprenume = rtrim(@parXML.value('(/row/@numeprenume)[1]', 'varchar(30)')),
		@windows = rtrim(@parXML.value('(/row/@utilizatorwindows)[1]', 'varchar(100)')),
		@parola = rtrim(@parXML.value('(/row/@parolaoffline)[1]', 'varchar(100)')),
		@grupa = rtrim((case @parXML.value('(/row/@egrupa)[1]', 'bit') when 1 then 'GRUP' else '' end)),
		@o_utilizator = rtrim(@parXML.value('(/row/@o_utilizator)[1]', 'varchar(10)')),
		@o_parola = isnull(rtrim(@parXML.value('(/row/@o_parolaoffline)[1]', 'varchar(100)')),'')

--> codificare parola:
select @parola=rtrim(case when @parola<>@o_parola then convert(varchar(100),HASHBYTES('MD5',@parola) ,2) else @parola end)

BEGIN TRY
--> adaugare
	if @o_utilizator is null	
		INSERT INTO utilizatori (ID, Nume, Observatii, Parola, Info, Categoria, Jurnal, Marca)
		-- id utilizator trebuie sa fie cu litere mari, pentru a fi recunoscut de PV off-line
		VALUES (upper(@utilizator), @numeprenume, @windows, '', @parola, '', '', @grupa)
--> modificare
	else begin 
		--select upper(@utilizator)+'|', @numeprenume+'|', @windows+'|', @parola+'|', @grupa+'|'
		update u set id=upper(@utilizator), nume=@numeprenume, observatii=@windows, info=@parola, marca=@grupa
		from utilizatori u where rtrim(u.id)=@o_utilizator
		end
	
	declare @x xml
	select @x=(select @utilizator utilizator for xml raw)
	exec wOPScriuUtilizatorED_p @sesiune=@sesiune, @parxml=@x
END TRY

BEGIN CATCH
	DECLARE @eroare VARCHAR(250)

	SET @eroare = 'Eroare la salvare date: ' + ERROR_MESSAGE()+' (wOPScriuUtilizatorED)'

	RAISERROR (@eroare, 15, 15)
END CATCH
