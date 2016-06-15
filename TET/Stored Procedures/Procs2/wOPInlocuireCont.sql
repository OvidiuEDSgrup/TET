
Create PROCEDURE wOPInlocuireCont @sesiune VARCHAR(50), @parXML XML
AS
begin try
/*	
	Operatia poate fi apelata
		1. Dintr-o macheta sau alta operatie pentru un singur cont caz in care se interpreteaza din XML <row cont_vechi="" cont_nou="" />
		2. Folosind #tmpInlocuireConturi (cont_vechi, cont_nou) pentru a trimite set de date



	Exemplu apel
	1:
		exec wOPInlocuireCont '','<row cont_vechi="371.0" cont_nou="371.1"/>'

	2:  Dam exemplu tot pentru un singur cont, dar tabelul #tmpInlocuireConturi poate retine oricate perechi de conturi
		IF OBJECT_ID('tempdb..#tmpInlocuireConturi') IS NOT NULL
			drop table #tmpInlocuireConturi

		select '371.1' cont_nou, '371.0' cont_vechi into #tmpInlocuireConturi

		exec wOPInlocuireCont '','<row fara_mesaje="1" />'
	 
*/

	declare	
		@cont_vechi varchar(20), @cont_nou varchar(20), @fara_mesaje bit

	select
		@cont_vechi=@parXML.value('(/*/@cont_vechi)[1]','varchar(20)'),
		@cont_nou=@parXML.value('(/*/@cont_nou)[1]','varchar(20)'),
		@fara_mesaje=ISNULL(@parXML.value('(/*/@fara_mesaje)[1]','bit'),0)

	IF @cont_vechi IS NOT NULL and @cont_nou IS NOT NULL
	begin
		/*Un singur CONT*/
		IF OBJECT_ID('tempdb..#tmpInlocuireConturi') IS NULL
			create table #tmpInlocuireConturi (cont_vechi varchar(20), cont_nou varchar(20))

		truncate table #tmpInlocuireConturi
		insert into #tmpInlocuireConturi(cont_vechi, cont_nou)
		select @cont_vechi, @cont_nou
	end

	if exists (select * from #tmpInlocuireConturi tt
					where not exists (select * from conturi t where t.cont=tt.cont_nou))
		raiserror ('Contul destinatar nu exista in catalog. ',16,1)

	/* Pentru SQL Dynamic vom lucra cu un tabel temp. ## populat din cel de mai sus */
	IF OBJECT_ID('tempdb..##tmp_coresp') IS NOT NULL
		drop table ##tmp_coresp

	create table ##tmp_coresp (cont_vechi varchar(20), cont_nou varchar(20))
	insert into ##tmp_coresp(cont_vechi, cont_nou)

	select cont_vechi, cont_nou from #tmpInlocuireConturi

	if OBJECT_ID('tempdb..##trigg_prel') IS NOT NULL
			drop table ##trigg_prel	
		create table ##trigg_prel (id int identity primary key,comandaSQLDisable nvarchar(4000), comandaSQLEnable nvarchar(4000))

	/* Aici vom trata majoritatea cazurilor, cele mai speciale (care depind de anumite conditii) le parcurgem separat mai jos */
	if OBJECT_ID('tempdb..##date_prel') IS NOT NULL
		drop table ##date_prel	
	create table ##date_prel (id int identity primary key, tabel varchar(100), coloana varchar(100), comandaSQL nvarchar(4000))

	insert into ##date_prel (tabel, coloana)
	select 'gestiuni', 'cont_contabil_specific' union
	select 'par', 'val_alfanumerica' union
	select 'nomencl', 'cont' union
	select 'stocuri', 'cont' union
	select 'istoricstocuri', 'cont' union
	select 'terti', 'cont_ca_beneficiar' union
	select 'terti', 'cont_ca_furnizor' union
	select 'facturi', 'cont_de_tert' union
	select 'factimpl', 'cont_de_tert' union
	select 'deconturi', 'cont' union
	select 'decimpl', 'cont' union
	select 'efecte', 'cont' union
	select 'efimpl', 'cont' union
	select 'doc', 'cont_factura' union
	select 'pozdoc', 'cont_de_stoc' union
	select 'pozdoc', 'cont_venituri' union
	select 'pozdoc', 'cont_corespondent' union
	select 'pozdoc', 'cont_intermediar' union
	select 'pozdoc', 'cont_factura' union
	select 'pozadoc', 'cont_deb' union
	select 'pozadoc', 'cont_cred' union
	select 'pozadoc', 'cont_dif' union
	/*select 'plin', 'cont' union*/ --> se trateaza mai jos la sectiunea "speciala"
	select 'pozplin', 'cont' union
	select 'pozplin', 'cont_corespondent' union
	select 'pozplin', 'cont_dif' union
	select 'incfact', 'cont' union
	select 'pozncon', 'cont_debitor' union
	select 'pozncon', 'cont_creditor' union
	/*select 'pozincon', 'cont_debitor' union  --> se trateaza mai jos la sectiunea "speciala"
	select 'pozincon', 'cont_creditor' union*/ --> se trateaza mai jos la sectiunea "speciala"
	select 'mismf', 'cont_corespondent' union
	select 'fisamf', 'cont_mijloc_fix' union
	select 'fisamf', 'cont_amortizare' union
	select 'fisamf', 'cont_cheltuieli' union
	select 'benret', 'cont_debitor' union
	select 'benret', 'cont_creditor' union
	select 'dvi', 'Cont_CIF' union
	select 'dvi', 'Cont_vama' union
	select 'dvi', 'Cont_suprataxe' union
	select 'dvi', 'Cont_comis' union
	select 'dvi', 'Cont_tert_vama' union
	select 'dvi', 'Cont_factura_TVA' union
	select 'dvi', 'Cont_vama_suprataxe' union
	select 'dvi', 'Cont_com_vam' union 
	select 'incfact', 'cont' union 
	select 'cost', 'Cont_cheltuieli_sursa' union 
	select 'chind', 'cont_ch_sursa' union 
	select 'config_nc', 'cont_debitor' union 
	select 'config_nc', 'cont_creditor' union
	select 'incasarifactabon','cont' union
	select 'fisaAmortizare','contImobilizari' union
	select 'fisaAmortizare','contAmortizare' union
	select 'fisaAmortizare','contCheltuiala'

	/* Stergem tabelele ce nu exista */
	delete d
	from ##date_prel d
	LEFT JOIN sys.objects so on so.name=d.tabel and so.type='U'
	where so.object_id IS NULL

	declare 
		@comandaDisableTriggere nvarchar(max), @comandaEnableTriggere nvarchar(max), @comandaUpdateTabele nvarchar(max)

	insert into ##trigg_prel(comandaSQLDisable, comandaSQLEnable)
	select
		'alter table '+tabel+' disable trigger all ','alter table '+tabel+' enable trigger all'
	from ##date_prel
	group by tabel

	update d
		set d.comandaSQL=
			'update t set t.'+d.coloana +'= c.cont_nou from '+d.tabel +' t join ##tmp_coresp c on t.'+d.coloana+'=c.cont_vechi and c.cont_nou is not null'
	from ##date_prel d

	select 
		@comandaDisableTriggere='', @comandaEnableTriggere='',@comandaUpdateTabele=''

	select 
		@comandaDisableTriggere=@comandaDisableTriggere + char(13) + comandaSQLDisable,
		@comandaEnableTriggere=@comandaEnableTriggere + char(13) + comandaSQLEnable
	from ##trigg_prel

	select
		@comandaUpdateTabele=@comandaUpdateTabele+char(13)+ comandaSQL from ##date_prel

	begin tran 
	
		/* Executam update-urile pentru tabelele normale*/
		begin try
			exec sp_executesql  @statement=@comandaDisableTriggere
		end try
		begin catch
			declare @m1 varchar(1000)
			set @m1='Eroare la sectiunea de dezactivare a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@m1,16,1)
		end catch

		begin try
			exec sp_executesql  @statement=@comandaUpdateTabele
		end try
		begin catch
			declare @m2 varchar(1000)
			set @m2='Eroare la sectiunea de actualizare a conturilor in tabele. '+ERROR_MESSAGE()
			raiserror (@m2,16,1)
		end catch
		
		begin try
			exec sp_executesql  @statement=@comandaEnableTriggere
		end try
		begin catch
			declare @m3 varchar(1000)
			set @m3='Eroare la sectiunea de activarea a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@m3,16,1)
		end catch
		/*
			Tabele mai speciale: Proprietati, Rulaje, MFIX, PozInCon, Plin
		*/
		begin try
			/* Plin */
			if object_id('tempdb..#tmpplin') IS NOT NULL
				drop table #tmpplin

			select p.* into #tmpplin from plin p
			JOIN #tmpInlocuireConturi c ON p.Cont=c.cont_vechi or p.Cont=c.cont_nou

			update p
				set p.Cont=c.cont_nou
			from #tmpplin p
			JOIN ##tmp_coresp c on p.Cont=c.cont_vechi

			alter table Plin disable trigger all
				--truncate table Plin
				delete p from plin p
				JOIN #tmpInlocuireConturi c ON p.Cont=c.cont_vechi or p.Cont=c.cont_nou

				insert into Plin(Subunitate, Cont, Data, Numar, Valuta, Curs, Total_plati, Total_incasari, Ziua, Numar_pozitii, Jurnal, Stare)
				select		
					Subunitate, Cont, Data, MAX(numar), max(valuta), max(curs), sum(total_plati), sum(total_incasari), max(ziua), sum(numar_pozitii), Jurnal, MAX(Stare)
				from #tmpplin
				group by Subunitate, Cont, Data, Jurnal
			alter table Plin enable trigger all

			/* PozInCon */
			if object_id('tempdb..#tmppozincon') IS NOT NULL
				drop table #tmppozincon

			select p.* into #tmppozincon from PozIncon p
			JOIN #tmpInlocuireConturi c ON p.Cont_debitor=c.cont_vechi or p.Cont_creditor=c.cont_vechi OR p.Cont_debitor=c.cont_nou OR p.Cont_creditor=c.cont_nou
				or (p.numar_document=c.cont_vechi or p.numar_document=c.cont_nou) and p.Tip_document='PI'

			update t
				set Cont_creditor=c.cont_nou
			from #tmppozincon t 
			JOIN #tmpInlocuireConturi c ON t.Cont_creditor=c.cont_vechi
						
			update t
				set Cont_debitor=c.cont_nou
			from #tmppozincon t 
			JOIN #tmpInlocuireConturi c ON t.Cont_debitor=c.cont_vechi

			update t
				set numar_document=tc.cont_nou
			from #tmppozincon t 
			JOIN ##tmp_coresp tc on tc.cont_vechi=t.Numar_document 
			where t.Tip_document='PI'

			alter table PozInCon disable trigger all
				--truncate table PozInCon
				delete p from PozInCon p
				JOIN #tmpInlocuireConturi c ON p.Cont_debitor=c.cont_vechi or p.Cont_creditor=c.cont_vechi OR p.Cont_debitor=c.cont_nou OR p.Cont_creditor=c.cont_nou
					or (p.numar_document=c.cont_vechi or p.numar_document=c.cont_nou) and p.Tip_document='PI'

				insert into PozInCon(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, Indbug)
				select		
					Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, sum(Suma), Valuta, max(Curs), sum(Suma_valuta), max(Explicatii), 
					max(Utilizator), max(Data_operarii), max(Ora_operarii), MIN(Numar_pozitie), Loc_de_munca, Comanda, max(Jurnal), max(Indbug)
				from #tmppozincon
				group by Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Loc_de_munca, Comanda, Valuta, Numar_pozitie
			alter table PozInCon enable trigger all

			/*	Tabela INCON, campul numar_document in conditiile tip_document=PI, contine contul din plin	*/
			/*	Pun in #inconPI, antetul inregistrarilor de plati incasari pe care se va face inlocuire de conturi. Pe baza tabelei #inconPI, se va face stergerea din incon. */
			if object_id('tempdb..#inconPI') IS NOT NULL
				drop table #inconPI
			select distinct subunitate, tip_document, numar_document, data, jurnal into #inconPI 
			from #tmppozincon
			where Tip_document='PI'
			
			delete i from incon i 
			JOIN #inconPI t ON t.subunitate=i.subunitate and t.tip_document=i.tip_document and t.numar_document=i.numar_document and t.data=i.data and t.Jurnal=i.jurnal

			insert incon(Subunitate, Tip_document, Numar_document, Data, Jurnal, Numar_pozitie )
			select 
				Subunitate, Tip_document, Numar_document, Data, Jurnal, max(Numar_pozitie )
			from #tmppozincon
			where tip_document='PI'
			group by Subunitate, Tip_document, Numar_document, Data, Jurnal 			

			/* Proprietati*/
			if object_id('tempdb..#tmpProp') IS NOT NULL    
				drop table #tmpProp    
			
			select p.* into #tmpProp from proprietati p 
			JOIN #tmpInlocuireConturi c ON p.Cod=c.cont_vechi OR p.Cod=c.cont_nou
			where p.tip='cont'   
   
			update p     
				set p.Cod=c.cont_nou    
			from #tmpProp p    
			JOIN ##tmp_coresp c on c.cont_vechi=p.Cod and p.tip ='CONT' and c.cont_nou IS NOT NULL 
			
			alter table proprietati disable trigger all    
   
			delete p from proprietati p 
			JOIN #tmpInlocuireConturi c ON p.Cod=c.cont_vechi OR p.Cod=c.cont_nou
			where tip='cont' 
			insert into proprietati(Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)    
			select Tip, Cod, Cod_proprietate, max(Valoare), max(Valoare_tupla)
			from #tmpProp    
			group by Tip, Cod, Cod_proprietate
   
			alter table proprietati enable trigger all
				
			/* Rulaje -> tratare mai deosebita*/
			alter table rulaje disable trigger all
				if object_id('tempdb..#tmprulaje') IS NOT NULL
					drop table #tmprulaje

				/* Salvam rulajele vechi */
				select r.* into #tmprulaje from rulaje r
				JOIN #tmpInlocuireConturi c ON r.Cont=c.cont_vechi OR r.Cont=c.cont_nou

				/* In tabelul temporar neavand index facem actualizarea conturilor direct */
				update r
					set r.cont=c.cont_nou
				from #tmprulaje r
				JOIN ##tmp_coresp c on c.cont_vechi=r.Cont and c.cont_nou IS NOT NULL

				if object_id('tempdb..#tmprulajecen') IS NOT NULL
					drop table #tmprulajecen
		
				/* Centralizam rulajele din tabelul temporar pt. a ne asigura de respectarea indexului din Rulaje */
				select subunitate, cont, loc_de_munca, valuta, data, sum(rulaj_debit) rulaj_debit, sum(rulaj_credit) rulaj_credit, Indbug
				into #tmprulajecen
				from #tmprulaje
				group by subunitate, cont, loc_de_munca, valuta, data, Indbug

				/* Golim tabelul rulaje si il "populam" cu datele calculate in tabelul temp. centralizat, doar pentru conturile implicate in inlocuire. */
				--truncate table rulaje
				delete r from rulaje r
				JOIN #tmpInlocuireConturi c ON r.Cont=c.cont_vechi OR r.Cont=c.cont_nou

				insert into rulaje (Subunitate,cont,Loc_de_munca,Valuta,data,Rulaj_debit,Rulaj_credit,Indbug)
				select
					Subunitate,cont,Loc_de_munca,Valuta,data,Rulaj_debit,Rulaj_credit,Indbug
				from #tmprulajecen

				if object_id('tempdb..#rulajetmp') IS NOT NULL
					drop table #rulajetmp
				/* Cu tabela temporara merge mai rapid update-ul pe rulaje. */
				select 
					r.subunitate, r.cont, r.loc_de_munca, r.valuta, r.data, c.tip_cont,
					round((case when c.Tip_cont='A' then 1 when c.Tip_cont='P' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)>0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) rulaj_debit,
					-round((case when c.Tip_cont='P' then 1 when c.Tip_cont='A' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)<0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) rulaj_credit,
					r.Indbug
				into #rulajetmp
				from rulaje r
				JOIN conturi c on c.Cont=r.Cont
				JOIN ##tmp_coresp tc on tc.cont_nou=c.cont
				where	MONTH(data)=1 and DAY(data)=1 
				group by r.subunitate, r.cont, r.loc_de_munca, r.valuta, r.data, c.tip_cont, r.Indbug

				update rl
					set 
						rl.rulaj_debit=rtmp.rulaj_debit,
						rl.rulaj_credit=rtmp.rulaj_credit
				FROM rulaje rl
				JOIN conturi c on rl.cont=c.cont
				JOIN ##tmp_coresp tc on tc.cont_nou=c.cont
				JOIN #rulajetmp rtmp on rl.subunitate=rtmp.subunitate and rl.cont=rtmp.cont and rl.loc_de_munca=rtmp.loc_de_munca and rl.valuta=rtmp.valuta and rl.data=rtmp.data 
					and rtmp.tip_cont=c.tip_cont and rl.Indbug=rtmp.Indbug
			
			/*	Refacere rulaje conturi parinte ale celor afectate. Pregatim doar contu*/
			declare
				@comandaRefacereRulaje nvarchar(4000)

			select
				@comandaRefacereRulaje = ''

			select distinct LEFT(cont_vechi,3) cont_vechi, LEFT(cont_nou,3) cont_nou into #refac from ##tmp_coresp
			select
				@comandaRefacereRulaje = @comandaRefacereRulaje + '
				exec RefacereRulajeParinte @dDataJos = NULL, @dDataSus = NULL, @cCont = '''+RTRIM(cont_vechi)+''', @nInLei = 1, @nInValuta = 1, @cValuta = '''' , @SiSoldIncAn = 1'+ CHAR(13) +
				'exec RefacereRulajeParinte @dDataJos = NULL, @dDataSus = NULL, @cCont = '''+RTRIM(cont_nou)+''', @nInLei = 1, @nInValuta = 1 , @cValuta = '''' , @SiSoldIncAn = 1'
			from #refac
			
			exec sp_executesql @statement=@comandaRefacereRulaje

			alter table rulaje enable trigger all
			

			/* MFIX- Aici sunt tratate conturile de prin refolosiri la documentele de Mijloace Fixe si alte gunoaie- partea aceasta probabil va disparea odata cu noua aplicatie MF*/

			-- Tabela MFIX, campul Cod_de_clasificare in conditiile subunitate=DENS
			alter table mfix disable trigger all
				update p 
					set p.Cod_de_clasificare=c.cont_nou
				from mfix p
				JOIN ##tmp_coresp c on c.cont_vechi=p.Cod_de_clasificare and p.Subunitate='DENS' and c.cont_nou IS NOT NULL
			alter table mfix enable trigger all

			-- Tabele MISMF, campurile Loc_de_munca_primitor si gestiune_primitoare in conditiile tip_miscare=EVI
			alter table mismf disable trigger all
				update m
					set m.Loc_de_munca_primitor=(case when tc.cont_vechi=m.Loc_de_munca_primitor then tc.cont_nou else m.Loc_de_munca_primitor end),
					    m.gestiune_primitoare=(case when tc.cont_vechi=m.gestiune_primitoare then tc.cont_nou else m.gestiune_primitoare end)
				from mismf m 
				JOIN ##tmp_coresp tc on (tc.cont_vechi=m.Loc_de_munca_primitor OR tc.cont_vechi=m.gestiune_primitoare)
				where m.tip_miscare='EVI'
				
				-- Tabele MISMF, campul subunitate_primitoare, fara conditii: putea fi adaugat si la lista de tabele de sus, dar pentru a fi mai usor de identificat (apartenenta la MF) este aici
				update m
					set m.Subunitate_primitoare=tc.cont_nou
				from mismf m
				JOIN ##tmp_coresp tc on tc.cont_vechi=m.Subunitate_primitoare
			alter table mismf enable trigger all
						
			alter table pozdoc disable trigger all
				/*	Tabela POZDOC, campurile numar_dvi si contract in conditiile jurnal=MFX 
					campul gestiune_primitoare in conditiile tip document=AI, AE si jurnal=MFX 
				*/
				update p
					set p.numar_dvi=(case when tc.cont_vechi=p.numar_dvi then tc.cont_nou else p.numar_dvi end),
						p.contract=(case when tc.cont_vechi=p.contract then tc.cont_nou else p.contract end),
						p.gestiune_primitoare=(case when tc.cont_vechi=p.gestiune_primitoare then tc.cont_nou else p.gestiune_primitoare end)
				from PozDoc p 
				JOIN ##tmp_coresp tc on (tc.cont_vechi=p.numar_dvi OR tc.cont_vechi=p.contract OR (p.tip in ('AI','AE') and p.gestiune_primitoare = tc.cont_vechi))
				where p.jurnal='MFX'

			-- in pozdoc.detalii tinem unle conturi, completate prin exceptie: ex. contul de TVA deductibil la receptii

			alter table pozdoc enable trigger all		

		end try
		begin catch
			declare @m4 varchar(1000)
			set @m4='Eroare la sectiunea de prelucrare a datelor din tabelele cu statut mai special. '+ERROR_MESSAGE()
			raiserror (@m4,16,1)
		end catch
	commit tran
	
	IF @fara_mesaje=0
		select 'Notificare' titluMesaj, 'Inlocuirea conturilor s-a finalizat cu succes!' textMesaj for xml raw, root('Mesaje')

	IF OBJECT_ID('tempdb..#tmpInlocuireConturi') IS NOT NULL
		drop table #tmpInlocuireConturi
	IF OBJECT_ID('tempdb..##tmp_coresp') IS NOT NULL
		drop table ##tmp_coresp
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
