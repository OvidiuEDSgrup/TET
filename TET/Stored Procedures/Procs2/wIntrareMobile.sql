--***
create procedure wIntrareMobile @sesiune varchar(50), @parXML xml
as 
declare @comanda varchar(max), @proprietate varchar(100),	@id varchar(20),@nume varchar(100),@gestUser varchar(50)
declare @parola varchar(255), @msgEroare varchar(max), @aplicatie varchar(50), @versiuneApp varchar(50), @versiuneMinima varchar(50)
declare @serverrap varchar(200), @raspuns varchar(max), @mesajEroare varchar(4000), @clearCache bit
set nocount on
begin try

	select	@versiuneApp = @parXML.value('(/row/@versiune)[1]','varchar(50)')

	/* Daca e pus pe 1 se da reset la cache (se sterg atributele relevante si pozele)*/
	set @clearCache = 0;
	/* 
		versiunea minima pe server - daca userul a actualizat aplicatia, si versiunea de aplicatie solicita script-uri noi.
		de folosit doar daca e nevoie. Nu vrem sa fortam userii sa isi actualizeze scripturile pe server.
	*/
	declare @versiuneMinimaServer varchar(100) 
	set @versiuneMinimaServer = @parXML.value('(/row/@versiuneMinimaServer)[1]','varchar(100)')
	set @versiuneMinima=(select rtrim(val_alfanumerica) from par where Tip_parametru='AM' and Parametru='VERSIUNE')
	if @versiuneApp<@versiuneMinima
	begin
		set @mesajEroare='Va rugam actualizati aplicatia. '+CHAR(10)+
			'Versiunea minima este '+convert(varchar(100),@versiuneMinima)+'. Versiunea dvs. este '+convert(varchar(100),@versiuneApp)+'.'
		raiserror(@mesajEroare,11,1)
	end

	if @versiuneMinima<@versiuneMinimaServer
	begin
		set @mesajEroare='Contactati administratorul aplicatiei pentru actualizarea aplicatiei pe server. '+CHAR(10)+
			'Versiunea minima: '+convert(varchar(100),@versiuneMinimaServer)+'. Versiunea de pe server: '+convert(varchar(100),@versiuneMinima)+'.'
		raiserror(@mesajEroare,11,1)
	end
	
	declare @m1 XML, @m2 XML

	set @m1 = (select '@searchText' as atribute for xml raw('atributeRelevante'))
	set @m2 = (select @clearCache as _clearCache for xml raw)

	select @m1, @m2 for xml raw('Mesaje');
	
end try
begin catch 
	declare @errormessage varchar(2000), @errorseverity varchar(2000), @errorstate varchar(500)
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch
