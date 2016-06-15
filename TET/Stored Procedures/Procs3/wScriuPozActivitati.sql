--***
create procedure wScriuPozActivitati @sesiune varchar(50),@parXML XML      
as      
declare @idActivitati int, @idPozActivitati int,
		@tip varchar(2), @fisa varchar(10), @data datetime, @o_tip varchar(2), @o_fisa varchar(10), @o_data datetime,
		@masina varchar(20), @comanda varchar(20), @lm varchar(9), @comanda_benef_antet varchar(20), @lm_benef_antet varchar(9),
		@tert_antet varchar(13), @marca_antet varchar(20), @marca_ajutor_antet varchar(20),
		@jurnal_antet varchar(20),
		@numar_pozitie int, @subtip varchar(2), @traseu varchar(20), @tert varchar(13), @plecare varchar(50), @data_plecarii datetime, 
		@ora_plecarii varchar(20), @sosire varchar(50), @data_sosirii datetime, @ora_sosirii varchar(20), @interventie varchar(40), @valoare float,
		@explicatii varchar(200), @comanda_benef varchar(20), @lm_benef varchar(9), @marca varchar(9), @eroare xml , @userASiS varchar(20), @textExec nvarchar(max),
		@AlimComb float, @KmEf float, @KmBord float, @KmEchv float, @ConsComb float, @RestDecl float, @OREBORD float,
		@implementare bit
        
