--***
create procedure wOPInlocuireCotaTVA (@sesiune varchar(50), @parXML xml/*, @idRulare int = 0*/) 
as     
-- apelare procedura specifica daca aceasta exista.
/*
	declare @p2 xml
	set @p2=convert(xml,N'<parametri data="2016-01-01" />')
	exec wOPInlocuireCotaTVA @sesiune='AB3AFE74AE2F0',@parXML=@p2
	Obs. Ghita: sa se tina cont de optiunea privind pretul doar la tabela preturi si pentru stocuri sa citim pretul cu wIaPreturi din preturi.
*/
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPInlocuireCotaTVASP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPInlocuireCotaTVASP @sesiune, @parXML output
	return @returnValue
end
/*
IF @idRulare = 0	--	procedura e apelata din frame
begin
	exec wOperatieLunga @sesiune = @sesiune, @parXML = @parXML, @procedura = 'wOPInlocuireCotaTVA'
	return
end
*/
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInlocuireCotaTVA'

declare @utilizator varchar(20), @sub varchar(9), @data datetime, @dataJosPreturi datetime, 
	@cotaveche float, @cotaNoua float, @inlocuireCotaTVaNomencl int, @recalcPretAmTabPreturi int, @recalcPretAmTabStocuri int, 
	@optiunePretAm char(1),	
	/*	R = Recalculare pret amanunt conform noii cote, P = Pastrare pret amanunt actual si modificare adaos conform noii cote, 
		C = Functie de categoria de pret, adica recalculare pret amanunt la categoriile de pret vanzare si pastrare pret amanunt la categoriile de pret amanunt
	*/
	@TabelaPreturi int, @input XML, @suma_rotunjire decimal(12,5), @parview int, @comandaSql nvarchar(max)
