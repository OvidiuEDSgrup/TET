--***
CREATE procedure wStergPozadoc @sesiune varchar(50), @parXML xml
as
declare @subunitate char(9), @tip varchar(2), @numar varchar(8), @data datetime, @numar_pozitie int, @eroare xml 

begin try

select @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
	@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(8)'), ''),
	@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
	@numar_pozitie=ISNULL(@parXML.value('(/row/@numarpozitie)[1]', 'int'), '')

delete pozadoc
where subunitate = @subunitate and tip = @tip and Numar_document = @numar and data = @data 
and (@numar_pozitie is null or numar_pozitie = @numar_pozitie)

exec wIaPozadoc @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