--BEGIN TRAN
begin try
		/* chem procedura care va scrie in XML elementele calculate. */
	/* Sterg linia curenta daca exista. Ea va fi inserata */
	if @parXML.value('(/row/row/@update)[1]', 'int')=1 --Update-ul se va face prin stergere si creeare
	begin
		raiserror('Nu este permisa modificarea! Stergeti linia gresita si operati-o din nou!',16,1)
		/*
		declare @randXML xml
		set @randXML=@parXML.query('(/row/row)[1]')
		exec wStergPozActivitati @sesiune,@randXMl
		*/
	end

	if exists(select * from sysobjects where name='wCalcElemActivitati' and type='P')
		exec wCalcElemActivitati @sesiune=@sesiune, @parXML = @parXML output
	else 
		raiserror('Procedura wCalcElemActivitati, folosita pentru elementele calculate, nu a fost gasita. 
		Configurati procedura folosind ca model procedura wCalcElemActivitatiModel.',11,1)
	if exists(select * from sysobjects where name='wScriuPozActivitatiSP' and type='P')
		exec wScriuPozActivitatiSP @sesiune=@sesiune, @parXML = @parXML output

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	select @implementare = isnull(@parXML.value('(/row/@implementare)[1]', 'bit'),'0')
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	/* citesc in cursor toate campurile statice din activitati si pozactivitati */
	declare crsPozActivitati cursor for
	select
			--antet
	idActivitati, tip, fisa, data, o_tip, o_fisa, o_data, isnull(masina,'') as masina, isnull(comanda,'') as comanda,
	isnull(loc_de_munca,'') as loc_de_munca, isnull(comanda_benef_antet,'') as comanda_benef_antet,
	isnull(lm_benef_antet,'') as lm_benef_antet, isnull(tert_antet,'') as tert_antet,
	isnull(marca_antet,'') as marca_antet, isnull(marca_ajutor_antet,'') marca_ajutor_antet,
	isnull(jurnal_antet,'') as jurnal_antet, 
			--pozitii
	numar_pozitie, subtip,  isnull(interventie,'') as interventie, isnull(valoare,0) as valoare, 
	isnull(traseu,'') as traseu, 
	isnull(tert,'') as tert, isnull(plecare,'') as plecare,
	isnull(data_plecarii,data) as data_plecarii, isnull(ora_plecarii,'') as ora_plecarii,
	isnull(sosire,'') as sosire, isnull(data_sosirii,data) as data_sosirii,
	isnull(ora_sosirii,'') as ora_sosirii, isnull(explicatii,'') as explicatii, 
	isnull(comanda_benef,'') as comanda_benef, isnull(lm_benef,'') as lm_benef, isnull(marca,'') as marca,
	--,isnull(KmEf,'') KmEf,isnull(KmBord,'') KmBord,isnull(KmEchv,'') KmEchv,isnull(ConsComb,'') ConsComb,isnull(RestDecl,'') RestDecl
	AlimComb ,  KmEf, KmBord, KmEchv, ConsComb, RestDecl , OREBORD
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(	--antet
		idActivitati int '../@idActivitati',
		tip varchar(10) '../@tip',
		fisa varchar(10) '../@fisa',
		data datetime '../@data',
		o_tip varchar(10) '../@o_tip',
		o_fisa varchar(10) '../@o_fisa',
		o_data datetime '../@o_data',
		masina varchar(20) '../@masina',
		comanda varchar(20) '../@comanda',
		loc_de_munca varchar(20) '../@lm',
		comanda_benef_antet varchar(20) '../@comanda_benef',
		lm_benef_antet varchar(20) '../@lm_benef',
		tert_antet varchar(20) '../@tert',
		marca_antet varchar(20) '../@marca',
		marca_ajutor_antet varchar(20) '../@marca_ajutor',
		jurnal_antet varchar(20) '../@jurnal',
		
		--pozitii
		numar_pozitie int '@numar_pozitie',
		subtip varchar(2) '@subtip',
		interventie varchar(10) '@interventie',
		valoare float '@valoare',
		traseu varchar(20) '@traseu',
		tert char(13) '@tert',
		plecare varchar(50) '@plecare',
		data_plecarii datetime '@data_plecarii',
		ora_plecarii varchar(20) '@ora_plecarii',
		sosire varchar(20) '@sosire',
		data_sosirii datetime '@data_sosirii',
		ora_sosirii varchar(20) '@ora_sosirii',
		explicatii char(200) '@explicatii', 
		comanda_benef char(20) '@comanda_benef', 
		lm_benef char(20) '@lm_benef', 
		marca char(20) '@marca', 
		AlimComb float '@AlimComb',
		--TTransp float '@TTransp',
		--
		KmEf float '@KmEF',
		KmBord float '@KmBord',
		KmEchv float '@KmEchv',
		ConsComb float '@ConsComb',
		RestDecl float '@RestDecl',
		OREBORD float '@OREBORD',
		Curse float '@Curse'
		)
	
	open crsPozActivitati
	fetch next from crsPozActivitati into 
	@idActivitati, @tip, @fisa, @data, @o_tip, @o_fisa, @o_data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
	@marca_antet, @marca_ajutor_antet,	@jurnal_antet,@numar_pozitie, @subtip, @interventie,@valoare,@traseu, @tert, @plecare, 
	@data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
	@explicatii, @comanda_benef, @lm_benef, @marca,
	@AlimComb, @KmEf, @KmBord, @KmEchv, @ConsComb, @RestDecl, @OREBORD
	
	while @@fetch_status = 0
	begin
		if @idActivitati is null select @idActivitati=a.idActivitati from activitati a where a.Fisa=@fisa and a.Tip=@tip and a.data=@data
			/* scriu antet */
		select @o_tip=isnull(@o_tip,@tip), @o_fisa=isnull(@o_fisa,@fisa), @o_data=isnull(@o_data,@data)
		-- daca @fisa=null -> autoincrement
		if isnull(@fisa,'')=''
		begin
			 set @fisa = isnull( (select MAX(convert(int,fisa)) from activitati a where ISNUMERIC(fisa)=1) , 0) + 1
			 set @parXML.modify('replace value of (/row/@fisa)[1]	with sql:variable("@fisa")')
		end
		if ISNULL(@lm,'')=''
			set @lm=isnull((select loc_de_munca from masini where cod_masina=@masina),'')
		if exists (select 1 from activitati a inner join masini m on a.Masina=m.cod_masina where a.Fisa=@fisa and a.Tip=@tip and a.Masina<>@masina)
			raiserror('Acest numar de fisa este deja folosit pentru alta masina!',16,1)

		if not exists (select 1 from activitati a where idActivitati=@idActivitati
		)
		begin	
			INSERT INTO activitati (Tip,Fisa,Data,Masina,Comanda,Loc_de_munca,Comanda_benef,lm_benef,Tert,Marca,Marca_ajutor,Jurnal)
			select @tip,@fisa, @data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
			@marca_antet, @marca_ajutor_antet, @jurnal_antet
			select @idActivitati=IDENT_CURRENT('activitati')
		end
		else
			update activitati
			set Tip=@tip, Fisa=@fisa, Data=@data, Masina=@masina, Comanda=@comanda, Loc_de_munca=@lm, Comanda_benef=@comanda_benef_antet,
				lm_benef=@lm_benef_antet, Tert=@tert_antet, Marca=@marca_antet, Marca_ajutor=@marca_ajutor_antet, Jurnal=@jurnal_antet
			where idActivitati=@idActivitati
			

		/* iau nr. pozitie pt. pozitii noi (adica tot timpul, pt ca nu e permis update-ul)*/
		set @numar_pozitie=isnull((select max(Numar_pozitie) from pozactivitati
			where idActivitati=@idActivitati
			),0)+1
		/* scriu si numar pozitie in xml pt. scrierea elementelor in elemactivitati  */
		if @parXML.value('(/row/row/@numar_pozitie)[1]','int') is not null
			set @parXML.modify ('delete (/row/row/@numar_pozitie)[1]')
		set @parXML.modify ('insert attribute numar_pozitie {sql:variable("@numar_pozitie")} as last into (/row/row)[1]') 

			/* scriu pozitie */
		if @tip in ('FP', 'FL')
		begin
			INSERT INTO pozactivitati(Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, 
			Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, 
			Data_operarii, Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1, idActivitati
			)
			
			select @tip, @fisa, @data, @numar_pozitie, @traseu, @plecare, @data_plecarii, @ora_plecarii, @sosire, @data_sosirii,
				@ora_sosirii, @explicatii, @comanda_benef, @lm_benef, @tert, @marca, @userASiS,
				convert(datetime, convert(char(10), getdate(), 104), 104) as data_operarii, 
				rtrim(replace(convert(char(8), getdate(), 108), ':', '')) as ora_operarii,
				@subtip, @interventie, 0, 0, '01/01/1901', @idActivitati
		end		
		else
		if @tip='FI' and @subtip='FI'
		begin		   
			INSERT INTO pozactivitati(Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, 
			Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, 
			Data_operarii, Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1, idActivitati
			)
		
			select @tip, @fisa, @data, @numar_pozitie, @traseu, @plecare, @data_plecarii, @ora_plecarii, @sosire, @data_sosirii,
				@ora_sosirii, @explicatii, @comanda_benef, @lm_benef, @tert, @marca, @userASiS,
				convert(datetime, convert(char(10), getdate(), 104), 104) as data_operarii, 
				rtrim(replace(convert(char(8), getdate(), 108), ':', '')) as ora_operarii,
				@subtip, @interventie, isnull(@valoare,0), 0, '1901-1-1', @idActivitati
		end
		select @idPozActivitati=IDENT_CURRENT('pozactivitati')
		declare @tipActivitate varchar(1), @element varchar(20),
				@bordVechi decimal(15,2), @bordNou decimal(15,2), @bordDif decimal(15,2)
		select @tipActivitate=(
			select t.Tip_activitate from tipmasini t inner join grupemasini g on g.tip_masina=t.Cod
				inner join masini m on m.grupa=g.Grupa
			where cod_masina=@masina
			)
		--select @element=(case when @tipActivitate='L' then 'OREBORD' else 'Kmbord' end)
		--inlocuit cu selectul de mai jos
		select @element=cod
		from elemente
		where (@tipActivitate='L' and cod in ('OREBORD','ORENOU') or @tipActivitate<>'L' and cod in ('Kmbord'))
				--,@bordNou=(case when @tipACtivitate='L' then @OREBORD else @KmBord end)
		--> retin valoarea anterioara
		exec iaValoareElementMM @element=@element, @masina=@masina, @data=@data,
			@data_plecarii=@data_plecarii, @ora_plecarii=@ora_plecarii, @valoare=@bordVechi output
		/* scriu elemente pt. pozitie */
		exec wScriuElemActivitati @parXML, @idPozActivitati=@idPozActivitati
		--> retin valoarea curenta:
		--if (@bordNou is null)
		exec iaValoareElementMM @element=@element, @masina=@masina, @data=@data,
			@data_plecarii=@data_plecarii, @ora_plecarii=@ora_plecarii, @valoare=@bordNou output
		--> calculez diferenta:
		select @bordDif=@bordNou-@bordVechi
		--> folosesc diferenta la calculul valorilor operate in avans dar cronologic dupa linia curenta:
		exec updateElementeAnterioareMM @bordDif=@bordDif, @element=@element,
			@masina=@masina, @data=@data, @data_plecarii=@data_plecarii,
			@ora_plecarii=@ora_plecarii

		fetch next from crsPozActivitati into 
		@idactivitati, @tip, @fisa, @data, @o_tip, @o_fisa, @o_data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
		@marca_antet, @marca_ajutor_antet,	@jurnal_antet,@numar_pozitie, @subtip, @interventie, @valoare,
		@traseu, @tert, @plecare, 
		@data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
		@explicatii, @comanda_benef, @lm_benef, @marca,
		@AlimComb, @KmEf, @KmBord, @KmEchv, @ConsComb, @RestDecl, @OREBORD
	end
	
	declare @xmlNou xml	
	set @xmlNou = '<row tip="'+@tip+'" fisa="'+@fisa+'" data="'+convert(char(10), @data, 101)+'"/>'	
	exec wIaPozActivitati @sesiune=@sesiune, @parXML = @xmlNou
	
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	set @mesaj=ERROR_MESSAGE()
	if (@mesaj <>'')
		set @mesaj = ERROR_MESSAGE()+' (wScriuPozActivitati)'
end catch

declare @cursorStatus int
set @cursorStatus=(select top 1 is_open from sys.dm_exec_cursors(0) where name='crsPozActivitati' and session_id=@@SPID)
if @cursorStatus=1 
	close crsPozActivitati
if @cursorStatus is not null
	deallocate crsPozActivitati

begin try 
	exec sp_xml_removedocument @iDoc 
end try begin catch end catch

if (@mesaj <>'') raiserror(@mesaj, 11, 1)
--max caractere
