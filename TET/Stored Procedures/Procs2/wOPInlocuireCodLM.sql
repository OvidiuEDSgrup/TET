
Create PROCEDURE wOPInlocuireCodLM @sesiune VARCHAR(50), @parXML XML
AS
begin try
/*	
	Operatia poate fi apelata
		1. Dintr-o macheta sau alta operatie pentru un singur loc de munca caz in care se interpreteaza din XML <row cod_vechi="" cod_nou="" />
		2. Folosind #tmpInlocuireCoduriLM (cod_vechi, cod_nou) pentru a trimite set de date



	Exemplu apel
	1:
		exec wOPInlocuireCodLM '','<row cod_vechi="371.0" cod_nou="371.1"/>'

	2:  Dam exemplu tot pentru un singur loc de munca, dar tabelul #tmpInlocuireCoduriLM poate retine oricate perechi de conturi
		IF OBJECT_ID('tempdb..#tmpInlocuireCoduriLM') IS NOT NULL
			drop table #tmpInlocuireCoduriLM

		select '1' cod_nou, '2' cod_vechi into #tmpInlocuireCoduriLM

		exec wOPInlocuireCodLM '','<row fara_mesaje="1" />'
	 
*/

	declare	
		@cod_vechi varchar(20), @cod_nou varchar(20), @fara_mesaje bit

	select
		@cod_vechi=@parXML.value('(/*/@cod_vechi)[1]','varchar(20)'),
		@cod_nou=@parXML.value('(/*/@cod_nou)[1]','varchar(20)'),
		@fara_mesaje=ISNULL(@parXML.value('(/*/@fara_mesaje)[1]','bit'),0)

	IF @cod_vechi IS NOT NULL and @cod_nou IS NOT NULL
	begin
		/*Un singur COD de loc de munca*/
		IF OBJECT_ID('tempdb..#tmpInlocuireCoduriLM') IS NULL
			create table #tmpInlocuireCoduriLM (cod_vechi varchar(20), cod_nou varchar(20))

		truncate table #tmpInlocuireCoduriLM
		insert into #tmpInlocuireCoduriLM(cod_vechi, cod_nou)
		select @cod_vechi, @cod_nou
	end

	/* Pentru SQL Dynamic vom lucra cu un tabel temp. ## populat din cel de mai sus */
	IF OBJECT_ID('tempdb..##tmp_clm') IS NOT NULL
		drop table ##tmp_clm

	create table ##tmp_clm (cod_vechi varchar(20), cod_nou varchar(20))
	insert into ##tmp_clm(cod_vechi, cod_nou)
	select cod_vechi, cod_nou from #tmpInlocuireCoduriLM

	if OBJECT_ID('tempdb..##trigg_prel') IS NOT NULL
			drop table ##trigg_prel	
	create table ##trigg_prel (id int identity primary key,comandaSQLDisable nvarchar(4000), comandaSQLEnable nvarchar(4000))

	/* Aici vom trata majoritatea cazurilor, cele mai speciale (care depind de anumite conditii) le parcurgem separat mai jos */
	if OBJECT_ID('tempdb..##date_prel') IS NOT NULL
		drop table ##date_prel	
	create table ##date_prel (id int identity primary key, tabel varchar(100), coloana varchar(100), comandaSQL nvarchar(4000))

	insert into ##date_prel (tabel, coloana)
	select 'factimpl', 'loc_de_munca' union
	select 'facturi', 'loc_de_munca' union 
	select 'efimpl', 'loc_de_munca' union 
	select 'efecte', 'loc_de_munca' union 
	select 'decimpl', 'loc_de_munca' union 
	select 'deconturi', 'loc_de_munca' union 
	select 'doc', 'loc_munca' union 
	select 'pozdoc', 'loc_de_munca' union 
	select 'pozadoc', 'loc_munca' union 
	select 'pozplin', 'loc_de_munca' union 
	select 'personal', 'loc_de_munca' union 
	select 'pozncon', 'loc_munca' union 
	select 'comenzi', 'loc_de_munca' union 
	select 'comenzi', 'loc_de_munca_beneficiar' union 
	select 'pozncon', 'loc_munca' union 
	select 'pozncon', 'loc_munca' union 
	select 'con', 'loc_de_munca' union 
	select 'contcor', 'loc_de_munca' union 
	select 'delegexp', 'loc_de_munca' union 
	select 'incfact', 'loc_de_munca' union 
	select 'infotert', 'loc_munca' union 
	select 'mismf', 'loc_de_munca_primitor' union 
	select 'fisamf', 'loc_de_munca' union
	select 'active', 'loc_de_munca' union
	select 'pontaj', 'loc_de_munca' union
	select 'fisamf', 'loc_de_munca' union
	select 'corectii', 'loc_de_munca' union
	select 'brut', 'loc_de_munca' union
	select 'net', 'loc_de_munca' union
	select 'mandatar', 'loc_munca' union
	select 'istpers', 'loc_de_munca' union
	select 'decaux', 'l_m_furnizor' union
	select 'decaux', 'loc_de_munca_beneficiar' union
	select 'tehnpoz', 'Loc_munca' union
	select 'realcom', 'loc_de_munca' union
	select 'reallmun', 'loc_de_munca' union
	select 'contracte','loc_de_munca' union
	select 'activitati', 'loc_de_munca' union
	select 'activitati', 'lm_benef' union
	select 'pozactivitati', 'lm_beneficiar' union
	select 'activitati', 'lm_benef' union
	select 'unitati','lm' union
	select 'cost','loc_de_munca' union
	select 'Cheltcomp','loc_de_munca' union
	select 'antetBonuri','loc_de_munca' union
	select 'bp','lm_real' union
	select 'bt','lm_real' union 
	select 'fisaAmortizare','loc_de_munca'
	--select 'bp','loc_de_munca' union -> bp.loc_de_munca = gestiune
	--select 'bt','loc_de_munca'



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
			'update t set t.'+d.coloana +'= c.cod_nou from '+d.tabel +' t join ##tmp_clm c on t.'+d.coloana+'=c.cod_vechi and c.cod_nou is not null'
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
		select @comandaDisableTriggere
		/* Executam update-urile pentru tabelele normale*/
		begin try
			exec sp_executesql  @statement=@comandaDisableTriggere
		end try
		begin catch
			declare @m1 varchar(1000)
			set @m1='Eroare la sectiunea de dezactivare a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@m1,16,1)
		end catch
		select @comandaUpdateTabele
		begin try
			exec sp_executesql  @statement=@comandaUpdateTabele
		end try
		begin catch
			declare @m2 varchar(1000)
			set @m2='Eroare la sectiunea de actualizare a codurilor in tabele. '+ERROR_MESSAGE()
			raiserror (@m2,16,1)
		end catch
		select @comandaEnableTriggere
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

			/* PozInCon */
			if object_id('tempdb..#tmppozincon') IS NOT NULL
				drop table #tmppozincon

			select * into #tmppozincon from PozIncon
			
			update t
				set loc_de_munca=c.cod_nou
			from #tmppozincon t 
			JOIN #tmpInlocuireCoduriLM c ON t.Loc_de_munca=c.cod_vechi
			

			alter table PozInCon disable trigger all
				truncate table PozInCon

				insert into PozInCon(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal)
				select		
					Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, sum(Suma), Valuta, max(Curs), sum(Suma_valuta), max(Explicatii), max(Utilizator), max(Data_operarii), max(Ora_operarii), 
					Numar_pozitie, Loc_de_munca, Comanda, max(Jurnal)
				from #tmppozincon
				group by Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Loc_de_munca, Comanda, Valuta, Numar_pozitie
			alter table PozInCon enable trigger all

			/* Proprietati*/
			alter table proprietati disable trigger all
			
			-- daca o proprietate exista deja pe locul nou de munca, ignoram ce era pe vechiul loc de munca
			delete p
			from proprietati p
			JOIN ##tmp_clm c on c.cod_vechi=p.Cod and p.tip ='LM' and c.cod_nou IS NOT NULL
			and (p.valoare='' or exists (select * from proprietati p2 JOIN ##tmp_clm c2 on c.cod_nou=p2.Cod and p2.tip ='LM' and c.cod_vechi=c2.cod_vechi ))

			update p 
				set p.Cod=c.cod_nou
			from proprietati p
			JOIN ##tmp_clm c on c.cod_vechi=p.Cod and p.tip ='LM' and c.cod_nou IS NOT NULL

			alter table proprietati enable trigger all
		
				
			/* Rulaje -> tratare mai deosebita*/
			alter table rulaje disable trigger all
				if object_id('tempdb..#tmprulaje') IS NOT NULL
					drop table #tmprulaje

				/* Salvam rulajele vechi */
				select * into #tmprulaje from rulaje

				/* In tabelul temporar neavand index facem actualizarea conturilor direct */
				update r
					set r.Loc_de_munca=c.cod_nou
				from #tmprulaje r
				JOIN ##tmp_clm c on c.cod_vechi=r.Loc_de_munca and c.cod_nou IS NOT NULL

				if object_id('tempdb..#tmprulajecen') IS NOT NULL
					drop table #tmprulajecen
		
				/* Centralizam rulajele din tabelul temporar pt. a ne asigura de respectarea indexului din Rulaje */
				select subunitate, cont, loc_de_munca, valuta, data, sum(rulaj_debit) rulaj_debit, sum(rulaj_credit) rulaj_credit
				into #tmprulajecen
				from #tmprulaje
				group by subunitate, cont, loc_de_munca, valuta, data

				/* Golim tabelul rulaje si il "populam" cu datele calculate in tabelul temp. centralizat */
				truncate table rulaje
				insert into rulaje (Subunitate,cont,Loc_de_munca,Valuta,data,Rulaj_debit, Rulaj_credit)
				select
					Subunitate,cont,Loc_de_munca,Valuta,data,Rulaj_debit, Rulaj_credit
				from #tmprulajecen

				update rl
					set 
						rl.rulaj_debit=rtmp.rulaj_debit,
						rl.rulaj_credit=rtmp.rulaj_credit
				FROM rulaje rl
				JOIN conturi c on rl.cont=c.cont
				JOIN ##tmp_clm tc on tc.cod_nou=c.cont
				JOIN
				(
					select 
						r.subunitate, r.cont, r.loc_de_munca, r.valuta, r.data, c.tip_cont,
						round((case when c.Tip_cont='A' then 1 when c.Tip_cont='P' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)>0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) rulaj_debit,
						-round((case when c.Tip_cont='P' then 1 when c.Tip_cont='A' then 0 when sum(r.rulaj_debit)-sum(r.rulaj_credit)<0 then 1 else 0 end)*(sum(r.rulaj_debit)-sum(r.rulaj_credit)),2) rulaj_credit
					from rulaje r
					JOIN conturi c on c.Cont=r.Cont
					JOIN ##tmp_clm tc on tc.cod_nou=c.cont
					where	MONTH(data)=1 and DAY(data)=1 
					group by r.subunitate, r.cont, r.loc_de_munca, r.valuta, r.data, c.tip_cont
				) rtmp on rl.subunitate=rtmp.subunitate and rl.cont=rtmp.cont and rl.loc_de_munca=rtmp.loc_de_munca and rl.valuta=rtmp.valuta and rl.data=rtmp.data and rtmp.tip_cont=c.tip_cont

			alter table rulaje enable trigger all
			
		end try
		begin catch
			declare @m4 varchar(1000)
			set @m4='Eroare la sectiunea de prelucrare a datelor din tabelele cu statut mai special. '+ERROR_MESSAGE()
			raiserror (@m4,16,1)
		end catch
	commit tran
	
	IF @fara_mesaje=0
		select 'Notificare' titluMesaj, 'Inlocuirea codurilor s-a finalizat cu succes!' textMesaj for xml raw, root('Mesaje')

	IF OBJECT_ID('tempdb..#tmpInlocuireCoduriLM') IS NOT NULL
		drop table #tmpInlocuireCoduriLM
	IF OBJECT_ID('tempdb..##tmp_clm') IS NOT NULL
		drop table ##tmp_clm
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
