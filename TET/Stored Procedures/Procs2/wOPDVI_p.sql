
CREATE procedure wOPDVI_p @sesiune varchar(50), @parXML xml
as  
begin try  
	declare @numar_receptie varchar(20), @data_receptie datetime, @tert_receptie varchar(13), @subunitate varchar(9), @numar_DVI varchar(13),
		@mesaj varchar(250), @valuta_CIF varchar(3), @VAMAPOZ bit, @suma_vama_total float, @taxe_vama float

	select @numar_receptie=isnull(isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),@parXML.value('(/row/*/@numar)[1]','varchar(20)')),''),
		@data_receptie=isnull(isnull(@parXML.value('(/row/@data)[1]','datetime'),@parXML.value('(/row/*/@data)[1]','datetime')),'1901-01-01'),
		@tert_receptie=isnull(isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),@parXML.value('(/row/*/@tert)[1]','varchar(13)')),''),
		@numar_DVI=isnull(isnull(@parXML.value('(/row/@numardvi)[1]','varchar(20)'),@parXML.value('(/row/*/@numardvi)[1]','varchar(20)')),''),
		@valuta_CIF=isnull(isnull(@parXML.value('(/row/@valuta)[1]','varchar(3)'),@parXML.value('(/row/*/@valuta)[1]','varchar(3)')),'')

	
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'	

	if @tert_receptie=''
		select top 1 @tert_receptie=rtrim(tert) from pozdoc 
		where subunitate=@subunitate and tip='RM' and numar=@numar_receptie and data=@data_receptie and isnull(Numar_DVI,'')<>''  
		
	select @VAMAPOZ=Val_logica from par where tip_parametru='GE' and parametru='VAMAPOZ'
	if isnull(@VAMAPOZ,0)=0 and exists (select 1 from webconfiggrid where meniu='DO' and tip='RM' and subtip='DV' and DataField='@taxe_vama' and modificabil=1)
		raiserror('Configurarea machetei permite completare taxe vamale pe pozitie, dar setarea "VAMAPOZ" ignora acest lucru!',11,1)	
	
	if exists (select 1 from doc where Subunitate=@subunitate and tip='RM' and Numar=@numar_receptie and data=@data_receptie and (ISNULL(valuta,'')='' or ISNULL(curs,0)=0))
		raiserror('Nu se poate opera DVI pe o receptie daca nu au fost specificate cursul si valuta!',11,1)	
		
	if exists(select 1 from terti where tert=@tert_receptie and Tert_extern<>1)
		raiserror('Pentru a se opera DVI este nevoie ca tertul de pe receptie sa fie tert extern si cu decontari in valuta!',11,1) 
	
	--Calculez si pun suma_taxe_vamale (pozdoc.TVA_deductibil) din procent_vama (eventual completat pe pozitii):

	/* Pregatim scrierea in detalii a taxelor de vama, dar avem grija ca s-ar putea sa fie si alte atribute in detalii*/
	IF OBJECT_ID('tempdb..#pozRMDvi') IS NOT NULL
		DROP TABLE #pozRMDvi

	select 
		p.*,
		-- valoare implicita pentru taxe vamale din procent 
		CONVERT(DECIMAL(17, 2), isnull(p.detalii.value('(/*/@taxe_vama)[1]','float'),p.TVA_deductibil)) as taxe_vama, 
		convert(decimal(12,2),suprataxe_vama) as comision_vamal 
	into #pozRMDvi
	from pozdoc p
	where p.Subunitate=@subunitate
		and p.Tip='RM' and p.Numar=@numar_receptie and p.Data=@data_receptie --and p.Numar_DVI<>'' eliminat aceasta conditie pentru a se popula gridul si la prima intrare in macheta de DVI.

	-- valoare implicita pentru taxe vamale din procent 
	update #pozRMDvi 
		set taxe_vama=convert(decimal(17,2),(cantitate*pret_valuta*curs+Pret_vanzare)*isnull(detalii.value('(/*/@procent_vama)[1]','float'),procent_vama)/100)  
	where isnull(detalii.value('(/*/@procent_vama)[1]','float'),procent_vama)>0 
			and taxe_vama=0 --<>convert(decimal(17,2),(cantitate*pret_valuta*curs+Pret_vanzare)*isnull(detalii.value('(/*/@procent_vama)[1]','float'),procent_vama)/100)

	-- valoare implicita pentru comision vamal din procent 
	update #pozRMDvi 
		set comision_vamal=convert(decimal(17,5),(cantitate*Pret_valuta/**(1+p.Discount/100)*/*(case when isnull(Valuta,'')<>'' then Curs else 1 end)+taxe_vama)*(isnull(detalii.value('(/*/@procent_comision)[1]','float'),Discount)/100.00))
	where isnull(detalii.value('(/*/@procent_comision)[1]','float'),Discount)>0 
			and comision_vamal=0 

	--update #pozRMDvi set detalii='<row/>'
	--where detalii is null

	--update #pozRMDvi
	--	set detalii.modify('delete (/row/@taxe_vama)[1]')

	--update #pozRMDvi
	--	set detalii.modify('insert attribute taxe_vama {sql:column("taxe_vama")} into (/row)[1]')

	--update p set detalii=pd.detalii
	--from pozdoc p
	--	inner join #pozRMDvi pd on pd.idPozdoc=p.idPozdoc


	--daca se lucreaza cu introducerea taxei vamale pentru fiecare pozitie in parte, atunci suma totala a taxei= suma taxelor din pozdoc 
	if @VAMAPOZ=1
		select @suma_vama_total= SUM(isnull(detalii.value('(/*/@taxe_vama)[1]','float'),TVA_deductibil)) 
		from pozdoc 
		where Subunitate=@subunitate and tip='RM' 
			and Numar=@numar_receptie and data=@data_receptie 
			and tert=@tert_receptie 
			and isnull(Numar_DVI,'')<>''  

	--date DVI pt antet operatie
	select top 100 RTRIM(Numar_DVI) as numarDVI, CONVERT(char(10),data_dvi,101) as dataDVI, RTRIM(Numar_receptie) as numar_receptie,
		CONVERT(char(10),data_receptiei,101)as data_receptie, RTRIM(Tert_receptie) as tert_receptie,CONVERT(decimal(12,2),Valoare_fara_CIF) as val_fara_CIF,
		RTRIM(Factura_CIF) as factura_CIF, CONVERT(char(10),data_cif,101) as data_CIF, RTRIM(Tert_CIF) as tert_CIF, RTRIM(Cont_CIF) as cont_CIF,
		convert(decimal(12,2),Procent_CIF) as procent_CIF, CONVERT(decimal(12,2),Valoare_CIF) as suma_valuta_CIF, 
		RTRIM(Valuta_CIF) as valuta, convert(decimal(12,5),curs) as curs, CONVERT(decimal(12,2),Valoare_CIF_lei) as suma_ron_CIF, 
		CONVERT(decimal(12,2),Valoare_CIF_lei) as valoare_CIF_lei,CONVERT(decimal(12,2),tva_CIF) as tva_CIF,convert(decimal(12,2),Total_vama) as total_vama,
		rtrim(Factura_vama) as factura_vama,RTRIM(cont_vama)as cont_vama, case when @VAMAPOZ=1 then CONVERT(decimal(12,2),@suma_vama_total) else  CONVERT(decimal(12,2),Suma_vama) end as suma_vama,
		RTRIM(Cont_suprataxe) as cont_suprataxe, CONVERT(decimal(12,2),Suma_suprataxe) as suma_suprataxe,
		convert(decimal(12,2),TVA_22) as tva_vama, convert(decimal(12,2),TVA_11) as tva_11, 
		convert(decimal(12,2),Val_fara_comis) as val_fara_comis,
		CONVERT(char(10),data_receptiei,101)as data_factura_vama,  
		convert(char(10),CONVERT(datetime,rtrim(Tert_comis),104),101) as data_scad_fact_vama,
		RTRIM(Factura_comis) as factura_comis, CONVERT(char(10),data_comis,101) as data_comis, rtrim(Cont_comis) as cont_comis,
		convert(decimal(12,2),Valoare_comis) as valoare_comis,convert(decimal(12,2),TVA_comis) as tva_comis,
		convert(decimal(12,2),Valoare_intrare) as valoare_intrare,convert(decimal(12,2),Valoare_TVA) as valoare_TVA,
		convert(decimal(12,2),Valoare_accize) as valoare_accize, RTRIM(Cont_tert_vama) as cont_tert_vama,RTRIM(d.Tert_vama) as tert_vama,
		RTRIM(Factura_TVA) as factura_TVA, RTRIM(Cont_factura_TVA) as cont_factura_TVA,RTRIM(Cont_vama_suprataxe ) as cont_vama_suprataxe,
		RTRIM(Cont_com_vam) as cont_com_vama, convert(decimal(12,2),Suma_com_vam) as suma_com_vam,convert(decimal(12,2),Dif_vama) as dif_vama,convert(decimal(12,2),0) as vama_calc,
		convert(decimal(12,2), dif_com_vam) as dif_com_vam,
		RTRIM(t_Cif.Denumire) as dentert_CIF, rtrim(t_vama.Denumire) as dentert_vama ,
		@numar_receptie as numar, CONVERT(varchar(10),@data_receptie,101) as data      
	into #antet
	from dvi d
		left join terti t_Cif on t_Cif.Tert=Tert_CIF
		left join terti t_vama on t_vama.Tert=Tert_vama 
	where d.Subunitate=@subunitate
		--and Numar_DVI=@numar_DVI
		and Numar_receptie=@numar_receptie
		--and Data_receptiei=@data_receptie -> data_receptiei este refolosit pentru data factura vama
		and Tert_receptie=@tert_receptie
	order by convert(datetime,Data_DVI) desc 
	
	update #antet set vama_calc=suma_vama

	update #antet set suma_vama=(select sum(taxe_vama) from #pozRMDvi )

	update #antet set suma_com_vam=(select sum(comision_vamal) from #pozRMDvi )

	if exists(select 1 from #antet)
		select * from #antet
		FOR XML RAW, ROOT('Date')
	else
		select CONVERT(char(10),@data_receptie,101) as dataDVI, @tert_receptie as tert_CIF, CONVERT(char(10),@data_receptie,101) as data_CIF,
			(select rtrim(denumire) from terti where tert=@tert_receptie)as dentert_CIF
		FOR XML RAW, ROOT('Date')
		
		
	--pozitii receptie, populare grid operatie
	SELECT p.tip AS tip,CONVERT(CHAR(10),p.data,101) AS data,RTRIM(p.subunitate) AS subunitate
			,RTRIM(p.numar) AS numar, p.Numar_pozitie AS numar_pozitie
			,RTRIM(p.cod) AS cod, CONVERT(DECIMAL(17,5),p.Cantitate) AS cantitate
			,CONVERT(DECIMAL(17,5),p.pret_valuta) AS pvaluta
			,CONVERT(DECIMAL(17, 3), p.cantitate*p.pret_valuta) AS valvaluta 
			,CONVERT(DECIMAL(17, 3), p.cantitate*p.Pret_de_stoc) AS valstoc 
			,CONVERT(DECIMAL(17, 5), p.pret_de_stoc) AS pstoc, CONVERT(DECIMAL(17, 5), p.pret_vanzare) AS pvanzare   
			,CONVERT(DECIMAL(17, 5), p.pret_cu_amanuntul) AS pamanunt, CONVERT(DECIMAL(5, 2), p.cota_tva) AS cotatva   
			,CONVERT(DECIMAL(17, 2), p.TVA_deductibil) AS sumatva, RTRIM(n.Denumire) AS dencod,RTRIM(p.Cod_intrare) AS cod_intrare
			,p.idPozDoc, 
			(case when isnull(left(p.Numar_DVI,13),'')<>'' then CONVERT(DECIMAL(17, 2), pd.taxe_vama) end) as taxe_vama, 
			(case when isnull(left(p.Numar_DVI,13),'')<>'' then CONVERT(DECIMAL(17, 2), pd.comision_vamal) end) as comision_vamal
		INTO #pozitiiDoc		
		FROM pozdoc p 
			inner join #pozRMDvi pd on pd.idPozdoc=p.idPozdoc
			LEFT JOIN nomencl n ON n.Cod=p.Cod
		WHERE p.Subunitate=@subunitate AND p.tip='RM'
			AND p.data=@data_receptie AND p.Numar=@numar_receptie

	SELECT (   
			SELECT * 
			FROM  #pozitiiDoc		
			FOR XML RAW, TYPE  
		  )  
		FOR XML PATH('DateGrid'), ROOT('Mesaje')	
end	try
begin catch
	set @mesaj ='(wOPDVI_p:) '+ ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	raiserror(@mesaj, 11, 1)	
end catch		


/*
select * from dvi where numar_dvi='DVIT1'
select * from pozdoc where numar='TESTDVI'
sp_help dvi
*/


