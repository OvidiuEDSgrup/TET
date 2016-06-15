
CREATE PROCEDURE wScriuPozContracte @sesiune VARCHAR(50), @parXML XML OUTPUT
AS
BEGIN TRY
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuPozContracteSP')
		exec wScriuPozContracteSP @sesiune=@sesiune, @parXML=@parXML OUTPUT
	
	SET NOCOUNT ON
	DECLARE 
		@idContract INT, @tert VARCHAR(20), @update BIT, @utilizator VARCHAR(100),  @tipContract VARCHAR(2), @numar varchar(20),
		@gestiuneProprietate VARCHAR(20), @clientProprietate VARCHAR(20), @lmProprietate VARCHAR(20), @gestiuneDepozitBK VARCHAR(20),
		@docJurnal XML, @docRefresh XML, @docPlaje XML, @documente int, @fara_luare_date bit, @mesaj varchar(max), @subunitate varchar(9), 
		@lm varchar(20), @serieprimita varchar(9), @idPlajaPrimit int, @serieInNumar bit, @punct_livrare varchar(20)

	/** Informatii identificare antet **/
	SET @tipContract = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(20)')
	
	/** Alte **/
	SET @fara_luare_date= isnull(@parXML.value('(/*/@fara_luare_date)[1]', 'bit'),0)
	SET @update = isnull(@parXML.value('(/*/*/@update)[1]', 'bit'), 0)

	if OBJECT_ID('tempdb..#setContracte') is not null
		drop table #setContracte
	
	/** Luare date din XML: fie 1 rand fie multiple documente **/
	select 
		DENSE_RANK() OVER 
		( 			
			ORDER by 
				A.doc.value('(../@tert)[1]', 'varchar(20)'), 
				A.doc.value('(../@data)[1]', 'varchar(20)')
		) nr_doc,
		A.doc.value('(../@tip)[1]', 'varchar(2)') tipContract, 
		A.doc.value('(../@idContract)[1]', 'int') idContract, 
		A.doc.value('(../@idContractCorespondent)[1]', 'int') idContractCorespondent, 
		A.doc.value('(../@numar)[1]', 'varchar(20)') numar, 
		isnull(A.doc.value('(../@stare)[1]', 'int'),0) stare, 
		A.doc.value('(../@tert)[1]', 'varchar(20)') tert, 
		A.doc.value('(../@gestiune)[1]', 'varchar(20)') gestiune, 
		A.doc.value('(../@gestiune_primitoare)[1]', 'varchar(20)') gestiune_primitoare, 
		A.doc.value('(../@punct_livrare)[1]', 'varchar(20)') punct_livrare, 
		A.doc.value('(../@explicatii)[1]', 'varchar(8000)') explicatiiAntet, 

		A.doc.value('(../@curs)[1]', 'float') curs, 
		A.doc.value('(../@lm)[1]', 'varchar(20)') lm, 
		A.doc.value('(../@valuta)[1]', 'varchar(20)') valuta, 
		A.doc.value('(../@valabilitate)[1]', 'datetime') valabilitate, 
		convert(datetime,convert(char(10),A.doc.value('(../@data)[1]', 'datetime'),101)) data,
		A.doc.query('(../detalii/row)[1]') detaliiAntet,
		--Pozitii
		A.doc.value('(@idPozContract)[1]', 'int') idPozContract, 
		A.doc.value('(@cod)[1]', 'varchar(20)') cod, 
		A.doc.value('(@codspecific)[1]', 'varchar(20)') codspecific, 
		A.doc.value('(@pret)[1]', 'float') pret, 
		A.doc.value('(@cantitate)[1]', 'float') cantitate, 
		A.doc.value('(@discount)[1]', 'float') discount, 
		A.doc.value('(@grupa)[1]', 'varchar(20)') grupa, 
		A.doc.value('(@termen)[1]', 'datetime') termen, 
		isnull(A.doc.value('(@periodicitate)[1]', 'int'),0) periodicitate, 
		A.doc.value('(@explicatii)[1]', 'varchar(500)') explicatiiPozitie, 
		A.doc.value('(@subtip)[1]', 'varchar(20)') subtip,
		A.doc.value('(@idPozLansare)[1]', 'int') idPozLansare,
		A.doc.value('(@idPozContractCoresp)[1]', 'int') idPozContractCoresp,
		isnull(A.doc.value('(@update)[1]', 'bit'),0) pupdate,
		A.doc.query('(detalii/row)[1]') detaliiPozitii
	into #setContracte
	FROM @parXML.nodes('row/row') A(doc)

	/**Numarul de documente din sesiunea curenta **/
	select 
		@documente=max(nr_doc)
	from #setContracte
	
	/** In detalii se scrie intotdeauna XML sau NULL  */
	UPDATE #setContracte 
		set detaliiPozitii=null
	where convert(varchar(max),detaliiPozitii)=''

	UPDATE #setContracte 
		set detaliiantet=null
	where convert(varchar(max),detaliiantet)=''

	update #setContracte
		set idContractCorespondent=null
	where isnull(idContractCorespondent,0)=0

	/*** Utilizator  si parametri*/
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate OUTPUT
	
	IF EXISTS 
		(	SELECT 1 
			FROM StariContracte st
			JOIN #setContracte sc on sc.tipContract=st.tipContract and st.stare=sc.stare AND st.modificabil<>1	)
		RAISERROR ('Documentul este intr-o stare care nu permite modificarea!', 11, 1)
	
	update #setContracte set 
		tert = (case when tert='' then null else tert end),
		punct_livrare = (case when punct_livrare='' then null else punct_livrare end),
		gestiune = (case when gestiune='' then null else gestiune end),
		gestiune_primitoare = (case when gestiune_primitoare='' then null else gestiune_primitoare end),
		lm = (case when lm='' then null else lm end),
		valuta = (case when valuta='' then null else valuta end)

	/** Introducere [antete] si/sau pozitii **/
	IF @update = 0
	BEGIN
		IF EXISTS (select 1 from #setContracte where idContract is null)
		BEGIN
			/** Valori din proprietati **/
			SELECT	
				@gestiuneProprietate = (CASE WHEN cod_proprietate = 'GESTBK' THEN valoare ELSE @gestiuneProprietate END), 
				@clientProprietate = (CASE WHEN cod_proprietate = 'CLIENT' THEN valoare ELSE @clientProprietate END), 
				@lmProprietate = (CASE WHEN cod_proprietate = 'LOCMUNCA' THEN valoare ELSE @lmProprietate END), 
				@gestiuneDepozitBK = (CASE WHEN cod_proprietate = 'GESTDEPBK' THEN valoare ELSE @gestiuneDepozitBK END)
			FROM proprietati
			WHERE tip = 'UTILIZATOR' AND cod = @utilizator AND cod_proprietate IN ('GESTBK', 'CLIENT', 'LOCMUNCA', 'GESTDEPBK') AND valoare <> ''
			
			update #setContracte
				set tert=@clientProprietate
			where ISNULL(tert,'')='' and tipContract in ('CL','CB','CS') and idContract is null
			
			update sc
				SET sc.punct_livrare=RTRIM(it.identificator)
			from #setContracte sc
			LEFT JOIN infotert it ON it.Tert=sc.tert and it.Subunitate=@subunitate and it.Identificator<>''
			where idContract is null and punct_livrare is null

			update #setContracte
				set gestiune=@gestiuneDepozitBK
			where isnull(gestiune,'')='' and @gestiuneDepozitBK<> '' and idContract is null

			/**Determinare gestiune **/
			update #setContracte
				set gestiune=@gestiuneProprietate
			where gestiune=''  and (tipContract not in ('CB','CL','CS') or gestiune_primitoare ='' OR gestiune_primitoare<> @gestiuneProprietate ) 		
				and idContract is null

			/** Determinare loc de munca fie proprietate fie din gestiune**/
			update #setContracte
				SET #setContracte.lm=@lmProprietate
			where ISNULL(#setContracte.lm,'')='' and @lmProprietate is not null and idContract is null

			update sc
				SET sc.lm=gc.lm
			from #setContracte sc
			CROSS APPLY
				(
					select 
						gc.loc_de_munca lm
					from gestcor gc where gc.Gestiune=sc.gestiune and gc.Loc_de_munca<>''
				) gc
			where ISNULL(sc.lm,'')='' and @lmProprietate is not null and sc.idContract is null
	
			
			if exists (select 1 from #setContracte where ISNULL(numar,'')='')
			begin
			/** Luare numere din plaja pt toate documentele daca este vorba de mai mult de 1 document**/
				select top 1 @lm=lm from #setContracte
				SET @docPlaje =
					(
						SELECT
							@tipContract tip, @utilizator utilizator, @documente documente, @lm lm
						for XML RAW
					)
				EXEC wIauNrDocFiscale @parXML = @docPlaje, @numar = @numar OUTPUT, @serie=@serieprimita OUTPUT, @idPlaja=@idPlajaPrimit output
				/**  Update la numarul de documente, fiecare in parte */

				select @serieInNumar = ISNULL(serieInNumar,0) from docfiscale where id=@idPlajaPrimit

				update #setContracte
					set numar=(case @serieInNumar when 1 then @serieprimita else '' end) + ltrim(str(nr_doc+convert(int,@numar)))
				where idContract is null and ISNULL(numar,'')=''
			end
			
			if OBJECT_ID('tempdb..#c_inserate') is not null
				drop TABLE #c_inserate
			create table #c_inserate(idContract int,tip varchar(2), tert varchar(20), numar varchar(20),data datetime)			

			/** Scriere antete contract in Contracte pe tipul corespunzator**/
			INSERT INTO Contracte (tip, numar, data, tert, punct_livrare, gestiune, gestiune_primitoare, loc_de_munca, valuta, curs, valabilitate, 
				explicatii, idContractCorespondent, detalii)
			OUTPUT inserted.idContract,inserted.tip,inserted.tert,inserted.numar,INSERTED.data
			into #c_inserate(idContract,tip,tert,numar,data) 
			select distinct
				tipContract,RTRIM(numar),data,RTRIM(tert), RTRIM(punct_livrare),RTRIM(gestiune),rtrim(gestiune_primitoare), RTRIM(lm),RTRIM(valuta),
				curs,valabilitate, explicatiiAntet,idContractCorespondent, NULL
			from #setContracte where idContract is null

			/** Se asociaza datele din tabelul temp (fara IDContract) cu idContract din antetele ce tocmai s-au scris **/
			update sc
				set sc.idContract=ci.idContract
			from #setContracte sc
			JOIN #c_inserate ci on sc.tipContract=ci.tip and (sc.tert=ci.tert OR sc.tert is null) 	and sc.numar=ci.numar and sc.data=ci.data 

			/** La fel si DETALII XML-> nu se poate selecta distinct daca ai o coloana XML, vezi selectul de mai sus unde se insereaza antetele **/
			update c
				set c.detalii=sc.detaliiAntet
			from Contracte c
			JOIN #setContracte sc on c.idContract=sc.idContract
			
			/** Pt. cazul in care se lucreaza din macheta si este vorba doar de 1 contract, e nevoie de ID la refresh **/
			select top 1 
				@idContract=idContract
			from #c_inserate
			/** Se consemneaza operarea contractului in JurnalContracte **/
			SET @docJurnal = 
				(
					SELECT distinct 
						idContract idContract, 'Introdus contract/comanda' AS explicatii, GETDATE() AS data, stare AS stare 
					FROM #setContracte
					FOR XML raw,root('Date')
				)
			EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
		END
		ELSE 
		/* Exista antet(e)*/
		begin 
			/* Fac update si la antet - daca se sterg toate pozitiile se poate edita antetul. */
			update c
			set c.numar=sc.numar, c.data=sc.data, c.tert=sc.tert, c.punct_livrare=sc.punct_livrare, c.gestiune=sc.gestiune, 
				c.gestiune_primitoare=sc.gestiune_primitoare, c.loc_de_munca=sc.lm, c.valuta=sc.valuta, c.curs=sc.curs, 
				c.valabilitate=sc.valabilitate, c.explicatii=sc.explicatiiAntet, c.idContractCorespondent=sc.idContractCorespondent, 
				c.detalii=sc.detaliiAntet
			from contracte c
			JOIN #setContracte  sc on  sc.idContract=c.idContract
			

			set @docJurnal =(select top 1 idContract, idJurnal from JurnalContracte where idContract= @idContract order by data desc for XML raw)
		end

		/** Pentru comenzi de livrare-> se va lua PRETUL si DISCOUNTUL folosind procedura wIaPreturi daca acestea nu sunt completate */
		if exists (select 1 from #setContracte where tipContract NOT IN ('CF','CA'))
		BEGIN
			if EXISTS (select 1 from #setContracte where isnull(pret,0)=0)
			BEGIN
				create table #preturi(cod varchar(20), umprodus varchar(3), nestlevel int)
				exec CreazaDiezPreturi
				declare @pXML xml

				--Parcurg fiecare comlanda intr-un cursor
				declare @data datetime,@valuta varchar(20)
				select distinct tert, punct_livrare, data, valuta
				into #setContractePeTerti
				from #setContracte
				group by tert,punct_livrare, data, valuta

				while exists(select 1 from #setContractePeTerti)
				begin
					select top 1 @tert=tert,@data=data,@valuta=valuta, @punct_livrare=punct_livrare
					from #setContractePeTerti

					truncate table #preturi
					insert into #preturi(cod, umprodus, nestlevel)
					select cod, max(detaliiPozitii.value('(/row/@um_um)[1]','varchar(3)')), @@nestlevel
					from #setContracte 
					where isnull(tert,'')=isnull(@tert,'') and isnull(data,'01/01/1901')=isnull(@data,'01/01/1901') and isnull(valuta,'')=isnull(@valuta,'')
					group by cod

									
					set @pXML=(select @tert as tert,@data as data,@valuta as valuta, @punct_livrare punctlivrare for xml raw)
					exec wIaPreturi @sesiune,@pXML

					update s set 
						s.pret=(case when ISNULL(s.pret,0)=0 then p.pret_vanzare else s.pret end),
						s.discount=(case when ISNULL(s.discount,0)=0 then p.discount else s.discount end)
					from #setContracte s,#preturi p where s.cod=p.cod

					delete from #setContractePeTerti
					where isnull(tert,'')=isnull(@tert,'') and isnull(data,'01/01/1901')=isnull(@data,'01/01/1901') and isnull(valuta,'')=isnull(@valuta,'')
					
				end
			END
		END

		/** Stabilire pret pentru comenzi de aprovizionare **/
		if exists (select 1 from #setContracte where tipContract='CA')
		BEGIN
			--incercam sa luam pretul pe furnizor din ppreturi
			update sc
				set sc.pret=ppret.pret
			from #setContracte sc
				outer apply (select top 1 pret from ppreturi pp where pp.tert=sc.tert and pp.cod_resursa=sc.cod and pp.data_pretului<=sc.data order by data_pretului desc) ppret
			where sc.tipContract='CA' and isnull(sc.pret,0)=0
			
			--daca nu gasim in ppreturi, luam pret stoc din nomenclator
			update sc
				set sc.pret=n.Pret_stoc
			from #setContracte sc
				JOIN nomencl n on sc.cod=n.cod
			where sc.tipContract='CA' and isnull(sc.pret,0)=0
		END
		
		if OBJECT_ID('tempdb..#pc_inserate') is not null
			drop TABLE #pc_inserate

		create table #pc_inserate(idContract int,idPozContract int, detalii xml)
			
		/** Daca exista campul idPozContractCorespondent, pregatesc scrierea lui in detalii XML si facem un shmen
			Unde nu exista campul detalii cream cu idPozContractCorespondent, iar unde exista doar inseram idPozContractCorespondent prin updateurile de mai jos

		 **/
		 -- ca sa evitam duplicate
		update #setContracte set detaliiPozitii.modify('delete (/row/@idPozContractCoresp)[1]') where detaliiPozitii IS NOT NULL

		update sc
			set detaliiPozitii.modify('insert attribute idPozContractCoresp {sql:column("sc.idPozContractCoresp")} into (/row)[1]')
		from #setContracte sc where sc.detaliiPozitii is not null and sc.idPozContractCoresp is not null

		update sc
			set sc.detaliiPozitii= (select sc.idPozContractCoresp idPozContractCoresp for xml raw)
		from #setContracte sc where sc.detaliiPozitii is null and sc.idPozContractCoresp is not null		

		/** Se scriu pozitiile **/
		INSERT INTO PozContracte (idContract, cod, grupa, cantitate, pret, discount, termen, periodicitate, explicatii, detalii, cod_specific, 
		subtip,idPozLansare)
		OUTPUT INSERTED.idContract, INSERTED.idPozContract, INSERTED.detalii into #pc_inserate(idContract,idPozContract,detalii)
		SELECT
			idContract, cod, grupa, cantitate, pret, discount, termen, periodicitate, explicatiiPozitie, detaliiPozitii, codspecific, subtip, idPozLansare
		from #setContracte
		where (cod is not null OR grupa is not null)

		/**
			Daca a fost cazul de idPozContractCorespondent scriem in legaturi pe baza outputului din inserted (mai sus)
		**/
		insert INTO LegaturiContracte(idJurnal, idPozContract,idPozContractCorespondent)
		select
			J.c.value('@idJurnal','int'), p.idPozContract,p.detalii.value('(/*/@idPozContractCoresp)[1]','int')
		FROM @docJurnal.nodes('/row') J(c)
		JOIN #pc_inserate p ON J.c.value('@idContract','int')=p.idContract 
		where NULLIF(p.detalii.value('(/*/@idPozContractCoresp)[1]','int'),0) IS NOT NULL

	END
	ELSE 
	/** Modificare date pozitii **/
	BEGIN
		UPDATE pc
			set  pc.cantitate = sc.cantitate, pc.termen = sc.termen, pc.discount = sc.discount, pc.pret = sc.pret, pc.periodicitate = sc.periodicitate, 
			pc.explicatii = sc.explicatiiPozitie, pc.detalii = sc.detaliiPozitii, pc.cod_specific = sc.codspecific, pc.cod=sc.cod
		from PozContracte pc
		JOIN #setContracte sc on sc.idPozContract=pc.idPozContract and sc.pupdate=1
	END

	if @parXML.value('(/*/@idContract)[1]','int') is NULL
		set @parXML.modify('insert attribute idContract {sql:variable("@idContract")} into (/*)[1]')
	else
		set @parXML.modify('replace value of (/*/@idContract)[1] with sql:variable("@idContract")')
	
	/** Fara luare date-> poate fi apeluat cu parametrul valoare 1 pt. a nu apela procedura de luare date **/
	if @fara_luare_date=0
	begin
		SET @docRefresh = 
			(
				SELECT 
					@idContract idContract, @tipContract tip, @tert tert 
				FOR XML raw
			)
		EXEC wIaPozContracte @sesiune = @sesiune, @parXML = @docRefresh
	end
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuPozContracte)'
	RAISERROR (@mesaj, 11, 1)
END CATCH
