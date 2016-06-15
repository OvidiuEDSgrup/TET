--***
CREATE procedure wOPDVI @sesiune varchar(50),@parXML xml
as  
Declare @mesaj varchar(250), @tip char(2),@numarDVI varchar(13),@dataDVI datetime, @numar_receptie varchar(20), @data_receptie datetime,
	@tert_receptie varchar(13), @factura_CIF varchar(20),@data_CIF datetime, @tert_CIF varchar(13),@cont_CIF varchar(40),@valuta_CIF varchar(3),
	@curs float, @tert_vama varchar(13),@factura_vama varchar(20) ,@cont_tert_vama varchar(40),@cont_vama_taxe varchar(40), @scadenta_CIF datetime,
	@cont_com_vama varchar(40),@cont_factura_TVA varchar(40), @tva_vama float, @tip_TVA_vama int,@subunitate varchar(9), @utilizator varchar(20),
	@numar varchar(20), @data datetime, @tert varchar(13), @suma_valuta_CIF float, @suma_vama float, @VAMAPOZ int,@iDoc INT,@scadenta_vama datetime,
	@suma_ron_CIF float, @val_fara_comis float, @suma_com_vam float
select
	/* date receptie*/
	@tip=isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
	@numar=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(20)'),''),
	@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'1901-01-01'),
	@tert=isnull(@parXML.value('(/parametri/@tert)[1]','varchar(13)'),''),
	
	@numarDVI=isnull(@parXML.value('(/parametri/@numarDVI)[1]','varchar(13)'),''),
	@dataDVI=isnull(@parXML.value('(/parametri/@dataDVI)[1]','datetime'),''),
	@numar_receptie=isnull(@parXML.value('(/parametri/@numar_receptie)[1]','varchar(20)'),isnull(@parXML.value('(/parametri/@numar)[1]','varchar(20)'),'')),
	@data_receptie=isnull(@parXML.value('(/parametri/@data_receptie)[1]','datetime'),isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'')),
	@scadenta_CIF=isnull(@parXML.value('(/parametri/@data_comis)[1]','datetime'),''),
	@scadenta_vama=isnull(@parXML.value('(/parametri/@data_scad_fact_vama)[1]','datetime'),''),
	@tert_receptie=isnull(@parXML.value('(/parametri/@tert_receptie)[1]','varchar(13)'),isnull(@parXML.value('(/parametri/@tert)[1]','varchar(13)'),'')),
	@factura_CIF=isnull(@parXML.value('(/parametri/@factura_CIF)[1]','varchar(20)'),''),
	@data_CIF=isnull(@parXML.value('(/parametri/@data_CIF)[1]','datetime'),''),
	@tert_CIF=isnull(@parXML.value('(/parametri/@tert_CIF)[1]','varchar(13)'),''),
	@cont_CIF=isnull(@parXML.value('(/parametri/@cont_CIF)[1]','varchar(40)'),''),
	@valuta_CIF=isnull(@parXML.value('(/parametri/@valuta)[1]','varchar(3)'),''),
	@curs=isnull(@parXML.value('(/parametri/@curs)[1]','float'),0),
	@tert_vama=isnull(@parXML.value('(/parametri/@tert_vama)[1]','varchar(13)'),0),
	@factura_vama=isnull(@parXML.value('(/parametri/@factura_vama)[1]','varchar(20)'),''),
	@cont_tert_vama=isnull(@parXML.value('(/parametri/@cont_tert_vama)[1]','varchar(40)'),''),
	@cont_vama_taxe=isnull(@parXML.value('(/parametri/@cont_vama)[1]','varchar(40)'),''),
	@cont_com_vama=isnull(@parXML.value('(/parametri/@cont_com_vama)[1]','varchar(40)'),''),
	@cont_factura_TVA=isnull(@parXML.value('(/parametri/@cont_factura_TVA)[1]','varchar(40)'),''),
	@tva_vama=isnull(@parXML.value('(/parametri/@tva_vama)[1]','float'),0),
	@suma_valuta_CIF=isnull(@parXML.value('(/parametri/@suma_valuta_CIF)[1]','float'),0),
	@suma_ron_CIF=isnull(@parXML.value('(/parametri/@suma_ron_CIF)[1]','float'),0),
	@suma_vama=isnull(@parXML.value('(/parametri/@suma_vama)[1]','float'),0),
	@suma_com_vam=isnull(@parXML.value('(/parametri/@suma_com_vam)[1]','float'),0),
	--@dif_vama=isnull(@parXML.value('(/parametri/@dif_vama)[1]','float'),0),
	@tip_TVA_vama=isnull(@parXML.value('(/parametri/@tip_TVA_vama)[1]','int'),0)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'	
	select @VAMAPOZ=Val_logica from par where tip_parametru='GE' and parametru='VAMAPOZ'	
	
	--citire date din gridul de operatii
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	IF OBJECT_ID('tempdb..#xmlPozitiiDocument') IS NOT NULL
		DROP TABLE #xmlPozitiiDocument

