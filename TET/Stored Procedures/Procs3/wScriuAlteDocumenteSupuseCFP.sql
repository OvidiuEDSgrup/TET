create procedure [dbo].[wScriuAlteDocumenteSupuseCFP] @sesiune varchar(50), @parXML xml  
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuAlteDocumenteSupuseCFPSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wScriuAlteDocumenteSupuseCFPSP @sesiune, @parXML output
	return @returnValue
end
DECLARE @Sub char(9), @utilizator varchar(10),@mesajeroare varchar(200),@indbug varchar(20),@tip_CFP varchar(1),@numar varchar(8),
	@data datetime,@numar_pozitie int,@compartiment varchar(13),
	@beneficiar varchar(13),@curs float,@observatii varchar(100),@scop varchar(100),@suma float,@suma_valuta float,
	@valuta varchar(3),@stare int,@data_CFP datetime

begin try	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	if @utilizator is null
		return -1

    select 
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),''),
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		@tip_CFP=isnull(@parXML.value('(/row/@tip_CFP)[1]','varchar(1)'),''),
		@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(8)'),''),
		@compartiment=isnull(@parXML.value('(/row/@compartiment)[1]','varchar(13)'),''),
		@beneficiar=isnull(@parXML.value('(/row/@beneficiar)[1]','varchar(13)'),''),
		@curs=isnull(@parXML.value('(/row/@curs)[1]','float'),0),
		@suma=isnull(@parXML.value('(/row/@suma)[1]','float'),0),
		@suma_valuta=isnull(@parXML.value('(/row/@suma_valuta)[1]','float'),0),
		@observatii=isnull(@parXML.value('(/row/@observatii)[1]','varchar(100)'),''),
		@scop=isnull(@parXML.value('(/row/@scop)[1]','varchar(100)'),''),
		@valuta=isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),''),
		@stare=isnull(@parXML.value('(/row/@stare)[1]','int'),0)	
		 
    if exists(select 1 from registrucfp where Numar=@numar and data=@data and tip=@tip_CFP and @indbug=indicator)
		raiserror('Acest document are deja alocata viza cfp!!',11,1)	     
    
	INSERT INTO altedocCFP ([Indicator],[Tip],[Numar],[Data],[Stare],[Loc_de_munca],[Beneficiar],[Suma],[Valuta],[Curs],[Suma_valuta],
		[Explicatii],[Observatii],[Utilizator] ,[Data_operarii],[Ora_operarii])
	SELECT  @indbug,@tip_CFP,@numar,@data,@stare,@compartiment,@beneficiar,@suma,@valuta,@curs,@suma_valuta,
		@scop,@observatii,@utilizator,convert(datetime, convert(char(10), getdate(), 101), 101),RTrim(replace(convert(char(8), getdate(), 108), ':', ''))

end try	
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
--select * from registrucfp order by data desc
