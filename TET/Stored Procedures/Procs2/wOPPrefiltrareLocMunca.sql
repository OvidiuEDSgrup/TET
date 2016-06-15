
CREATE PROCEDURE wOPPrefiltrareLocMunca @sesiune VARCHAR(30), @parXML XML
AS
	if exists (select * from sysobjects where name='wOPPrefiltrareLocMuncaSP' and type='P')      
	begin
		exec wOPPrefiltrareLocMuncaSP @sesiune, @parXML
		return 0
	end

	declare
		@utilizator varchar(100), @lm varchar(20), @nume_user varchar(200),  @nume_bd varchar(200)


	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	set @lm = @parXML.value('(/*/@lm)[1]','varchar(20)')

	if isnull(@lm,'')=''
	begin
		raiserror ('Alegeti obligatoriu o unitate!!!',16,1)
		return -1
	end	

	if isnull(@lm,'') not in (select cod from lm)
	begin
		raiserror ('Unitatea selectata nu este definita!!!',16,1)
		return -1	
	end	

	IF isnull(@lm,'')<>''
	begin
			delete FROM LMFiltrare where utilizator=@utilizator

			insert into LMFiltrare (utilizator,cod)
			select @utilizator, lm.cod
			from lm 
			where cod like @lm+'%'

			select top 1 @nume_user= rtrim(nume) from utilizatori where id=@utilizator
			select top 1 @nume_bd = RTRIM(nume) from asisria..bazedeDateRIA where BD=DB_NAME()

			select top 1
				@nume_bd +' ['+RTRIM(lm.denumire)+'] '+ @nume_user as text
			from lm 
			where cod=@lm
			for xml RAW('textControlBar'), ROOT('Mesaje')
	end
