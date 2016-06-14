--***
IF exists (SELECT * FROM sysobjects WHERE name ='yso_wOPStornareDocument_p')
DROP PROCEDURE yso_wOPStornareDocument_p
go
--***
/****** Object:  StoredProcedure [dbo].[wOPModificareAntetCon_p]    Script Date: 04/06/2011 10:58:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
CREATE PROCEDURE yso_wOPStornareDocument_p @sesiune VARCHAR(50), @parXML XML 
AS  
BEGIN TRY
	DECLARE /*date de identificare document:*/@sub VARCHAR(9),@tip VARCHAR(2),@data DATETIME,@contract VARCHAR(20),@numar VARCHAR(20),
		/*alte variabile necesare:*/@utilizator VARCHAR(20), @eroare VARCHAR(250),@factura VARCHAR(20),@numardoc VARCHAR(20),
		@NrAvizeUnitar INT, @lm VARCHAR(13),@idPozDoc INT,
		/*pentru identificare bon stornat*/@idantetbon int, @numarBon varchar(100),@casa varchar(100), @tertstorno varchar(20), @tipdoc varchar(2)
--/*SP
		,@CTCLAVRT bit,@ContAvizNefacturat varchar(20), @avizNefacturat bit

		exec luare_date_par 'GE', 'CTCLAVRT ', @CTCLAVRT  output, 0, @ContAvizNefacturat output
--SP*/

	SELECT
		--date pt identificare document care se storneaza 
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@factura=ISNULL(@parXML.value('(/row/@factura)[1]', 'varchar(20)'), ''),
		@idPozDoc=ISNULL(@parXML.value('(/row/@idPozDoc)[1]', 'INT'), ''),
		@lm=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), ''),
		@idantetbon=ISNULL(@parXML.value('(/row/@idantetbon)[1]', 'int'), 0)
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identificare utilizator pe baza sesiunii
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati    
	
	if isnull(@idantetbon,0)>0--daca se doreste stornare bon(dinspre macheta de bonuri)
	begin
		--identific documentul care trebuie stornat
		select top 1 
			@numar= bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'),
			@data=Data_bon,
			@tip=bon.value('(/date/document/@tipdoc)[1]','varchar(2)'),
			@numarBon=numar_bon,
			@casa=casa_de_marcat
		from antetBonuri where IdAntetBon=@idantetbon

		set @tipDoc=@tip
	end
	
	select @tip=(case when @tip in ('RC','RA','RF') then 'RM' when @tip in ('AA','AB') then 'AP' else @tip end)

	IF @numar=''
	BEGIN
		SELECT 'Selectati mai intai documentul pentru stornare!' AS textMesaj FOR XML RAW, ROOT('Mesaje')
		RETURN -1
	END  
	
	select top (1) @avizNefacturat=(case when p.Tip in ('AP','AS') and isnull(d.Cont_factura,p.Cont_factura) =@ContAvizNefacturat then 1 else 0 end )
	FROM pozdoc p
		left JOIN doc d on d.Subunitate=p.Subunitate and d.Tip=p.Tip and d.Data=p.Data and d.Numar=p.Numar
	WHERE p.Subunitate=@sub AND p.tip=@tip
		AND p.data=@data AND p.Numar=@numar
	
	if @avizNefacturat=1 
		if @parXML.value('(/*/@aviznefacturat)[1]', 'bit') is null
			set @parxml.modify('insert attribute aviznefacturat {sql:variable("@avizNefacturat")} into (/*)[1]')
		else 
			set @parXML.modify('replace value of (/row/@aviznefacturat)[1] with sql:variable("@avizNefacturat")')
	
	exec wOPStornareDocument_p @sesiune, @parXML
	
END TRY	
BEGIN CATCH
	SET @eroare = ERROR_MESSAGE()
	RAISERROR(@eroare, 11, 1)	
END CATCH

/*select * from pozdoc*/