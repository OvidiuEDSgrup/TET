--***
Create procedure wStergPozD112 @sesiune varchar(250), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozD112SP')
begin
	declare @returnValue int
	exec @returnValue=wStergPozD112SP @sesiune, @parXML output
	return @returnValue
end
begin try
	declare @utilizator char(20), @datalunii datetime, @idPozitie int, @mesaj varchar(500), @docXMLPozD112 xml
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select	@datalunii=ISNULL(@parXML.value('(/row/@datalunii)[1]','datetime'),''),
			@idPozitie=ISNULL(@parXML.value('(/row/row/@idPozitie)[1]','int'),'')

	delete from D112AsiguratE3 where Data=@datalunii and idPozitie=@idPozitie

	set @docXMLPozD112='<row datalunii="'+convert(char(10),@datalunii,101)+'"/>'

	exec wIaPozD112 @sesiune=@sesiune, @parXML=@docXMLPozD112

end try

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wStergPozD112)'
	raiserror(@mesaj,11,1) 
end catch
