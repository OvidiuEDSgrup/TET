
CREATE PROCEDURE wOPInlocuireCodNomenclator @sesiune VARCHAR(50), @parXML XML output
AS
	SET NOCOUNT ON
if exists(select * from sysobjects where name='wOPInlocuireCodNomenclatorSP' and type='P')      
begin
	exec wOPInlocuireCodNomenclatorSP @sesiune=@sesiune,@parXML=@parXML
	return 0
end

BEGIN TRY
	declare 
		@cod_nou varchar(20), @cod_vechi varchar(20), @fara_mesaje bit
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	select
		@cod_vechi=@parXML.value('(/*/@cod)[1]','varchar(20)'),
		@cod_nou=@parXML.value('(/*/@cod_nou)[1]','varchar(20)'),
		@fara_mesaje=ISNULL(@parXML.value('(/*/@fara_mesaje)[1]','bit'),0)

	IF @cod_vechi IS NOT NULL and @cod_nou IS NOT NULL
	begin
		/*Un singur COD de nomenclator*/
		IF OBJECT_ID('tempdb..#tmpInlocuireCoduri') IS NULL
			create table #tmpInlocuireCoduri (cod_vechi varchar(20), cod_nou varchar(20))

		truncate table #tmpInlocuireCoduri
		insert into #tmpInlocuireCoduri(cod_vechi, cod_nou)
		select @cod_vechi, @cod_nou
	end

	IF OBJECT_ID('tempdb..##tmp_corespc') IS NOT NULL
		drop table ##tmp_corespc

	create table ##tmp_corespc (cod_vechi varchar(20), cod_nou varchar(20), comandaSQLRefaceri nvarchar(4000))
	insert into ##tmp_corespc(cod_vechi, cod_nou)

	select cod_vechi, cod_nou from #tmpInlocuireCoduri			

	if exists (select * from ##tmp_corespc tt where not exists (select * from nomencl n where n.cod=tt.cod_nou))
		raiserror ('Codul noul (destinatar) selectat nu exista in catalogul de articole (nomenclator)',16,1)

	if exists (select * from ##tmp_corespc tt where not exists (select * from nomencl n where n.cod=tt.cod_vechi))
		raiserror ('Codul vechi (sursa) selectat nu exista in catalogul de articole (nomenclator)',16,1)

	if OBJECT_ID('tempdb..##trigg_prel') IS NOT NULL
			drop table ##trigg_prel	
	create table ##trigg_prel (id int identity primary key,comandaSQLDisable nvarchar(4000), comandaSQLEnable nvarchar(4000))

	/* Aici vom trata majoritatea cazurilor, cele mai speciale (care depind de anumite conditii) vedem mai jos ce facem	*/
	if OBJECT_ID('tempdb..##date_prel') IS NOT NULL
		drop table ##date_prel	
	create table ##date_prel (id int identity primary key, tabel varchar(100), coloana varchar(100), comandaSQL nvarchar(4000))

	insert into ##date_prel (tabel, coloana)
	select 'PozDoc', 'cod' union
	select 'PozContracte', 'cod' union
	select 'Tehnologii', 'codNomencl' union
	select 'PozCom', 'cod_produs' union
	select 'PozCon', 'cod' union
	select 'PozInventar', 'cod' union
	select 'bp', 'cod_produs' union
	select 'bt', 'cod_produs' union
	select 'nomspec', 'cod' 

	/* Stergem tabelele ce nu exista */
	delete d
	from ##date_prel d
	LEFT JOIN sys.objects so on so.name=d.tabel and so.type='U'
	where so.object_id IS NULL	

	update ##tmp_corespc
		set comandaSQLRefaceri= 
			'exec RefacereStocuri @cCod= '''+rtrim(cod_vechi)+''''+char(13)+
			' exec RefacereStocuri @cCod= '''+rtrim(cod_nou)+''''
	
	declare 
		@comandaDisableTriggere nvarchar(max), @comandaEnableTriggere nvarchar(max), @comandaUpdateTabele nvarchar(max), @comandaRefaceri nvarchar(max)

	insert into ##trigg_prel(comandaSQLDisable, comandaSQLEnable)
	select
		'alter table '+tabel+' disable trigger all ','alter table '+tabel+' enable trigger all'
	from ##date_prel
	group by tabel

	update d
		set d.comandaSQL=
			'update t set t.'+d.coloana +'= c.cod_nou from '+d.tabel +' t join ##tmp_corespc c on t.'+d.coloana+'=c.cod_vechi '
	from ##date_prel d

	select 
		@comandaDisableTriggere='', @comandaEnableTriggere='',@comandaUpdateTabele='', @comandaRefaceri=''

	select 
		@comandaDisableTriggere=@comandaDisableTriggere + char(13) + comandaSQLDisable,
		@comandaEnableTriggere=@comandaEnableTriggere + char(13) + comandaSQLEnable
	from ##trigg_prel

	select
		@comandaUpdateTabele=@comandaUpdateTabele+char(13)+ comandaSQL from ##date_prel

	select
		@comandaRefaceri=@comandaRefaceri+' '+ comandaSQLRefaceri from ##tmp_corespc

	begin tran 
		declare 
			@err varchar(1000)
		/* Executam update-urile pentru tabelele normale*/
		begin try
			exec sp_executesql  @statement=@comandaDisableTriggere
		end try
		begin catch
			set @err='Eroare la sectiunea de dezactivare a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch

		begin try
			exec sp_executesql  @statement=@comandaUpdateTabele
		end try
		begin catch
			set @err='Eroare la sectiunea de actualizare a codurilor in tabele. '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch

		begin try
			exec sp_executesql  @statement=@comandaRefaceri
		end try
		begin catch
			set @err='Eroare la sectiunea de refacere de stocuri '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch
		begin try
			exec sp_executesql  @statement=@comandaEnableTriggere
		end try
		begin catch
			set @err='Eroare la sectiunea de activarea a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch
		begin try
			delete cb
			FROM codbare cb
			JOIN ##tmp_corespc tc on cb.cod_produs=tc.cod_vechi
		
			delete p
			FROM preturi p
			JOIN ##tmp_corespc tc on p.cod_produs=tc.cod_vechi

			delete p
			FROM ppreturi p
			JOIN ##tmp_corespc tc on p.cod_resursa=tc.cod_vechi
			
			delete n
			FROM nomencl n
			JOIN ##tmp_corespc tc on n.cod=tc.cod_vechi
			
			end try
		begin catch
			set @err='Eroare la sectiunea de stergere date vechi (coduri de bare, preturi, coduri vechi) '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch
		begin try
			
			/*	Tabelele de MPria unde actualizam filtrat pe cod	*/
			Update p
				set cod=t.cod_nou
			FROM PozTehnologii p
			JOIN ##tmp_corespc t on t.cod_vechi=p.cod and p.tip in ('M')

			Update p
				set cod=t.cod_nou
			FROM PozLansari p
			JOIN ##tmp_corespc t on t.cod_vechi=p.cod and p.tip in ('M')

			Update p
				set cod=t.cod_nou
			FROM pozAntecalculatii p
			JOIN ##tmp_corespc t on t.cod_vechi=p.cod and p.tip in ('M')

			/*	Daca exista situatia de coduri de intrare repetate pe cod_vechi, cod_nou	*/
			IF EXISTS (SELECT 1 from IstoricStocuri iv JOIN ##tmp_corespc tc on iv.Cod=tc.cod_vechi JOIN IstoricStocuri [in] on [in].Cod=tc.cod_nou
						where [in].Subunitate=iv.Subunitate and [in].Data_lunii=iv.Data_lunii and [in].cod_gestiune=iv.cod_gestiune and [in].Cod_intrare=iv.Cod_intrare)
			BEGIN

				IF OBJECT_ID('tempdb.dbo.#istoc') IS NOT NULL
					DROP TABLE #istoc
				
				SELECT
					i.*
				INTO #istoc
				from IstoricStocuri i
				JOIN ##tmp_corespc t on i.cod in (t.cod_vechi, t.cod_nou)

				DELETE i
				FROM IstoricStocuri i
				JOIN #istoc di on i.subunitate=di.subunitate and i.tip_gestiune=di.tip_gestiune and i.Cod_gestiune=di.Cod_gestiune and i.cod=di.cod and i.Cod_intrare=di.Cod_intrare


				update i
					set cod=t.cod_nou
				from #istoc i
				JOIN ##tmp_corespc t on i.cod=t.cod_vechi				 

				INSERT INTO IstoricStocuri (
					Subunitate, Data_lunii, Tip_gestiune, Cod_gestiune, Cod, Data, Cod_intrare, Pret, TVA_neexigibil, Pret_cu_amanuntul, Stoc, Cont, Locatie, Data_expirarii, Pret_vanzare, Loc_de_munca, Comanda, Contract, Furnizor, Lot, 
					Stoc_UM2, Val1, Alfa1, Data1, idIntrareFirma, idIntrare)
				SELECT
					Subunitate, Data_lunii, Tip_gestiune, Cod_gestiune, Cod, MAX(Data), Cod_intrare, MAX(Pret), MAX(TVA_neexigibil), MAX(Pret_cu_amanuntul), SUM(Stoc), MAX(Cont), MAX(Locatie), MIN(Data_expirarii), 
					MAX(Pret_vanzare), MAX(Loc_de_munca), MAX(Comanda), MAX(Contract), MAX(Furnizor), MAX(Lot), SUM(Stoc_UM2), MAX(Val1), MAX(Alfa1), MAX(Data1), MAX(idIntrareFirma), MAX(idIntrare)
				FROM #istoc
				GROUP BY subunitate, Data_lunii, Tip_gestiune, Cod_gestiune, cod, Cod_intrare
				
			END
			else
				update i
					set cod=t.cod_nou
				from IstoricStocuri i JOIN
				##tmp_corespc t on i.cod=t.cod_vechi	
		end try
		begin catch
			set @err='Eroare la sectiunea actualizare a datelor in tabelele tratate special (ex: IstoricStocuri)'+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch
		
		begin try
			exec sp_executesql  @statement=@comandaRefaceri
		end try
		begin catch
			set @err='Eroare la sectiunea de refacere de stocuri dupa inlocuiri '+ERROR_MESSAGE()
			raiserror (@err,16,1)
		end catch
		
		
	commit tran	
	
	IF @fara_mesaje=0
		select 'Notificare' titluMesaj, 'Inlocuirea codurilor s-a finalizat cu succes!' textMesaj for xml raw, root('Mesaje')
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
