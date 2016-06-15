
CREATE PROCEDURE [dbo].[wOPStornareBonSP] @sesiune varchar(50), @parXML XML
AS
begin try
--/*sp
		declare @procid int=@@procid, @objname sysname
		set @objname=object_name(@procid)
		EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	declare
		@sub varchar(9), @utilizator varchar(100), @gestiune varchar(20), @lm varchar(20), @databon datetime, @data datetime, @tert varchar(20), @faraGenerarePlin int, 
		@mesaj varchar(max), @cont_casa varchar(20), @idantetbon int, @numar_PozDoc varchar(20), 
		@docAP xml, @docRE xml, @numarAP varchar(20), @docPlaja xml, @sumaPD float,	@cant_eroare int, @DetaliereBonuri int, @comandaSql varchar(max)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT	

	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@sub,'') end),
			@DetaliereBonuri=(case when Parametru='DETBON' then Val_logica else isnull(@DetaliereBonuri, 0) end)
	from par
	where Tip_parametru='GE' and Parametru in ('SUBPRO')
		or Tip_parametru='PO' and Parametru in ('DETBON') 

	set @idantetbon = @parXML.value('(/*/@idantetbon)[1]','int')
	set @gestiune = @parXML.value('(/*/@gestiune_storno)[1]','varchar(20)')
	set @lm = @parXML.value('(/*/@lm_storno)[1]','varchar(20)')
	set @tert = @parXML.value('(/*/@tert_storno)[1]','varchar(20)')
	set @data = @parXML.value('(/*/@data_storno)[1]','datetime')
	set @faraGenerarePlin = isnull(@parXML.value('(/*/@faraplin)[1]','int'),0)
	
	select 
		@cont_casa=dbo.wfProprietateUtilizator('CONTCASA',@utilizator)

	if isnull(@tert,'')=''
		raiserror('Tertul nu este completat! Completati tertul care va fi folosit la intocmirea facturii de stornare!',16,1)

	IF OBJECT_ID('tempdb..#bonstorn') is not null
		drop table #bonstorn

	--IF exists (select 1 from antetBonuri where IdAntetBon=@idantetbon and isnull(Factura,'')<>'')
	--	raiserror('Bonul selectat are factura atasata! Folositi modulul de facturare pentru a generare factura storno',16,1)

	-- Verificare sa nu existe pozitii cu cantitatea storno mai mare decat cantitatea actuala sau valori pozitive pentru cantitatea storno
	select @cant_eroare = (
		select count(*)
			from @parXML.nodes('parametri/DateGrid/row') as x(i)
				inner join @parXML.nodes('parametri/o_DateGrid/row') as y(i) 
					on x.i.value('@cod_produs','varchar(20)')=y.i.value('@cod_produs','varchar(20)')
						and x.i.value('@nrlinie','int')=y.i.value('@nrlinie','int')
			where (x.i.value('@cant_storno','decimal(17,2)') < y.i.value('@cant_storno','decimal(17,2)')) or (x.i.value('@cant_storno','decimal(17,2)') > 0)
		)

	if @cant_eroare > 0
		raiserror('Exista pozitii cu cantitatea storno gresita.',16,1)

	SELECT
		x.i.value('@cod_produs','varchar(20)') as cod,
		--x.i.value('@denumire','varchar(100)') as denumire,
		--x.i.value('@gestiune','varchar(100)') as gestiune,
		--x.i.value('@cantitate','decimal(17,2)') as cantitate,
		--x.i.value('@pret','decimal(17,2)') as pret,
		x.i.value('@cant_storno','decimal(17,2)') as cant_storno,
		isnull(x.i.value('@idPozdoc','int'),0) as idPozdoc
	into #bonstorn
	from @parXML.nodes('parametri/DateGrid/row') as x(i) 
	where x.i.value('@cant_storno','decimal(17,2)') <> 0 

	select top 1 
		@numar_PozDoc= bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'),
		@databon=Data_bon
	from antetBonuri where IdAntetBon=@idantetbon

	if isnull(@numar_PozDoc,'')=''
		raiserror('Nu s-a putut identifica documentul contabil asociat bonului (PozDoc)',16,1)

	set @docPlaja=(SELECT @utilizator utilizator, 'AP' as tip, @lm lm for xml raw)
	exec wIauNrDocFiscale @parXML=@docPlaja, @nrDoc=@numarAP OUTPUT

	IF OBJECT_ID('tempdb..#acstorno') is not null
		drop table #acstorno
	IF OBJECT_ID('tempdb..#acstornocod') is not null
		drop table #acstornocod

	select 
		pd.*
	into #acstorno
	from PozDoc pd where pd.Subunitate='1' and pd.tip='AC' and pd.Numar=@numar_PozDoc and Data=@databon

	/*	daca @DetaliereBonuri=1 (s-a generat pentru fiecare bon un AC), se va face stornarea pana la nivel de cod intrare de pe AC-ul initial. Afisam si codul de intrare in Grid */
	set @docAP=
	(
		SELECT
			'AP' tip, '1' fara_luare_date, convert(varchar(10), @data,101) data, @numarAP numar, @tert tert, @gestiune gestiune, @lm lm,
			convert(varchar(10), @data,101) data_facturii, @numarAP factura,
			(
				SELECT
					rtrim(bs.cod) cod, convert(decimal(15,2), bs.cant_storno) cantitate, rtrim(ac.gestiune) as gestiune, rtrim(ac.cod_intrare) codintrare,
					convert(decimal(15,5),ac.pret_valuta) pvaluta, convert(decimal(15, 5), ac.pret_vanzare) pret_vanzare, convert(decimal(15, 2), round(ac.pret_cu_amanuntul,2)) pamanunt,
					convert(decimal(12,3),ac.discount) discount, (case when ac.Gestiune_primitoare like '378.%' then ac.Gestiune else rtrim(ac.gestiune_primitoare) end) gestprim, 
					rtrim(ac.Cont_corespondent) contcorespondent, rtrim(ac.Cont_venituri) contvenituri, 
					(case when ac.Gestiune_primitoare like '378%' then '371.'+rtrim(ac.Gestiune) else rtrim(ac.Cont_intermediar) end) contintermediar, 
					(case when @DetaliereBonuri=1 then convert(int,ac.Accize_cumparare) end) categpret
					,cotatva=convert(decimal(5,2),ac.Cota_tva)
					/*convert(decimal(12,2),(case when @DetaliereBonuri=1 and abs(bs.cant_storno)=ac.cantitate then ac.TVA_deductibil 
						else round(ac.pret_cu_amanuntul,2)*bs.cant_storno*ac.Cota_tva/(100+ac.Cota_tva) end)) 
						--Cristy: Aici e o problema veche. Oricum trebuie modificata operatia de stornare bon dupa specificare completa a problemei.
						*/
				from #bonstorn bs
					CROSS APPLY (SELECT top 1 * from #acstorno where (@DetaliereBonuri=0 and cod=bs.cod or @DetaliereBonuri=1 and idPozdoc=bs.idPozdoc)) ac
				for xml raw, type
			)
		for xml raw		
	)

	if exists (select * from sysobjects where name ='wScriuDoc')
		exec wScriuDoc @sesiune=@sesiune, @parXML=@docAP OUTPUT
	else 
	if exists (select * from sysobjects where name ='wScriuDocBeta')
		exec wScriuDocBeta @sesiune=@sesiune, @parXML=@docAP OUTPUT
	else 
		raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc(beta).', 16, 1)


	--exec wScriuPozDoc @sesiune=@sesiune, @parXML=@docAP

	if @faraGenerarePlin=0
	begin
		select 
			@sumaPD=-SUM(cantitate*Pret_vanzare+TVA_deductibil)--SUM(cantitate*Pret_cu_amanuntul)
		from PozDoc where Subunitate='1' and tip='AP' and numar=@numarAP and data=@data

		declare 
			@numar_bon varchar(20), @data_bon varchar(10)

		select 
			@numar_bon=convert(varchar(10),Numar_bon), @data_bon=convert(varchar(10),Data_bon,103)
		from antetBonuri where IdAntetBon=@idantetbon

		set @docRE=
			(
				SELECT
					@cont_casa cont, convert(varchar(10), @data,101) data,'RE' tip, 
					(
						select
							'AP'+@numarAP numar, convert(decimal(15,2),@sumaPD) suma,  'PS' subtip,
							'Stornare bon '+ @numar_bon+ ' din data '+@data_bon explicatii, @tert tert, @numarAP factura
						for XML raw, TYPE
					)
				for xml RAW
			)

		exec wScriuPozplin @sesiune=@sesiune, @parXML=@docRE
	end
	SELECT 'S-a generat cu succes documentul storno tip AP '+RTRIM(@numarAP)+' din data de '+LTRIM(CONVERT(VARCHAR(20),@data,103))
		+(case when @faraGenerarePlin=0 then ' si PS de stornare pe aceeasi data' else '' end) AS textMesaj for xml raw, root('Mesaje') 

	/** Tiparim si un formular */

	-- de aici...
end try
begin catch

	set @mesaj=ERROR_MESSAGE()+ ' (wOPStornareBonSP)'
	RAISERROR(@mesaj, 11, 1)
end catch
