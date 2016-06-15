--***
CREATE procedure calculDVI @sesiune varchar(50), @parXML xml
as  
Declare @tip char(2), @numarDVI varchar(13), @dataDVI datetime, @valuta_CIF varchar(3), @curs float, 
	@numar varchar(20), @data datetime, @suma_valuta_CIF float, @suma_ron_CIF float, @suma_ron_CIF_rep float, 
	@suma_vama float, @dif_vama float, @suma_comision float, @dif_com_vam float,  
	@val_fara_comis float,
	@utilizator varchar(20), @subunitate varchar(9), @TaxeVamaComisVamaGlobal int, @VAMAPOZ int, @mesaj varchar(250)
select
	/* date receptie*/
	@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
	@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),''),
	@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'),
	@numarDVI=isnull(@parXML.value('(/row/@numarDVI)[1]','varchar(13)'),''),
	@dataDVI=isnull(@parXML.value('(/row/@dataDVI)[1]','datetime'),'')

--begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	select @subunitate=val_alfanumerica from par where tip_parametru='GE' and parametru='SUBPRO'
	select @TaxeVamaComisVamaGlobal=Val_logica from par where tip_parametru='GE' and parametru='VAMGLOB'
	select @VAMAPOZ=Val_logica from par where tip_parametru='GE' and parametru='VAMAPOZ'

	/*	In conditiile setarii [X]Taxe vamale si comision calculate global, in CGplus, se culege suma taxelor vamale si se stocheaza in campul Dif_vama.
		Din acest motiv pentru a pastra noul mod de calcul, mutam la inceput de calcul in campul Suma_vama, suma introdusa in dif_vama, si consideram procent taxe vamale=10.
		La final punem in Dif_vama, suma_vama+dif_vama si suma_vama=0. Acelasi lucru si pentru comsionul vamal. */
	if @TaxeVamaComisVamaGlobal=1
		update dvi set Suma_vama=Dif_vama, Dif_vama=0, suma_com_vam=Dif_com_vam, Dif_com_vam=0
		where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar

	select @suma_vama=suma_vama+dif_vama, -- formez @suma_vama sa fie egala cu suma finala (compusa din valoarea din procente si diferenta).
		@suma_comision=suma_com_vam, @valuta_CIF=Valuta_CIF, @curs=Curs, @suma_ron_CIF=Valoare_CIF_lei, @suma_valuta_CIF=Valoare_CIF
	from dvi 
	where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar
	
	--daca se introduce cif in valuta calculam echivalentul in ron		
	if isnull(@suma_valuta_CIF,0)<>0 and isnull(@curs,0)<>0 and isnull(@valuta_CIF,'')<>''
		set @suma_ron_CIF=@suma_valuta_CIF*@curs	
	
	IF OBJECT_ID('tempdb..#pozRMDvi') IS NOT NULL
		DROP TABLE #pozRMDvi
	
	--tabela temporara cu pozitiile de RM
	select 
		p.idPozDoc,p.numar_DVI,
		isnull(detalii.value('(/*/@procent_vama)[1]','float'),procent_vama) as procent_vama, 
		convert(decimal(17,2),isnull(p.detalii.value('(/*/@taxe_vama)[1]','float'),p.TVA_deductibil)) as taxe_vama,
		convert(decimal(17,2),0) as taxe_din_proc, 
		p.Pret_amanunt_predator,p.Pret_vanzare,p.pret_de_stoc,p.Pret_valuta,
		isnull(p.detalii.value('(/*/@procent_comision)[1]','float'),p.Discount) as procent_comision, 
		convert(decimal(12,2),0) as comision_vamal, 
		p.Valuta,p.Curs,p.numar_pozitie,p.cantitate,p.cod, 
		p.Pret_valuta/**(1+p.Discount/100)*/*(case when isnull(p.Valuta,'')<>'' then p.Curs else 1 end) as pret_furnizor_ron,
		p.Pret_valuta/**(1+p.Discount/100)*/ as pret_furnizor_valuta,
		p.detalii detalii	
	into #pozRMDvi
	from pozdoc p
	where p.Subunitate=@subunitate
		and p.Numar=@Numar
		and p.Data=@Data
		and p.Tip='RM'	
	
	if @TaxeVamaComisVamaGlobal=1 or isnull(@VAMAPOZ,0)=0 and not exists (select 1 from #pozRMDvi where procent_vama>0)
		update #pozRMDvi set procent_vama=10
	if @TaxeVamaComisVamaGlobal=1 --or isnull(@VAMAPOZ,0)=0 and not exists (select 1 from #pozRMDvi where procent_comision>0)
		update #pozRMDvi set procent_comision=10

	-- s-a mutat aici calcul taxe din procent, pentru cazul initializarii procentului cu 10%
	update #pozRMDvi set 
		taxe_din_proc=convert(decimal(17,2),(cantitate*pret_furnizor_valuta*curs+Pret_vanzare)*procent_vama/100) 

	declare @valTotalaRM float
	--calculam valoarea totala a receptiei 
	select @valTotalaRM=sum(Cantitate*pret_furnizor_ron)
		from #pozRMDvi
	set @val_fara_comis=@suma_ron_CIF+@valTotalaRM

	if @valTotalaRM=0 and @suma_ron_CIF<>0
		raiserror('Nu se poate face repartizarea CIF-ului intrucat valoarea receptiei este egala cu 0. Completati Pret valuta cu o valoare diferita de 0 (ex. 0.000001)!',11,1)		
		
	--repartizare CIF pe pozitii rm
	update #pozRMDvi set
		--suma CIF ron calculata proportional pentru fiecare pozitie de receptie
		Pret_vanzare=((Cantitate*pret_furnizor_ron)*100/@valTotalaRM)/100*@suma_ron_CIF,
		
		--suma CIF valuta calculata proportional pentru fiecare pozitie de receptie	
		Pret_amanunt_predator=case when isnull(@valuta_CIF,'')<>'' then (((Cantitate*pret_furnizor_ron)*100/@valTotalaRM)/100*@suma_ron_CIF)/@curs else Pret_amanunt_predator end
	where @valTotalaRM<>0

	--corectez eventuale diferente rezultate din spargerea CIF-ului
	select @suma_ron_CIF_rep=sum(convert(decimal(12,2),pret_vanzare)) from #pozRMDvi
	update #pozRMDvi set pret_vanzare=pret_vanzare+@suma_ron_cif-@suma_ron_CIF_rep
	where idPozdoc in (select top 1 idPozdoc from #pozRMDvi order by idPozdoc desc)

	--repartizare taxe vamale
	set @dif_vama=0
	set @dif_com_vam=0
	if @VAMAPOZ=1--se culeg taxe vamale(sume) pentru fiecare pozitie de receptie in parte
	begin
		select @suma_vama=isnull(sum(taxe_vama),0) from #pozRMDvi
	end			
	else --se culege o suma globala de taxe vamale pe toata receptia care trebuie distibuita proportional valoric pe fiecare pozitie
	begin
		-- calcul taxe vamale din procent
		update p set --taxe_vama=convert(decimal(12,2),(((p.Cantitate*p.pret_furnizor_ron)+p.Pret_vanzare)*100 /(@valTotalaRM+@suma_ron_CIF))/100*(@suma_vama+@dif_vama))
			taxe_vama=taxe_din_proc
				from #pozRMDvi p
		--repartizare diferenta suma taxe vamale: proportional cu baza taxelor
		declare @vama_calc_din_procent float
		select @vama_calc_din_procent=sum(taxe_din_proc) from #pozRMDvi p
		set @dif_vama=convert(decimal(12,2),isnull(@suma_vama,0)-isnull(@vama_calc_din_procent,0))
		if @dif_vama<>0
		declare @sumarep decimal(12,2), @idPrimPozdoc int
		begin
			update p set --taxe_vama=convert(decimal(12,2),(((p.Cantitate*p.pret_furnizor_ron)+p.Pret_vanzare)*100 /(@valTotalaRM+@suma_ron_CIF))/100*(@suma_vama+@dif_vama))
				taxe_vama=taxe_vama+convert(decimal(12,2),p.taxe_vama*@dif_vama/(@vama_calc_din_procent))
					from #pozRMDvi p
					where (@valTotalaRM+@suma_ron_CIF)<>0 
						and @vama_calc_din_procent<>0
			-- eventuala diferenta de rotunjire se pune pe prima pozitie 
			select @sumarep=sum(taxe_vama) from #pozRMDvi
			if @sumarep<>@suma_vama
			begin
				select top 1 @idPrimPozdoc=idPozDoc from #pozRMDvi where taxe_vama>0
				update p set taxe_vama=taxe_vama+(@suma_vama-@sumarep)
					from #pozRMDvi p
					where idPozDoc=@idPrimPozdoc
			end
		end
		-- calcul comison vamal
		update #pozRMDvi set
			comision_vamal=convert(decimal(17,5),(cantitate*pret_furnizor_ron+taxe_vama)*(procent_comision/100.00))
		--repartizare diferenta suma taxe vamale: proportional cu baza taxelor
		declare @com_vam_calc_din_procent float
		select @com_vam_calc_din_procent=sum(comision_vamal) from #pozRMDvi p

		set @dif_com_vam=isnull(@suma_comision,0)-isnull(@com_vam_calc_din_procent,0)
		if @dif_com_vam<>0
		begin
			declare @valTotalaCuTaxe float
			--calculam valoarea totala a receptiei 
			select @valTotalaCuTaxe=sum(Cantitate*pret_furnizor_ron+taxe_vama)
				from #pozRMDvi
			update p set --taxe_vama=convert(decimal(12,2),(((p.Cantitate*p.pret_furnizor_ron)+p.Pret_vanzare)*100 /(@valTotalaRM+@suma_ron_CIF))/100*(@suma_vama+@dif_vama))
				comision_vamal=comision_vamal+convert(decimal(12,2),p.comision_vamal*@dif_com_vam/@com_vam_calc_din_procent)
					from #pozRMDvi p
					where @valTotalaCuTaxe<>0 
						and @com_vam_calc_din_procent<>0
			-- eventuala diferenta de rotunjire se pune pe prima pozitie 
			select @sumarep=sum(comision_vamal) from #pozRMDvi
			if @sumarep<>@suma_comision
			begin
				select top 1 @idPrimPozdoc=idPozDoc from #pozRMDvi where comision_vamal>0
				update p set comision_vamal=comision_vamal+(@suma_comision-@sumarep)
					from #pozRMDvi p
					where idPozDoc=@idPrimPozdoc
			end
		end

	end		

	-- totaluri DVI
	select @suma_vama=sum(taxe_vama) from #pozRMDvi
	select @suma_comision=sum(comision_vamal) from #pozRMDvi

	/* Pregatim detaliile XML care retin taxele de VAMA a.i sa nu stricam alte posibile atribute de acolo */
	update	#pozRMDvi
		set detalii='<row/>'
	where detalii IS NULL

	update #pozRMDvi
		set detalii.modify('delete (/row/@taxe_vama)[1]')

	update #pozRMDvi
		set detalii.modify('insert attribute taxe_vama {sql:column("taxe_vama")} into (/row)[1]')

	update p set 
		detalii=a.detalii,
		Pret_vanzare=convert(decimal(17,5),a.Pret_vanzare), -- Cif ron
		Pret_amanunt_predator=convert(decimal(17,5),a.Pret_amanunt_predator), --Cif valuta
		suprataxe_vama=comision_vamal, 
		TVA_deductibil=0 
	from pozdoc p
		inner join #pozRMDvi a on a.idPozDoc=p.idPozDoc
	where p.Subunitate=@subunitate
		and p.Numar=@Numar
		and p.Data=@Data
		and p.Tip='RM'	
	
	select @suma_vama=isnull(@suma_vama,0), @suma_comision=isnull(@suma_comision,0), @val_fara_comis=isnull(@val_fara_comis,0)
	update dvi set 
		/*date CIF*/ Valoare_CIF_lei=@suma_ron_CIF,
		/*date vama*/ Suma_vama=@suma_vama-@dif_vama, dif_vama=@dif_vama, suma_com_vam=@suma_comision-@dif_com_vam, dif_com_vam=@dif_com_vam, 
		val_fara_comis=@val_fara_comis+@suma_vama+@suma_comision-@dif_vama-@dif_com_vam, 
		/*tva vama */ Valoare_TVA=TVA_CIF+TVA_22
	where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar --and Data_receptiei=@data

	if @TaxeVamaComisVamaGlobal=1
		update dvi set Dif_vama=Suma_vama+Dif_vama, Suma_vama=0, dif_com_vam=suma_com_vam+dif_com_vam, suma_com_vam=0,
			val_fara_comis=@val_fara_comis
		where Subunitate=@subunitate and Numar_DVI=@numarDVI and Data_DVI=@dataDVI and Numar_receptie=@numar

--end try
--begin catch
--	set @mesaj ='(calculDVI:) '+ ERROR_MESSAGE()
--	raiserror(@mesaj, 11, 1)	
--end catch   
  
/*
sp_help dvi
select * from dvi
sp_help facturi
*/
