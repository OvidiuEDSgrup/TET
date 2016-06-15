--***
create procedure [dbo].[wScriuActivitati] @sesiune varchar(50),@parXML XML      
as      
declare @tip varchar(2), @fisa varchar(10), @data datetime, @masina varchar(20), 
	@comanda varchar(20), @lm varchar(9), @comanda_benef_antet varchar(20), @lm_benef_antet varchar(9),
	@tert_antet varchar(13), @marca_antet varchar(20), @marca_ajutor_antet varchar(20),
	@jurnal_antet varchar(20),
	@numar_pozitie int, @subtip varchar(2), @traseu varchar(20), @tert varchar(13), @plecare varchar(50), @data_plecarii datetime, 
	@ora_plecarii varchar(20), @sosire varchar(50), @data_sosirii datetime, @ora_sosirii varchar(20), 
	@explicatii varchar(200), @comanda_benef varchar(20), @lm_benef varchar(9), @marca varchar(9), @eroare xml , @userASiS varchar(20), @textExec nvarchar(max)
declare @elemTemp table (tip char(2), fisa varchar(30), data datetime, numar_pozitie int, element varchar(20), valoare float, tip_doc char(2), numar_doc varchar(20), data_doc datetime )

--BEGIN TRAN
begin try
		/* chem procedura care va scrie in XML elementele calculate. */
	if exists(select * from sysobjects where name='wCalcElemActivitati' and type='P')      
		exec wCalcElemActivitati @sesiune=@sesiune, @parXML = @parXML output
	else 
		raiserror('Procedura wCalcElemActivitati, folosita pentru elementele calculate, nu a fost gasita. 
		Configurati procedura folosind ca model procedura wCalcElemActivitatiModel.',11,1)

	set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')
	
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	/* citesc in cursor toate campurile statice din activitati si pozactivitati */
	declare crsPozActivitati cursor for
	select	--antet
	tip, fisa, data, isnull(masina,'') as masina, isnull(comanda,'') as comanda, 
	isnull(loc_de_munca,'') as loc_de_munca, isnull(comanda_benef_antet,'') as comanda_benef_antet,
	isnull(lm_benef_antet,'') as lm_benef_antet, isnull(tert_antet,'') as tert_antet, 
	isnull(marca_antet,'') as marca_antet, isnull(marca_ajutor_antet,'') marca_ajutor_antet, 
	isnull(jurnal_antet,'') as jurnal_antet,
			--pozitii
	numar_pozitie, subtip, isnull(traseu,'') as traseu, isnull(tert,'') as tert, isnull(plecare,'') as plecare,
	isnull(data_plecarii,'01/01/1901') as data_plecarii, isnull(ora_plecarii,'') as ora_plecarii,
	isnull(sosire,'') as sosire, isnull(data_sosirii,'01/01/1901') as data_sosirii,
	isnull(ora_sosirii,'') as ora_sosirii, isnull(explicatii,'') as explicatii,
	isnull(comanda_benef,'') as comanda_benef, isnull(lm_benef,'') as lm_benef, isnull(marca,'') as marca
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(	--antet
		tip varchar(10) '../@tip',
		fisa varchar(10) '../@fisa',
		data datetime '../@data',
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
		TTransp float '@TTransp',
		Curse float '@Curse')

	open crsPozActivitati
	fetch next from crsPozActivitati into 
	@tip, @fisa, @data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
	@marca_antet, @marca_ajutor_antet,	@jurnal_antet,@numar_pozitie, @subtip, @traseu, @tert, @plecare, 
	@data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
	@explicatii, @comanda_benef, @lm_benef, @marca
	
	while @@fetch_status = 0
	begin
			/* scriu antet */
		if not exists (select 1 from activitati a where a.Tip=@tip and a.Fisa=@fisa and a.Data=@data)
			INSERT INTO activitati (Tip,Fisa,Data,Masina,Comanda,Loc_de_munca,Comanda_benef,lm_benef,Tert,Marca,Marca_ajutor,Jurnal)
			select @tip,@fisa, @data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
			@marca_antet, @marca_ajutor_antet, @jurnal_antet

			/* iau nr. pozitie pt. pozitii noi */
		if isnull(@numar_pozitie,0)=0 
		begin
			set @numar_pozitie=isnull((select max(Numar_pozitie) from pozactivitati where tip=@tip and fisa=@fisa and Data=@data),0)+1
			update @elemTemp set numar_pozitie=@numar_pozitie where numar_pozitie = 0
			/* scriu si numar pozitie in xml pt. scrierea elementelor in elemactivitati  */
			if @parXML.exist('(/row/row/@numar_pozitie)[1]' ) = 1
				set @parXML.modify('replace value of (/row/row/@numar_pozitie)[1]	with sql:variable("@numar_pozitie")')
			else
				set @parXML.modify ('insert attribute numar_pozitie {sql:variable("@numar_pozitie")} as last into (/row/row)[1]') 
		end
		else	/* sterg pozitia existenta */
			delete from pozactivitati where tip=@tip and fisa=@fisa and Data=@data and Numar_pozitie=@numar_pozitie 
		
			/* scriu pozitie */
		INSERT INTO pozactivitati(Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, 
		Sosire, Data_sosirii, Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, 
		Data_operarii, Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1)
		
		select @tip, @fisa, @data, @numar_pozitie, @traseu, @plecare, @data_plecarii, @ora_plecarii, @sosire, @data_sosirii,
			@ora_sosirii, @explicatii, @comanda_benef, @lm_benef, @tert, @marca, @userASiS,
			convert(datetime, convert(char(10), getdate(), 104), 104) as data_operarii, 
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')) as ora_operarii,
			@subtip,'',0,0,'01/01/1901'
		
		/* scriu elemente pt. pozitie */
		exec wScriuElemActivitati @parXML,@tip, @fisa, @data, @numar_pozitie
					
		fetch next from crsPozActivitati into 
		@tip, @fisa, @data, @masina, @comanda, @lm, @comanda_benef_antet, @lm_benef_antet, @tert_antet, 
		@marca_antet, @marca_ajutor_antet,	@jurnal_antet,@numar_pozitie, @subtip, @traseu, @tert, @plecare, 
		@data_plecarii, @ora_plecarii, @sosire, @data_sosirii, @ora_sosirii, 
		@explicatii, @comanda_benef, @lm_benef, @marca
	end

	declare @xmlNou xml
	set @xmlNou = '<row tip="'+@tip+'" fisa="'+@fisa+'" data="'+convert(char(10), @data, 101)+'"/>'
	exec wIaPozActivitati @sesiune=@sesiune, @fltXML = @xmlNou
	--COMMIT TRAN
end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj = ERROR_MESSAGE() 
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch

IF OBJECT_ID('crsPozActivitati') IS NOT NULL
	begin
	close crspozdoc 
	deallocate crspozdoc 
	end

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
--max caractere
