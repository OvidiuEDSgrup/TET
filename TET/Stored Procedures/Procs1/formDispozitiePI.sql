create PROCEDURE [dbo].[formDispozitiePI] @sesiune VARCHAR(50), @parXML XML, @numeTabelTemp VARCHAR(100) OUTPUT     
AS    
begin try     
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
	declare @tip varchar(2),@numar varchar(20),@data datetime,@subunitate varchar(9),@debug int,@cont varchar(20),@userASiS varchar(200),@idPozPlin int
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT  

	 /** Filtre **/    
	SET @cont=@parXML.value('(/*/@cont)[1]', 'varchar(20)')    
	SET @tip=@parXML.value('(/*/row/@tip)[1]', 'varchar(2)')    
	SET @numar=@parXML.value('(/*/row/@numar)[1]', 'varchar(20)')    
	SET @data= @parXML.value('(/*/row/@data)[1]', 'datetime')    
	SET @idPozPlin=@parXML.value('(/*/row/@idPozPlin)[1]', 'int')    
	if @tip is null --Pentru date din MOBILE
	begin
		select top 1 @cont=valoare from proprietati where tip='UTILIZATOR' and Cod_proprietate='CONTPLIN' and cod=@userASiS
		SET @tip=@parXML.value('(/*/@tip)[1]', 'varchar(2)')    
		SET @numar=@parXML.value('(/*/@numar)[1]', 'varchar(20)')    
		SET @data= @parXML.value('(/*/@data)[1]', 'datetime')    
	end   
     
	/* Alte **/    
	set @debug=0
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT    

	select 
		p.numar,
		p.numar as doc, 
		replace(convert(char(10), p.data, 103),'/','.') data,
		pp.Nume,
		ff.Denumire as functia,
		convert(decimal(12,2),p.Suma) as suma,
		dbo.Nr2Text(p.suma) as sumalitere,
		p.Explicatii,
		pp.copii as seria
	into #fmic
	FROM pozplin p
	left outer join facturi f on f.Tip=0x46 and f.Tert=p.Tert and f.Factura=p.Factura
	left outer join personal pp on p.Marca=pp.Marca
	left outer join functii ff on pp.cod_functie=ff.cod_functie
	WHERE p.Subunitate=@subunitate and p.Cont=@cont and p.Data=@data and p.Numar=@numar and p.idPozPlin=@idPozPlin

	declare @textReprezentand varchar(8000)
	set @textReprezentand=''

	SELECT *
	into #selectMare    
	FROM #fmic f   
    
	declare @cTextSelect nvarchar(max),@mesaj varchar(8000)    
    
	SET @cTextSelect = '    
	SELECT *    
	into ' + @numeTabelTemp + '    
	from #selectMare    
	ORDER BY data,numar    
	'    
    
	EXEC sp_executesql @statement = @cTextSelect    
    
	IF @debug = 1    
	BEGIN    
		SET @cTextSelect = 'select * from ' + @numeTabelTemp    
		EXEC sp_executesql @statement = @cTextSelect    
	END    
end try    
begin catch    
	set @mesaj=ERROR_MESSAGE()+ ' (formChitanta)'    
	raiserror(@mesaj, 11, 1)    
end catch    
return
