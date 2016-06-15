
Create PROCEDURE wOPInlocuireCodTert @sesiune VARCHAR(50), @parXML XML
AS
begin try
	SET NOCOUNT ON
/*
	Exemplu apel

		exec wOPInlocuireCodTert '','<row tert="RO17627090" tert_nou="RO17627030"/>'
*/
	declare 
		@fara_mesaje bit, @tert_vechi varchar(20), @tert_nou varchar(20)

	select
		@tert_vechi=@parXML.value('(/*/@tert)[1]','varchar(20)'),
		@tert_nou=@parXML.value('(/*/@tert_nou)[1]','varchar(20)'),
		@fara_mesaje=ISNULL(@parXML.value('(/*/@fara_mesaje)[1]','bit'),0)
	IF @tert_vechi IS NOT NULL and @tert_nou IS NOT NULL
	begin
		IF OBJECT_ID('tempdb..##tmp_tert') IS NOT NULL
			drop table ##tmp_tert
		create table ##tmp_tert (tert_vechi varchar(20), tert_nou varchar(20), comandaSQLRefaceri nvarchar(4000))

		insert into ##tmp_tert(tert_vechi, tert_nou)
		select @tert_vechi, @tert_nou
	end

	if exists (select * from ##tmp_tert tt
					where not exists (select * from terti t where t.tert=tt.tert_nou))
		raiserror ('Tertul destinatar nu exista in catalogul de terti. ',16,1)
	
	update ##tmp_tert
		set comandaSQLRefaceri=		
			'exec RefacereFacturi '''','''+convert(varchar(20), GETDATE())+''','''+tert_vechi+''', null'+ char(13)+
			'exec RefacereFacturi '''','''+convert(varchar(20), GETDATE())+''','''+tert_nou+''', null'+char(13)+
			'exec RefacereEfecte '''+convert(varchar(20), GETDATE())+''','''','''+tert_vechi+''', null'+char(13)+
			'exec RefacereEfecte '''+convert(varchar(20), GETDATE())+''','''','''+tert_nou+''', null'

	if OBJECT_ID('tempdb..##trigg') IS NOT NULL
			drop table ##trigg
		create table ##trigg (id int identity primary key,comandaSQLDisable nvarchar(4000), comandaSQLEnable nvarchar(4000))

	if OBJECT_ID('tempdb..##date_itert') IS NOT NULL
		drop table ##date_itert	

	create table ##date_itert (id int identity primary key, tabel varchar(100), coloana varchar(100), comandaSQL nvarchar(4000))

	insert into ##date_itert (tabel, coloana)
	select 'antetBonuri','Tert' union
	select 'avnefac','Cod_tert' union
	select 'penalizarifact','Tert' union
	select 'PozOrdineDePlata','tert' union
	select 'FactSold','tert' union
	select 'doc','Cod_tert' union
	select 'tmpCentralizatorComenziTransport','tert' union
	select 'Contracte','tert' union
	select 'pozactivitati','Tert' union
	select 'con','Tert' union
	select 'pozcon','Tert' union
	select 'CarduriFidelizare','Tert' union
	select 'nomspec','Tert' union
	select 'SoldFacturiTLI','tert' union
	select 'ppreturi','Tert' union
	select 'pozdoc','Tert' union
	select 'DVI','Cont_tert_vama' union
	select 'DVI','Tert_CIF' union
	select 'DVI','Tert_comis' union
	select 'DVI','Tert_receptie' union
	select 'DVI','Tert_vama' union
	select 'pozplin','Tert' union
	select 'adoc','Tert' union
	select 'pozadoc','Tert' union
	select 'pozncon','Tert' union
	select 'incfact','Tert' union
	select 'misMF','Tert' union
	select 'factimpl','Tert' union
	select 'istfact','Tert' union
	select 'efimpl','Tert' union
	select 'comenzi','beneficiar' union
	select 'bt','client' union
	select 'bp','client'
	-- nu se face inlocuire in tabelele atasate: infotert, TVApeTerti - se presupune ca sunt bune pe noul tert

	/* Stergem tabelele ce nu exista */
	delete d
	from ##date_itert d
	LEFT JOIN sys.objects so on so.name=d.tabel and so.type='U'
	where so.object_id IS NULL

	-- Pentru aceste doua tabele trebuie discutat si vazut daca este in regula

	declare 
		@comandaDisableTriggere nvarchar(max), @comandaEnableTriggere nvarchar(max), @comandaUpdateTabele nvarchar(max), @comandaRefaceri nvarchar(max)

	insert into ##trigg(comandaSQLDisable, comandaSQLEnable)
	select
		'alter table '+tabel+' disable trigger all ','alter table '+tabel+' enable trigger all'
	from ##date_itert
	group by tabel

	update d
		set d.comandaSQL=
			'update t set t.'+d.coloana +'= c.tert_nou from '+d.tabel +' t join ##tmp_tert c on t.'+d.coloana+'=c.tert_vechi '
	from ##date_itert d

	select 
		@comandaDisableTriggere='', @comandaEnableTriggere='',@comandaUpdateTabele='', @comandaRefaceri=''

	select 
		@comandaDisableTriggere=@comandaDisableTriggere + char(13) + comandaSQLDisable,
		@comandaEnableTriggere=@comandaEnableTriggere + char(13) + comandaSQLEnable
	from ##trigg

	select
		@comandaUpdateTabele=@comandaUpdateTabele+char(13)+ comandaSQL from ##date_itert

	select
		@comandaRefaceri=@comandaRefaceri+' '+ comandaSQLRefaceri from ##tmp_tert

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
			set @m2='Eroare la sectiunea de actualizare a codurilor de tert in tabele. '+ERROR_MESSAGE()
			raiserror (@m2,16,1)
		end catch

		begin try
			exec sp_executesql  @statement=@comandaRefaceri
		end try
		begin catch
			declare @m4 varchar(1000)
			set @m4='Eroare la sectiunea de refacere facturi si efecte terti '+ERROR_MESSAGE()
			raiserror (@m4,16,1)
		end catch
		begin try
			exec sp_executesql  @statement=@comandaEnableTriggere
		end try
		begin catch
			declare @m3 varchar(1000)
			set @m3='Eroare la sectiunea de activarea a triggerelor pe tabelele implicate. '+ERROR_MESSAGE()
			raiserror (@m3,16,1)
		end catch
			
	commit tran
	
	IF @fara_mesaje=0
		select 'Notificare' titluMesaj, 'Inlocuirea codurilor de tert s-a finalizat cu succes!' textMesaj for xml raw, root('Mesaje')

	IF OBJECT_ID('tempdb..#tmpInlocuireConturi') IS NOT NULL
		drop table #tmpInlocuireConturi
	IF OBJECT_ID('tempdb..##tmp_tert') IS NOT NULL
		drop table ##tmp_tert
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