--	apelez validarea pentru receptiile de mijloace fixe cu DVI pentru cazul in care s-a inceput amortizarea pentru acestea
	if exists (select 1 from sysobjects where [type]='P' and [name]='wValidareMFdinCG') 
		and exists (select 1 from pozdoc where Subunitate=@subunitate and Tip=@tip and Numar=@numar and Data=@data and subtip='MF')
		exec wValidareMFdinCG @sesiune, @parXML

	SELECT subunitate,tip,data,numar,numar_pozitie,ISNULL(idPozDoc,0) AS idPozDoc, cantitate, cod, pvaluta, isnull(taxe_vama,0) taxe_vama
	INTO #xmlPozitiiDocument
	FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
	WITH
	(
		taxe_vama FLOAT '@taxe_vama'
		,cantitate FLOAT '@cantitate'
		,subunitate VARCHAR(13) '@subunitate'
		,tip VARCHAR(2) '@tip'
		,data DATETIME '@data'
		,numar VARCHAR(20) '@numar'
		,numar_pozitie INT '@numar_pozitie'
		,idPozDoc INT '@idPozDoc'
		,cod varchar(20) '@cod'
		,pvaluta varchar(20) '@pvaluta'
		
	)
	EXEC sp_xml_removedocument @iDoc 		

	--validari
	if exists(select 1 from DVI where Subunitate=@subunitate and Numar_receptie=@numar_receptie	and Data_receptiei=@data_receptie and Tert_receptie=@tert_receptie)
		and not exists(select 1 from DVI where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar_receptie
			and Data_receptiei=@data_receptie)
		raiserror('Numarul si data DVI-ului nu pot fi modificate!',11,1)	
	
	if ISNULL(@numarDVI,'')=''
		raiserror ('Introduceti un numar de DVI!',11,1)
	
	IF OBJECT_ID('tempdb..#pozRM') IS NOT NULL
		DROP TABLE #pozRM
	
	--tabela temporara cu pozitiile de rm
	select 
		p.idPozDoc,p.numar_DVI,isnull(p.detalii.value('(/*/@taxe_vama)[1]','float'),p.TVA_deductibil) as taxe_vama,
		p.detalii detalii	
	into #pozRM
	from pozdoc p
	where p.Subunitate=@subunitate
		and p.Numar=@Numar
		and p.Data=@Data
		and p.Tip='RM'	
	
	--pun taxe vamale in #pozRM din #xmlPozitiiDocument
	if @VAMAPOZ=1--se culeg taxe vamale(sume) pentru fiecare pozitie de receptie in parte
	begin
		--update taxe vamale pentru fiecare pozitie in RM
		update p set taxe_vama=x.taxe_vama
		from #pozRM p
			inner join #xmlPozitiiDocument x on p.idPozDoc=x.idPozDoc		

		/* Pregatim detaliile XML care retin taxele de VAMA a.i sa nustricam alte posibile atribute de acolo */
		update	#pozRM
			set detalii='<row/>'
		where detalii IS NULL

		update #pozRM
			set detalii.modify('delete (/row/@taxe_vama)[1]')

		update #pozRM
			set detalii.modify('insert attribute taxe_vama {sql:column("taxe_vama")} into (/row)[1]')
	end	

	update p set 
		Numar_DVI=(case when ISNULL(left(p.Numar_DVI,13),'')='' then convert(char(13),left(@numarDVI,13))+RIGHT(p.Numar_DVI,12) else p.Numar_DVI end),
		p.detalii=a.detalii
	from pozdoc p
		inner join #pozRM a on a.idPozDoc=p.idPozDoc
	where p.Subunitate=@subunitate
		and p.Numar=@Numar
		and p.Data=@Data
		and p.Tip='RM'	

	--setat numarul de dvi si in doc
	update doc set Numar_DVI=(case when ISNULL(left(Numar_DVI,13),'')='' then convert(char(13),left(@numarDVI,13))+RIGHT(Numar_DVI,12) else Numar_DVI end)
	where Subunitate=@subunitate
		and Tip='RM'
		and Data=@data_receptie
		and Numar=@numar_receptie	
			
	if exists(select 1 from DVI where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar_receptie
		and Data_receptiei=@data_receptie)
	begin  				
		update dvi set 
			/*date CIF*/ Tert_CIF=@tert_CIF, Factura_CIF=@factura_CIF, Data_CIF=@data_CIF, Data_comis=@scadenta_CIF, Cont_CIF=@cont_CIF,
				Valoare_CIF=@suma_valuta_CIF,Valoare_CIF_lei=@suma_ron_CIF,
			/*date vama*/ Tert_vama=@tert_vama, Factura_vama=@factura_vama, Cont_tert_vama=@cont_tert_vama, Cont_vama=@cont_vama_taxe,
				Cont_com_vam=@cont_com_vama, Factura_TVA=@factura_vama, Cont_factura_TVA=@cont_factura_TVA, TVA_22=@tva_vama, Valoare_TVA=@tva_vama, 
				Total_vama=@tip_TVA_vama,--camp refolosit
				Suma_vama=@suma_vama,Suma_com_vam=@suma_com_vam,Tert_comis=CONVERT(char(10),@scadenta_vama,103), 
				val_fara_comis=isnull(@val_fara_comis,0)+@suma_vama
		where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI 
			and Numar_receptie=@numar_receptie
			and Data_receptiei=@data_receptie
	end  
	else   
	begin  
		--inserare in dvi datele necesare
		INSERT INTO DVI  ([Subunitate],[Numar_DVI],[Data_DVI],[Numar_receptie] ,[Data_receptiei],[Tert_receptie],[Valoare_fara_CIF],[Factura_CIF],[Data_CIF]
           ,[Tert_CIF],[Cont_CIF],[Procent_CIF],[Valoare_CIF],[Valuta_CIF],[Curs],[Valoare_CIF_lei],[TVA_CIF],[Total_vama],[Tert_vama],[Factura_vama]
           ,[Cont_vama],[Suma_vama],[Cont_suprataxe],[Suma_suprataxe],[TVA_22],[TVA_11],[Val_fara_comis],[Tert_comis],[Factura_comis],[Data_comis]
           ,[Cont_comis],[Valoare_comis],[TVA_comis],[Valoare_intrare],[Valoare_TVA],[Valoare_accize],[Cont_tert_vama],[Factura_TVA],[Cont_factura_TVA]
           ,[Cont_vama_suprataxe],[Cont_com_vam],[Suma_com_vam],[Dif_vama],[Dif_com_vam],[Utilizator],[Data_operarii],[Ora_operarii])
		VALUES
           (@subunitate,@numarDVI,convert(varchar(10),@dataDVI,101),@numar,convert(varchar(10),@data,101),@tert,0,@factura_CIF,convert(varchar(10),@data_CIF,101)
           ,@tert_CIF,@cont_CIF,0,@suma_valuta_CIF,@valuta_CIF,@curs,@suma_ron_CIF,0,@tip_TVA_vama,@tert_vama, @factura_vama
           ,@cont_vama_taxe,@suma_vama,'',0,@tva_vama,0,isnull(@val_fara_comis,0)+@suma_vama,CONVERT(char(10),@scadenta_vama,103),'D',convert(varchar(10),@scadenta_CIF,101)
           ,'',0,0,0/*valoare intrare*/,@tva_vama,0,@cont_tert_vama,@factura_vama,@cont_factura_TVA
           ,'',@cont_com_vama,@suma_com_vam,0,0,@utilizator,convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')))
           
  	end  
  
	--	inainte de calcul, pun dif_vama=0 pentru a se determina in procedura de calcul si sa nu tina cont de ea.
	update DVI set Dif_vama=0
	where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI 
			and Numar_receptie=@numar_receptie
	--	apelare procedura pentru calcul dvi 
	declare @parXMLC xml
	set @parXMLC=(select @tip as tip, @numar as numar, @data as data, @numarDVI as numarDVI, @dataDVI as dataDVI for xml raw)
	exec calculDVI @sesiune=@sesiune, @parXML=@parXMLC

   	--apelare procedura pentru repartizare dvi in pret de stoc
	exec repartizarePrestariReceptii 'RM', @numar, @data
end try
begin catch
	set @mesaj ='(wOPDVI:) '+ ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch   
  
/*
sp_help dvi
select * from dvi
sp_help facturi
*/
