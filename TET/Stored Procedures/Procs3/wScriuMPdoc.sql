--***
create procedure [dbo].[wScriuMPdoc] @sesiune varchar(50), @parXML xml 
as

declare @tip char(2), @numar char(8), @data datetime, @schimb int, @sarja int, @ord float, 
	@gestprod char(9), @gestmat char(9), @lm char(9), @com char(9), @utilaj char(9), 
	@pozitie int, @cod char(20), @stoci float, @defabr float, @fabr float, @stoc float, @rebut float, 
	@pret float, @lot char(20), @dataexp datetime, @sef char(6), @mecanic char(6), 
	@nrpers int, @tipGrp char(2), @numarGrp char(8), @dataGrp datetime, 
	@sub char(9), @docXMLIaMPdocpoz xml, @eroare xml, @userASiS varchar(20)

begin try
	--BEGIN TRAN
	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuMPdocSP')
		exec wScriuMPdocSP @sesiune, @parXML output
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	declare crsMPdocpoz cursor for
	select tip, numar, data, schimb, sarja, 
	(case when isnull( gestpoz, '')<>'' then gestpoz when isnull( gestant, '')<>'' then gestant else '' end) as gestprod, 
	isnull( gestmat, '') as gestmat, (case when isnull( lmpoz, '')<>'' then lmpoz when isnull( lmant, '')<>'' then lmant else '' end) as lm, 
	(case when isnull( compoz, '')<>'' then compoz when isnull( comant, '')<>'' then comant else '' end) as com, isnull( sef, '') as sef, 
	isnull( mecanic, '') as mecanic, isnull( nrpers, 0) as nrpers, isnull( utilaj, '') as utilaj, isnull( pozitie, 0) as pozitie, isnull( cod, '') as cod, 
	isnull( defabr, 0) as defabr, isnull( fabr, 0) as fabr, isnull( stoc, 0) as stoc, isnull( rebut, 0) as rebut, 
	pret, isnull( lot, '') as lot, isnull( dataexp, '01/01/1901') as dataexp
	
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(2) '../@tip', 
		numar char(8) '../@numar',
		data datetime '../@data',
		schimb int '../@schimb',
		sarja int '../@sarja', 
		gestant char(9) '../@gestprod',
		gestmat char(9) '../@gestmat', 
		lmant char(9) '../@lm',
		comant char(13) '../@com',
		sef char(6) '../@sef',
		mecanic char(6) '../@mecanic',
		nrpers int '../@nrpers',
		utilaj char(20) '@utilaj',
		pozitie int '@pozitie',
		cod char(20) '@cod',
		defabr decimal(10, 3) '@defabr',
		fabr decimal(10, 3) '@fabr',
		stoc decimal(10, 3) '@stoc',
		rebut decimal(10, 3) '@rebut',
		gestpoz char(9) '@gestprod', 
		lmpoz char(9) '@lm', 
		compoz char(13) '@com', 
		pret float '@pret', 
		lot char(20) '@lot', 
		dataexp datetime '@dataexp'
	)

	open crsMPdocpoz
	fetch next from crsMPdocpoz into @tip, @numar, @data, @schimb, @sarja, @gestprod, @gestmat, @lm, @com, @sef, 
		@mecanic, @nrpers, @utilaj, @pozitie, @cod, @defabr, @fabr, @stoc, @rebut, @pret, @lot, @dataexp
	while @@fetch_status = 0
	begin
		if isnull(@com, '')='' or isnull((select val_logica from par where tip_parametru='MP' and parametru='RETCUCOM'),0)=0
		begin
			set @com=@cod
			if not exists (select 1 from comenzi where subunitate=@Sub and comanda=@com)
			insert into comenzi (Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, Loc_de_munca, Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef) select @sub, @com, 'P', (select denumire from tehn where cod_tehn=@cod), @data, @data, 'P', 0, @lm, '1901/01/01', '','','',''
			if not exists (select 1 from pozcom where subunitate=@Sub and comanda=@com)
			insert into pozcom (subunitate, comanda, cod_produs, cantitate, um) select @sub, @com, @cod, 1, ''
		end
		SELECT @pret=(case when isnull(@pret,0)=0 then (case when isnull( (select pret_stoc from nomencl where cod=(select max(cod) from tehnpoz where cod_tehn=@cod and tip='R')), 0)=0 then 1 else (select pret_stoc from nomencl where cod=(select max(cod) from tehnpoz where cod_tehn=@cod and tip='R')) end) else @pret end), @utilaj=isnull(@utilaj,''), @ord=convert (float, RTrim(replace(convert(char(10), @data, 102), '.', ''))+replicate('0',2-len(ltrim(convert(char(2),@schimb))))+rtrim(convert(char(2),@schimb))+ replicate('0',3-len(ltrim(convert(char(3),@sarja))))+rtrim(convert(char(3),@sarja)))
		SELECT @stoci=isnull((select top 1 c.stoc from MPdocpoz c where c.loc_munca=@lm and c.cod=@cod and c.utilaj= @utilaj and c.ordonare< @ord order by c.ordonare desc), 0)
		if @tip in ('RP') begin
			if isnull(@numar, '')='' or isnull(@schimb, 0)=0 or isnull(@sarja, 0)=0 or isnull(@lm, '')='' or isnull(@gestprod,'')='' or isnull(@gestmat, '')=''
				raiserror('Nu se poate adauga doc. fara nr./gestiuni/schimb/sarja/loc munca!', 11, 1)

			if ISNULL((select count(1) from mpdocpoz where subunitate=@Sub and schimb=@schimb and sarja=@sarja and data=@data and cod=@cod and loc_munca=@lm and utilaj=@utilaj ), 0)>0
				raiserror('Exista deja un doc. pe locul de munca, utilajul, articolul, data, schimbul si sarja introduse!', 11, 1)
			if ISNULL((select count(1) from pozcom where subunitate=@Sub and comanda=@com and cod_produs=@cod ), 0)=0
				raiserror('Cod inexistent pe comanda!', 11, 1)
			if @fabr<0 or @stoc<0 or @pret<0
				raiserror('Stocul final / fabricatul / pretul nu poate fi negativ!', 11, 1)
			if @fabr=0 or @stoci+@fabr-@stoc=0
				raiserror('Fabricatul si predatul (stoc initial + fabricat - stoc final) sunt nule!', 11, 1)
			if @stoci+@fabr-@stoc<0 --rtrim(convert (char(20), convert(decimal(10, 3), @stoci)))
				raiserror('Stoc final > stoc initial + fabricat!', 11, 1)
			if not exists (select 1 from mpdoc where tip=@tip and numar=@numar and data=@data and subunitate=@Sub)
				insert into mpdoc (Subunitate, Tip, Numar, Data, Schimb, Sarja, Gest_prod, Gest_mat, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Sef_schimb, Mecanic_schimb, Nr_pers_schimb, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Stare, Nr_pozitii, Utilizator, Data_operarii, Ora_operarii, Jurnal)
				select @Sub, @tip, @numar, @data, @schimb, @sarja, @gestprod, @gestmat, @lm, '', 
					@utilaj, '', @com, @sef, @mecanic, @nrpers, '','','', 0, 0, 0, 
					'', 0, @userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 'MPX'
			update mpdoc set nr_pozitii=nr_pozitii+1
				where subunitate=@Sub and tip=@tip and numar=@numar and data=@data
				
			if ISNULL((select max(stare) from mpdoc where subunitate=@Sub and tip=@tip and numar=@numar and data=@data), '')='I' or ISNULL((select count(1) from pozdoc where subunitate=@Sub and tip in ('CM', 'PP') and numar=@numar and data=@data), 0)>0
				raiserror('Doc. nu mai poate fi modificat, fiindca a fost inchis!', 11, 1)

			if isnull(@pozitie,0)=0 
				set @pozitie=isnull((select max(nr_pozitie) from mpdocpoz where subunitate=@Sub and tip=@tip and numar=@numar and data=@data),0)+1
			else
				delete from mpdocpoz where subunitate=@Sub and tip=@tip and numar=@numar and data=@data and nr_pozitie=@pozitie
				insert into mpdocpoz (Subunitate, Tip, Numar, Data, Schimb, Sarja, Ordonare, Gestiune, Loc_munca, Loc_munca_prim, Utilaj, Utilaj_prim, Comanda, Cod, De_fabricat, Fabricat, Stoc, Predat, Rebut, Rebut_KG, Preluat, Pret, Locatie, Lot, Data_expirarii, tip_consum, Nr_operatie, Cod_operatie, Ora_inceput, Ora_sfarsit, Alfa1, Alfa2, Alfa3, Val1, Val2, Val3, Tip_misc, Nr_pozitie, Utilizator, Data_operarii, Ora_operarii, Jurnal)
				select @Sub, @tip, @numar, @data, @schimb, @sarja, @ord, @gestprod, @lm, '', @utilaj, '', 
					@com, @cod, @defabr, @fabr, @stoc, @stoci+@fabr-@stoc, @rebut, 0, 0, @pret, '', 
					@lot, @dataexp, 'F', 0, '', '000000', '000000', '','','',0,0,0,'I', @pozitie, @userASiS, 
					convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 'MPX'
		end
		
		if @numarGrp is null
			select @tipGrp=@tip, @numarGrp=@numar, @dataGrp=@data
		
	fetch next from crsMPdocpoz into @tip, @numar, @data, @schimb, @sarja, @gestprod, @gestmat, @lm, @com, @sef, 
		@mecanic, @nrpers, @utilaj, @pozitie, @cod, @defabr, @fabr, @stoc, @rebut, @pret, @lot, @dataexp
	end
	
	set @docXMLIaMPdocpoz = '<row subunitate="' + rtrim(@sub) + '" tip="' + rtrim(@tipGrp) + '" numar="' + rtrim(@numarGrp) + '" data="' + convert(char(10), @dataGrp, 101)+'"/>'
	exec wIaMPdocpoz @sesiune=@sesiune, @docXML=@docXMLIaMPdocpoz 
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj = ERROR_MESSAGE() 
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
end catch

IF OBJECT_ID('crsMPdocpoz') IS NOT NULL
	begin
	close crsMPdocpoz 
	deallocate crsMPdocpoz 
	end

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