begin try
	set transaction isolation level read uncommitted
	set @utilizator=dbo.fIaUtilizator(@sesiune)

	select 
		@data=isnull(@parXML.value('(/*/@data)[1]','datetime'), '2999-01-01'),
		@dataJosPreturi=isnull(@parXML.value('(/*/@datajospret)[1]','datetime'), '2999-01-01'),
		@cotaveche=@parXML.value('(/*/@cotaveche)[1]','float'),
		@cotaNoua=@parXML.value('(/*/@cotanoua)[1]','float'),
		@inlocuireCotaTVaNomencl=isnull(@parXML.value('(/*/@cotanomencl)[1]','int'),0),
		@recalcPretAmTabPreturi=isnull(@parXML.value('(/*/@pretamtabpreturi)[1]','int'),0),
		@recalcPretAmTabStocuri=isnull(@parXML.value('(/*/@pretamtabstocuri)[1]','int'),0),
		@optiunePretAm=isnull(@parXML.value('(/*/@optpretam)[1]','char(1)'),'R'),
		@suma_rotunjire=isnull(@parXML.value('(/*/@sumarotunjire)[1]','decimal(10,5)'),0.05)

	select	@sub=max(case when Parametru='SUBPRO' then val_alfanumerica else '' end),
			@TabelaPreturi=max(case when Parametru='PRETURI' then val_logica else 0 end)
	from par where Tip_parametru='GE' and Parametru in ('PRETURI','SUBPRO')

	if not exists (select * from sysobjects where name ='wScriuDoc') 
		and not exists (select * from sysobjects where name ='wScriuDocBeta')
		raiserror('Eroare configurare: aceasta procedura necesita folosirea procedurii wScriuDoc(Beta).', 16, 1)

	begin transaction inlocuire_cota_tva

		/*	Inlocuire cota TVA in parametrii (par/parlm).	*/
		set @parview=(case when exists (select * from sysobjects where name ='par' and xtype='V') then 1 else 0 end)
		SET @comandaSql = N'
			update '+(case when @parview=1 then 'parlm' else 'par' end)+
			' set val_numerica=@cotaNoua where tip_parametru=''GE'' and parametru=''COTATVA'''
		exec sp_executesql @statement=@comandaSql, @params=N'@cotaNoua float', @cotaNoua=@cotaNoua

		/*	Inlocuire cota TVA in nomenclator. */
		--UPDATE p SET statusText = 'Inlocuire cota TVA in nomenclator!' FROM asisria.dbo.ProceduriDeRulat p WHERE p.idRulare = @idRulare
		update n
		set Cota_TVA=(case when @inlocuireCotaTVaNomencl=1 then @cotaNoua else n.Cota_TVA end), 
			Pret_cu_amanuntul=(case when @recalcPretAmTabPreturi=1 and @TabelaPreturi=0 then convert(decimal(18, 5), n.Pret_vanzare*(1.00+@cotaNoua/100.00)) else n.Pret_cu_amanuntul end)
		from nomencl n
		where n.Cota_TVA=@cotaveche 

		if @recalcPretAmTabPreturi=1
		begin
			/* Recalculare preturi cu amanuntul in tabela de preturi incepand cu data de .... */
			declare @PastrezPretAmanuntActual int, @CategorieFiltru int

			/*	@PastrezPretAmanuntActual: daca e 0 atunci se recalculeaza pretul cu amanuntul conform noii cote, plecand de la pretul de vanzare;
				daca e 1 atunci se pastreaza pretul cu amanuntul actual si se recalculeaza pretul de vanzare*/
			select	@PastrezPretAmanuntActual=(case when @optiunePretAm='P' then 1 when @optiunePretAm='R' then 0 end), 
					@CategorieFiltru=null

			if object_id('tempdb..#preturirecalc') is not null
				drop table #preturirecalc

			--UPDATE p SET statusText = 'Recalculare preturi cu amanuntul in '+(case when @tabelaPreturi=0 then 'nomenclator' else 'tabela de preturi' end)+'!' 
			--FROM asisria.dbo.ProceduriDeRulat p WHERE p.idRulare = @idRulare

			select p.cod_produs, p.UM, p.umprodus, p.tip_pret, @dataJosPreturi as data_inferioara, p.ora_inferioara, p.data_superioara, p.ora_superioara, 
			(case when @optiunePretAm='R' or @optiunePretAm='C' and isnull(c.tip_categorie, 0)=1 then p.pret_vanzare else convert(decimal(18, 5), p.pret_cu_amanuntul/(1.00+@cotaNoua/100.00)) end) as pret_vanzare, 
			(case when @optiunePretAm='R' or @optiunePretAm='C' and isnull(c.tip_categorie, 0)=1
				then dbo.rot_pret (round(convert(decimal(18, 5), p.pret_vanzare*(1.00+@cotaNoua/100.00)),2),@suma_rotunjire) else p.pret_cu_amanuntul end) as pret_cu_amanuntul, 
			@utilizator as utilizator, convert(datetime, convert(char(10), getdate(), 101), 101) as data_operarii, 
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')) as ora_operarii
			into #preturirecalc
			from preturi p
			inner join nomencl n on n.cod=p.cod_produs
			left outer join categpret c on c.categorie=p.UM
			where n.cota_TVA=@cotaNoua and isnull(c.tip_categorie, 0)<>3 and (@CategorieFiltru is null or p.UM=@CategorieFiltru)
			and p.data_inferioara<@dataJosPreturi and p.data_superioara>=@dataJosPreturi 
			--daca nu se doreste tratarea preturilor promotionale (speciale, perioada, etc.) se va decomenta linia de mai jos
			/*and p.data_superioara='01/01/2999'*/

			alter table preturi disable trigger all
			update p
			set data_superioara=dateadd(d, -1, @dataJosPreturi)
			from preturi p
			inner join nomencl n on n.cod=p.cod_produs
			left outer join categpret c on c.categorie=p.UM
			where n.cota_TVA=@cotaNoua and isnull(c.tip_categorie, 0)<>3 and (@CategorieFiltru is null or p.UM=@CategorieFiltru)
			and p.data_inferioara<@dataJosPreturi and p.data_superioara>=@dataJosPreturi 
			--daca nu se doreste tratarea preturilor promotionale (speciale, perioada, etc.) se va decomenta linia de mai jos
			/*and p.data_superioara='01/01/2999'*/

			insert preturi
			(Cod_produs, UM, umprodus, Tip_pret, Data_inferioara, Ora_inferioara, Data_superioara, Ora_superioara, Pret_vanzare, Pret_cu_amanuntul, Utilizator, Data_operarii, Ora_operarii)
			select Cod_produs, UM, umprodus, Tip_pret, Data_inferioara, Ora_inferioara, Data_superioara, Ora_superioara, Pret_vanzare, Pret_cu_amanuntul, Utilizator, Data_operarii, Ora_operarii
			from #preturirecalc

			alter table preturi enable trigger all
			drop table #preturirecalc
		end

		--UPDATE p SET statusText = 'Recalculare TVA neexigibil si preturi cu amanuntul in stocuri pe gestiuni tip A!' FROM asisria.dbo.ProceduriDeRulat p WHERE p.idRulare = @idRulare
		if @recalcPretAmTabStocuri=1
		begin
			declare @DataSusStocuri datetime
			select @DataSusStocuri=dateadd(d, -1, @dataJosPreturi)

			declare @GestiuneFiltru char(9), @DataDocumente datetime
			/*	@PastrezPretAmanuntActual: daca e 0 atunci se recalculeaza pretul cu amanuntul conform noii cote, plecand de la pretul fara tva (124 devine 120); 
				in acest caz valoarea adaosului pe stoc (378) ramane neschimbata;
				daca e 1 atunci se pastreaza preturile actuale, diminuandu-se adaosul pe stoc (378) cu aceeasi valoare cu care creste TVA-ul neexigibil pe stoc (4428)*/
			select @GestiuneFiltru=null, @DataDocumente=@DataSusStocuri

			declare @p xml
			select @p=(select @DataSusStocuri dDataSus, @GestiuneFiltru cGestiune, 1 GrCod, 1 GrGest, 1 GrCodi, 'D' TipStoc	for xml raw)
			/*
			if object_id('tempdb..#docstoc') is not null drop table #docstoc
				create table #docstoc(subunitate varchar(9))
				exec pStocuri_tabela
	 
			exec pstoc @sesiune='', @parxml=@p
			*/
			declare @crsInlCotaTVA cursor, @cGestiune varchar(13), @ft int

			set @crsInlCotaTVA = cursor local fast_forward for
			select distinct s.cod_gestiune
			from stocuri s --#docstoc s
			where s.subunitate=@sub and s.tip_gestiune='A' and s.tva_neexigibil=@cotaveche and abs(s.stoc)>=0.001 

			open @crsInlCotaTVA
			fetch next from @crsInlCotaTVA into @cGestiune
			set @ft=@@FETCH_STATUS
			while @ft=0
			begin
				if object_id('tempdb..#tmpstoc') is not null 
					drop table #tmpstoc

				select	s.subunitate, s.cod_gestiune as gestiune, s.cod, s.cod_intrare, s.pret, s.stoc, s.cont, s.tva_neexigibil, s.pret_cu_amanuntul, 
						s.locatie, s.loc_de_munca, s.comanda, s.contract, s.furnizor, s.lot, s.stoc_UM2, 
						convert(decimal(18, 5), 0) as PretAmNou					
						/*(case when @PastrezPretAmanuntActual=1 then s.pret_cu_amanuntul 
							else convert(decimal(18, 5), s.pret_cu_amanuntul / (1.00+s.tva_neexigibil/100.00) * (1.00+@cotanoua/100.00)) end) as PretAmNou*/
				into #tmpstoc
				from stocuri s --#docstoc s
				where s.subunitate=@sub and s.tip_gestiune='A' and s.cod_gestiune=@cGestiune and s.tva_neexigibil=@cotaveche and abs(s.stoc)>=0.001 
				order by 1, 2, 3

				if object_id('tempdb..#preturi') is not null 
					drop table #preturi
				create table #preturi(cod varchar(20),nestlevel int)
		
				insert into #preturi
				select cod,@@NESTLEVEL
				from #tmpstoc
				group by cod
			
				exec CreazaDiezPreturi

				declare @parXMLPreturi xml
				select @parXMLPreturi=(select @cGestiune as gestiune, convert(varchar(10),@dataJosPreturi,101) as data for xml raw)

				exec wIaPreturi @sesiune=@sesiune, @parXML=@parXMLPreturi

				update s set s.PretAmNou=p.pret_amanunt
				from #tmpstoc s
					inner join #preturi p on s.cod=p.cod

				set @input=(select 'TE' as '@tip', convert(varchar(10),@DataDocumente,101) as '@data', 
					rtrim(a.gestiune) as '@gestiune', rtrim(a.gestiune) as '@gestprim', 
						(select rtrim(s.cod) as '@cod',
						convert(decimal(12,3),s.stoc) as '@cantitate',
						convert(decimal(12,5),s.pret) as '@pstoc',
						convert(decimal(12,2),s.PretAmNou) as '@pamanunt',
						convert(decimal(12,2),s.tva_neexigibil) as '@cotatva',
						rtrim(s.cont) as '@contstoc',
						rtrim(s.Cod_intrare) as '@codintrare',
						(select convert(decimal(12,2),@cotaveche) as 'tvaneexies' for xml raw,type) as detalii
						from #tmpstoc s where s.gestiune=a.gestiune for XML path,type)
					from #tmpstoc a 
					group by a.gestiune
					for xml Path,type, root('Date'))

				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'doccontr') AND type='TR')
					alter table pozdoc disable trigger doccontr
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'docctatr') AND type='TR')
					alter table pozdoc disable trigger docctatr
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'docdec') AND type='TR')
					alter table pozdoc disable trigger docdec
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'docfac') AND type='TR')
					alter table pozdoc disable trigger docfac
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'docfacav') AND type='TR')
					alter table pozdoc disable trigger docfacav
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'pozdocsterg') AND type='TR')
					alter table pozdoc disable trigger pozdocsterg
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'realizsterg') AND type='TR')
					alter table pozdoc disable trigger realizsterg
				if exists (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'tr_ValidPozdoc') AND type='TR')
					alter table pozdoc disable trigger tr_ValidPozdoc
			--select @input
				if exists (select * from sysobjects where name ='wScriuDoc')
					exec wScriuDoc @sesiune=@sesiune, @parXML=@input
				else 
					if exists (select * from sysobjects where name ='wScriuDocBeta')
						exec wScriuDocBeta @sesiune=@sesiune, @parXML=@input
				if object_id('tempdb..#docstoc') is not null drop table #docstoc

				alter table pozdoc enable trigger all

				fetch next from @crsInlCotaTVA into @cGestiune
				set @ft=@@FETCH_STATUS
			end
		end
	
		--UPDATE p SET statusText = 'Operatie finalizata' FROM asisria.dbo.ProceduriDeRulat p WHERE p.idRulare = @idRulare
	commit transaction inlocuire_cota_tva

end try
begin catch
	if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'inlocuire_cota_tva')
		ROLLBACK TRAN inlocuire_cota_tva
	alter table pozdoc enable trigger all
	alter table preturi enable trigger all

	declare @mesaj varchar(4000)
	set @mesaj = ERROR_MESSAGE()+' (wOPInlocuireCotaTVA)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)