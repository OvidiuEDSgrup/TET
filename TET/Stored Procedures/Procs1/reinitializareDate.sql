
create procedure reinitializareDate (@datareinit datetime,@stergdoc int,@reffact int,@refdec int,@refefecte int)
as
begin try
	SET NOCOUNT ON
	/*
		Exemplu apel (din RIA apelul vine din procedura wOPReinitializareDate) in ASiSplus se va apela in stilul de mai jos ):
		exec reinitializareDate @datareinit= '2013-12-31', @stergdoc =1, @reffact =1, @refdec =1, @refefecte =1
	*/
	declare 
		@utilizator varchar(100), @sub char(9),@luna int,@lunaalfa char(20),@anul int, @initFact xml, @anul_inc int, @luna_inc int

	select @utilizator=dbo.fIaUtilizator (null)
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output

	/* Validare */
	IF EXISTS (select 1 from LMFiltrare where utilizator=@utilizator)
		raiserror('Accesul dvs. este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)

	/* Determinam anul si luna  */
	select @luna=month(@datareinit), @anul=year(@datareinit)
	select @lunaalfa=LunaAlfa from fCalendar(@datareinit,@datareinit)
	
	begin tran

		/* Fiind in tranzactie comitem deja modificarile in PAR*/
		exec setare_par 'GE','LUNAIMPL','Luna impl.',0,@luna,@lunaalfa
		exec setare_par 'GE','ANULIMPL','Anul lunii impl.',0,@anul,''
		exec setare_par 'MF','LUNAINCH','Ultima luna inchisa',0,@luna,@lunaalfa
		exec setare_par 'MF','ANULINCH','Anul ultimei luni inchise',0,@anul,''
		
		--exec setare_par 'GE','ULT_AN_IN','Ultimul an initializare facturi',1,0,'' asta nu vad ce efect ar da


		/************   PASI REINITIALIZARE DATE ************/

		/* PAS 1- oprim triggerele si actualizam ID-uri in POZDOC, STOCURI si ISTORICSTOCURI*/
		alter table PozDoc disable trigger all

		update PozDoc set idIntrare=null, idIntrareFirma=null, idIntrareTI=null
		update Stocuri set idIntrare=null, idIntrareFirma=null
		update IstoricStocuri set idIntrare=null, idIntrareFirma=null
		
		/* Pas 2 - Initializare stoc la data, daca e cazul */
		exec luare_date_par 'GE','ANULINC',0,@anul_inc OUTPUT, ''
		exec luare_date_par 'GE','LUNAINC',0,@luna_inc OUTPUT, ''
	
		IF @anul_inc!=@anul OR @luna_inc!=@luna OR NOT EXISTS(select 1 from istoricstocuri where data_lunii=@datareinit)
		begin
			declare @initStocuri xml
			set @initStocuri=(select @anul an, @luna luna for xml raw)
			exec initializareLunaStocuriRIA @sesiune='', @parXML=@initStocuri
		end

		/* Pas 3- Initializare facturi, deconturi si efecte */
			/* Initializare facturi la luna de reimpl.*/
			set @initFact= (select @luna luna, @anul an for xml raw)
			exec initializareFacturi @sesiune='', @parXML=@initFact

			/* Initializare deconturi la luna de reimpl.*/
			exec RefacereDeconturi @ddata=@datareinit, @cmarca='', @cdecont=''

			delete from decimpl 
			insert into decimpl (Subunitate, Tip, Marca, Decont, Cont, Data, Data_scadentei, Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii) 
			select * from deconturi where sold<>0 or sold_valuta<>0	
	
			/* Initializare efecte la luna de reimpl.*/
			exec RefacereEfecte @ddata=@datareinit, @ctipef='', @ctert='', @cefect=''

			delete from efimpl  
			insert into efimpl (Subunitate, Tip, Tert, Nr_efect, Cont, Data, Data_scadentei, Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, Loc_de_munca, Comanda, Data_decontarii, Explicatii) 
			select * from efecte where sold<>0 or sold_valuta<>0

		/* PASUL 4- Sectiunea de stergere documente anterioare-> daca este cazul*/
	
		if @stergdoc=1
		begin
			declare @comanda_sql nvarchar(4000)
			if OBJECT_ID('tempdb..##tabele') IS NOT NULL
				drop table ##tabele	
		
			create table ##tabele (id int identity primary key, tabel varchar(100),data varchar(100) DEFAULT 'data', comandaSQL nvarchar(4000))
			insert into ##tabele (tabel)
			select 'rulaje' union
			select 'incon' union
			select 'pozincon' union
			select 'doc' union
			select 'pozdoc' union
			select 'pdserii' union
			select 'plin' union
			select 'pozplin' union
			select 'adoc' union
			select 'pozadoc' union
			select 'ncon' union
			select 'pozncon' 

			insert into ##tabele (tabel, data)
			--select 'istoricstocuri','data_lunii' union
			select 'istoricserii','data_lunii' union
			select 'istfact' ,'data_an' union
			select 'dvi', 'data_dvi'

			update d
			set comandaSQL=
				'alter table '+tabel+ ' disable trigger all ' + 
				'delete '+tabel+' where '+data + ' <=''' + convert(varchar(10),@datareinit,101)+''''+(case when tabel in ('pozdoc','doc') then 'and tip!=''SI''' else '' end )+' '+
				'alter table '+tabel+' enable trigger all '
			from ##tabele d

			select @comanda_sql=''
			select @comanda_sql=@comanda_sql+char(13)+ comandaSQL from ##tabele
			
			begin try
				exec sp_executesql  @statement=@comanda_sql
			end try
			begin catch
				declare @errTab varchar(4000)
				set @errTab= 'Eroare generata la stergerea datelor din tabele! [' +ERROR_MESSAGE()+ ']'
				RAISERROR(@errTab,15,1)
			end catch
		end	

		/*PASUL 5- rulare adauga iditrare firma, care se va ocupa si de documentele "SI" dupa noua data a implementarii-schimbata mai sus*/		
		exec AdaugIdIntrareFirma '',''

		/*PASUL 6- refaceri */
			/*Refacere stocuri la zi*/
			exec RefacereStocuri @cGestiune=null, @cCod=null, @cMarca=null, @dData = null, @PretMed=0, @InlocPret=0
			/*Refacere facturi la zi*/
			if @reffact=1 exec RefacereFacturi @cFurnBenef='', @ddata=null, @ctert=null, @cfactura=null
			/*Refacere deconturi la zi*/
			if @refdec=1 exec RefacereDeconturi @ddata='12/31/2999', @cmarca='', @cdecont=''
			/*Refacere efecte la zi*/
			if @refefecte=1 exec RefacereEfecte @ddata='12/31/2999', @cTipEf='', @ctert='', @cefect=''
	
	commit tran
end try
begin catch
	IF @@trancount>0
		rollback tran
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
