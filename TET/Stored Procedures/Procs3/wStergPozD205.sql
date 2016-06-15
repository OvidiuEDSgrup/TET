--***
Create procedure wStergPozD205 @sesiune varchar(250), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozD205SP')
begin
	declare @returnValue int
	exec @returnValue=wStergPozD205SP @sesiune, @parXML output
	return @returnValue
end
begin try
	declare @utilizator char(20), @an int, @lm varchar(9), @marca varchar(6), 
		@tipvenit char(2), @tipimpozit char(1), @cnp varchar(13), @tipfunctie varchar(1), @mesaj varchar(500), @docXMLPozD205 xml
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	select @an=ISNULL(@parXML.value('(/row/@an)[1]','int'),0),
		@lm=ISNULL(@parXML.value('(/row/row/@lm)[1]','char(9)'),''),
		@tipvenit=ISNULL(@parXML.value('(/row/row/@tipvenit)[1]','char(2)'),''),
		@tipimpozit=ISNULL(@parXML.value('(/row/row/@tipimpozit)[1]','char(1)'),''),
		@marca=ISNULL(@parXML.value('(/row/row/@marca)[1]','varchar(6)'),''),
		@cnp=ISNULL(@parXML.value('(/row/row/@cnp)[1]','char(13)'),''),
		@tipfunctie=ISNULL(@parXML.value('(/row/row/@tipfunctie)[1]','char(1)'),'')

	delete from DateD205 where An=@an and Loc_de_munca=@lm and Tip_venit=@tipvenit and Tip_impozit=@tipimpozit and Marca=@marca and CNP=@cnp and Tip_functie=@tipfunctie

	set @docXMLPozD205='<row an="'+convert(char(4),(@an))+'"/>'

	exec wIaPozD205 @sesiune=@sesiune, @parXML=@docXMLPozD205

end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
