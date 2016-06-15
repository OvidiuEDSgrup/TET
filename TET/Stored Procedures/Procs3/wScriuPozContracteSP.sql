
CREATE PROCEDURE wScriuPozContracteSP @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY /*
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozContracteSP')
		exec wScriuPozContracteSP @sesiune=@sesiune, @parXML=@parXML OUTPUT SP*/
	
	SET NOCOUNT ON
	DECLARE 
		@idContract INT, @tert VARCHAR(20), @update BIT, @utilizator VARCHAR(100),  @tipContract VARCHAR(2), @numar varchar(20),
		@gestiuneProprietate VARCHAR(20), @clientProprietate VARCHAR(20), @lmProprietate VARCHAR(20), @gestiuneDepozitBK VARCHAR(20),
		@docJurnal XML, @docRefresh XML, @docPlaje XML, @documente int, @fara_luare_date bit, @mesaj varchar(max), @subunitate varchar(9), 
		@lm varchar(20), @serieprimita varchar(9), @idPlajaPrimit int, @serieInNumar bit, @punct_livrare varchar(20)
		,@stare int

	/** Informatii identificare antet **/
	SET @tipContract = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
	SET @stare = @parXML.value('(/*/@stare)[1]', 'int')
	
	/** Alte **/
	SET @fara_luare_date= isnull(@parXML.value('(/*/@fara_luare_date)[1]', 'bit'),0)
	SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)

	/*** Utilizator  si parametri*/
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT

	/** Valori din proprietati **/
	SELECT	
		@gestiuneProprietate = (CASE WHEN cod_proprietate = 'GESTBK' THEN valoare ELSE @gestiuneProprietate END), 
		@clientProprietate = (CASE WHEN cod_proprietate = 'CLIENT' THEN valoare ELSE @clientProprietate END), 
		@lmProprietate = (CASE WHEN cod_proprietate = 'LOCMUNCA' THEN valoare ELSE @lmProprietate END), 
		@gestiuneDepozitBK = (CASE WHEN cod_proprietate = 'GESTDEPBK' THEN valoare ELSE @gestiuneDepozitBK END)
	FROM proprietati
	WHERE tip = 'UTILIZATOR' AND cod = @utilizator AND cod_proprietate IN ('GESTBK', 'CLIENT', 'LOCMUNCA', 'GESTDEPBK') AND valoare <> ''
	
	declare @gestimpl varchar(10)
			
	if isnull(@gestimpl,'')=''
		select top 1 @gestimpl=Valoare from proprietati p
			where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('GESTIUNEIMPLICITA') and p.valoare<>'' and p.Valoare_tupla=''
			
	if isnull(@parXML.value('(/row/@gestiune)[1]','varchar(10)'),'')='' and ISNULL(@gestimpl,'')<>'' 
		if @parXML.value('(/row/@gestiune)[1]','varchar(10)') is null
			set @parXML.modify ('insert attribute gestiune {sql:variable("@gestimpl")} into (/row)[1]')
		else
			set @parXML.modify('replace value of (/row/@gestiune)[1] with sql:variable("@gestimpl")')	
			
	declare @lmimplicit varchar(10)
		
	if isnull(@lmimplicit,'')=''
		select top 1 @lmimplicit=i.Loc_munca from infotert i 
			inner join proprietati p on p.tip='UTILIZATOR' and p.cod=@utilizator and p.cod_proprietate in ('LOCMUNCA') 
				and i.Loc_munca like RTRIM(p.Valoare)+'%' and p.Valoare_tupla=''
		where i.Subunitate=@subunitate and i.Tert=@tert and i.Identificator='' 
		
	if isnull(@lmimplicit,'')=''
		select top 1 @lmimplicit=Valoare from proprietati 
			where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCASTABIL') and valoare<>'' and Valoare_tupla=''
	
	if isnull(@lmimplicit,'')='' 
		select top 1 @lmimplicit=loc_de_munca from gestcor g 
			inner join proprietati p on p.Valoare=g.Gestiune and p.Cod=@utilizator and p.Tip='UTILIZATOR' 
				and p.Cod_proprietate='GESTIUNE' and p.Valoare_tupla='' 
		where gestiune in (@parXML.value('(/row/@gestiune)[1]','varchar(10)'),@parXML.value('(/row/@gestiune_primitoare)[1]','varchar(10)')) and g.Loc_de_munca<>''
		order by case g.Gestiune when isnull(@parXML.value('(/row/@gestiune)[1]','varchar(10)'),'') then 1 else 2 end
		
	if isnull(@lmimplicit,'')=''
		select top 1 @lmimplicit=Valoare from proprietati 
			where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA') and valoare<>'' and Valoare_tupla=''
	
	if ISNULL(@lmimplicit,'')<>'' and nullif(@parXML.value('(/row/@lm)[1]','varchar(9)'),'') is null --and @lm<>ISNULL(@lmimplicit,'')
		if @parXML.value('(/row/@lm)[1]','varchar(9)') is null
			set @parXML.modify ('insert attribute lm {sql:variable("@lmimplicit")} into (/row)[1]')
		else
			if @parXML.value('(/row/@lm)[1]','varchar(9)')<>@lmimplicit
				set @parXML.modify('replace value of (/row/@lm)[1] with sql:variable("@lmimplicit")')
				
	if @stare is null
		set @parXML.modify ('insert attribute stare {"-15"} into (/row)[1]')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozContracteSP)'
	RAISERROR (@mesaj, 11, 1)
END CATCH