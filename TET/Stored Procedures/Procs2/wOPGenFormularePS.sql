/* operatie pt. vizualizare formulare specifice PS (adeverinte pe salariat, cerere restituire indemnizatii de la FNUASS, contracte de munca, etc) cu formular SQL */
create procedure wOPGenFormularePS (@sesiune varchar(50), @parXML xml) 
as     

declare @utilizator varchar(10), @tip varchar(1), @formular varchar(13), @data datetime, @lunaalfa varchar(15), @nradev varchar(10), @dataadev datetime, @nrluni int, 
	@dataJos datetime, @dataSus datetime, @marca varchar(6), @lm varchar(20), @ordonare char(1), @inXML varchar(1), @mesaj varchar(254), @debug bit, 
	@CLFrom varchar(100), @caleRaport varchar(1000)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenFormularePS' 

	if exists (select * from sysobjects where name ='wOPGenFormularePSSP')
		exec wOPGenFormularePSSP @sesiune=@sesiune, @parXML=@parXML

	select	@formular = isnull(@parXML.value('(/parametri/@formular)[1]','varchar(13)'),''),	
		@data = isnull(@parXML.value('(/parametri/@data)[1]','datetime'),0),
		@marca = isnull(@parXML.value('(/parametri/@marca)[1]','varchar(6)'),''),
		@lm = isnull(@parXML.value('(/parametri/@lm)[1]','varchar(20)'),''),
		@nradev = isnull(@parXML.value('(/parametri/@nradev)[1]','varchar(10)'),''),
		@dataadev = isnull(@parXML.value('(/parametri/@dataadev)[1]','datetime'),0),
		@nrluni = isnull(@parXML.value('(/parametri/@nrluni)[1]','int'),''),
		@inXML = @parXML.value('(/parametri/@inXML)[1]','varchar(1)'),
		@debug = isnull(@parXML.value('(/parametri/@debug)[1]','bit'),0)
		
	set @dataJos=dbo.BOM(@data)
	set @dataSus=dbo.eom(@dataJos)
	select @lunaalfa=LunaAlfa from fCalendar(@dataSus,@dataSus)

	if @formular=''
	begin
		raiserror('Eroare: Formular necompletat!',11,1)
		return -1
	end
	select @tip=tip_formular from antform where Numar_formular=@formular
	if isnull(@tip,'')='' set @tip='W'
	select @CLFrom=CLFrom, @caleRaport=rtrim(CLWhere) from antform where numar_formular=@formular

--	formular
    delete from avnefac where terminal=@utilizator
	insert into avnefac(Terminal, Subunitate, Tip, Numar, Cod_gestiune, Data, Cod_tert, Factura, Contractul, Data_facturii, Loc_munca, Comanda, 
		Gestiune_primitoare, Valuta, Curs, Valoare, Valoare_valuta, Tva_11, Tva_22, Cont_beneficiar, Discount) 
	values (@utilizator, '1', 'AD', (case when @marca='' then @nradev else @marca end), '', @dataSus, '', '', '', (case when @marca='' then @dataadev else dbo.eom(DateAdd(month,-@nrluni,@data)) end), 
		@lm, @nradev, '', '', 0, @nrluni, 0, 0, 0, convert(char(10),@dataadev,103), 0)
	
	if exists (select 1 from antform where Tip_formular='6' 
		and (clfrom like '% flutur %' or clfrom like '% flutur,%')
		and numar_formular=@formular)
		if exists(select * from sysobjects where name='ptFluturasiSP' and type='P')
			exec ptFluturasiSP @cTerm=@utilizator, @sesiune=@sesiune
		else 
	    	exec ptFluturasi @cTerm=@utilizator, @sesiune=@sesiune	/**	Lucian: se executa doar daca am nevoie de date din tabela flutur pt. formularul de fluturasi*/
    	
    --declare @DelayLength char(8)= '00:00:01'
	-- WAITFOR delay @DelayLength
    declare @paramXmlString varchar(max)
    set @paramXmlString= (select @tip as tip, @formular as nrform, 0 as scriuavnefac, (case when @CLFrom='Raport' then @caleRaport end) as caleRaport, 
	    @dataSus as data, @dataSus as datalunii, (case when @marca='' then @nradev else @marca end) as numar, @marca as marca, @nradev as nrinreg, '' as Cod_gestiune, '' as Cod_tert, '' as factura, 
		@dataJos as data_facturii, '' as loc_munca, @inXML as inXML, @debug as debug, @lm as lm, @utilizator as utilizator for xml raw)
	--select @paramXmlString
	if @CLFrom='Raport'
		exec wExportaRaport @sesiune=@sesiune, @parXML=@paramXmlString
	else 
		exec wTipFormular @sesiune=@sesiune, @parXML=@paramXmlString
    delete from avnefac where terminal=@utilizator
end try

begin catch
	select 0 as inchideFereastra for xml raw,root('Mesaje')
	set @mesaj = '(wOPGenFormularePS) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
