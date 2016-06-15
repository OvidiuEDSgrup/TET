--***
create 
procedure wStergSalariiZilieri @sesiune varchar(250), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergSalariiZilieriSP')
	begin
		declare @returnValue int
		exec @returnValue=wStergSalariiZilieriSP @sesiune, @parXML output
		return @returnValue
	end
begin try
	declare @utilizator char(20), @lmantet varchar(9), @marca int, @mesaj varchar(500), @data datetime, @nrcrt smallint,
	@docXMLIaSalariiZilieri xml
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select @lmantet=ISNULL(@parXML.value('(/row/@lmantet)[1]','varchar(9)'),0),
	@marca=ISNULL(@parXML.value('(/row/@marca)[1]','int'),0),
	@data=ISNULL(@parXML.value('(/row/@data)[1]','datetime'),''),
	@nrcrt=ISNULL(@parXML.value('(/row/@nrcrt)[1]','smallint'),0)	
	
	delete from salariizilieri where Marca=@marca and convert(char(10),Data,101)=@data and Nr_curent=@nrcrt
	set @docXMLIaSalariiZilieri='<row lmantet="'+rtrim(@lmantet)+'" data="'+convert(char(10),dbo.eom(@data),101)+'"/>'
	exec wIaPozSalariiZilieri @sesiune=@sesiune, @parXML=@docXMLIaSalariiZilieri

end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
