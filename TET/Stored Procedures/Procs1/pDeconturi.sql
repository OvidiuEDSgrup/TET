--***
create procedure pDeconturi @sesiune varchar(50), @parXML xml
as 
begin try

	declare @dDataJos datetime, @dDataSus datetime, @cMarca char(6), @cDecont varchar(40), @cCont varchar(40), @PtRulaj int, @PtFisa int, 
		@Sb char(9), @Bugetari int, @dDataImpl datetime, @nAnImpl int, @nLunaImpl int, @dDataJosDoc datetime, @DecRest int, @GrMarcaCont int, @RestitCaAchit int, @CuContVenDF int, 
		@ContVenDF varchar(40), @cen int, @GrMarca int, @GrDec int, @tabela_fltdec int, @indicator varchar(100)

	select @dDataJos=@parXML.value('(row/@datajos)[1]','datetime')
		,@dDataSus=@parXML.value('(row/@datasus)[1]','datetime')
		,@cMarca=@parXML.value('(row/@marca)[1]','varchar(20)')
		,@cDecont=@parXML.value('(row/@decont)[1]','varchar(40)')
		,@cCont=@parXML.value('(row/@cont)[1]','varchar(40)')
		,@PtRulaj=@parXML.value('(row/@ptrulaj)[1]','int')
		,@PtFisa=@parXML.value('(row/@ptfisa)[1]','int')
		,@cen=@parXML.value('(row/@cen)[1]','int')
		,@GrMarca=@parXML.value('(row/@grmarca)[1]','int')
		,@GrDec=@parXML.value('(row/@grdec)[1]','int')
		,@indicator=@parXML.value('(row/@indicator)[1]','varchar(100)')+'%'

	set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
	set @Bugetari=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='BUGETARI'),0)
	set @nAnImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULIMPL'), 1901)
	set @nLunaImpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAIMPL'), 1)
	set @dDataImpl=dateadd(month, @nLunaImpl, dateadd(year, @nAnImpl-1901, '01/01/1901'))
	set @DecRest=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DECREST'), 0)
	set @GrMarcaCont=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='DECMARCT'), 0)
	set @CuContVenDF=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='CTVENDF'), 0)
	set @ContVenDF=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='CTVENDF'), '')
	if @dDataJos is null set @dDataJos = '01/01/1901'
	if @dDataSus is null set @dDataSus = '12/31/2999'
	if @PtRulaj is null set @PtRulaj = 0
	if @PtFisa is null set @PtFisa = 0

	set @RestitCaAchit = @DecRest + @PtFisa
	if @RestitCaAchit > 1 set @RestitCaAchit = 1

	if @PtRulaj = 1
		set @dDataJosDoc = @dDataJos
	else
		set @dDataJosDoc = @dDataImpl
	
			/**	Pregatire filtrare pe proprietati utilizatori*/
	declare @userASiS varchar(10)
	select @userASiS=dbo.fIaUtilizator(@sesiune)

	/*	introduc tabela #fltdec pentru a putea filtra documentele pentru calculul soldului initial la apelul procedurii dinspre wIaPlin (vechea functie dbo.solddec) */
	IF OBJECT_ID('tempdb..#fltdec') IS NULL
	begin
		CREATE TABLE #fltdec (data datetime, marca varchar(6), decont varchar(40), cont varchar(40))
		set @tabela_fltdec=0
	end
	else
		set @tabela_fltdec=1

	if object_id('tempdb..#docdec') is not null
		drop table #docdec
	create table #docdec (subunitate varchar(9))
	exec CreazaDiezDeconturi @numeTabela='#docdec'

	insert #docdec (subunitate, marca, decont, tip_document, numar_document, data, in_perioada, valoare, achitat, cont, cont_coresp, fel, valuta, curs, valoare_valuta, achitat_valuta, tert, factura, 
			explicatii, numar_pozitie, loc_de_munca, comanda, data_scadentei, cantitate, debit_credit, idPozitieDoc, tabela)
	select d.subunitate, left(d.marca, 6), rtrim(d.decont) as decont, 'SI' as tip_document, d.decont as numar_document, d.data, (case when d.data between @dDataJos and @dDataSus then '2' else '1' end) as in_perioada, 
		d.valoare, d.decontat, d.cont, '' as cont_coresp, '1' as fel, d.valuta, d.curs, d.valoare_valuta, d.decontat_valuta, 
		'' as tert, '' as factura, 'Sold initial' as explicatii, 0 as numar_pozitie, d.loc_de_munca, d.comanda, d.data_scadentei, 0 as cantitate, 'D' as debit_credit, 0 as idPozitieDoc, 'decimpl' as tabela
	from decimpl d 
		left join lmfiltrare pr on pr.cod=loc_de_munca and pr.utilizator=@userASiS
		left join #fltdec fd on fd.Marca=d.Marca and fd.decont=d.decont and fd.Cont=d.Cont
	where d.subunitate=@Sb and d.tip='T' and @PtRulaj = 0 and d.data<=@dDataSus 
		and (isnull(@cMarca, '')='' or d.marca=@cMarca) and (isnull(@cDecont, '')='' or d.decont=@cDecont) and (isnull(@cCont, '')='' or d.cont like rtrim(@cCont)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)
		and (@tabela_fltdec=0 or fd.decont is not null and d.Data<=fd.data)

	union all 
	select a.subunitate, left(a.marca, 6), (case when @GrMarcaCont=1 then a.cont_corespondent else rtrim(a.decont) end), a.plata_incasare, left(a.numar,20), a.data, 
		(case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
		(case when a.plata_incasare='ID' then (case when @RestitCaAchit=1 then 0 else -a.suma end) else a.suma end), (case when a.plata_incasare='ID' and @RestitCaAchit=1 then a.suma else 0 end), 
		a.cont_corespondent, a.cont, '3', a.valuta, a.curs, 
		(case when a.plata_incasare='ID' then (case when @RestitCaAchit=1 then 0 else -a.suma_valuta end) else a.suma_valuta end), (case when a.plata_incasare='ID' and @RestitCaAchit=1 then a.suma_valuta else 0 end), 
		a.tert, a.factura, isnull(nullif(a.detalii.value('(/row/@explicatii)[1]','varchar(100)'),''),a.explicatii), a.numar_pozitie, a.loc_de_munca, a.comanda, 
		isnull(a.detalii.value('(/row/@datascad)[1]','datetime'), a.data), 
		isnull(a.detalii.value('(/row/@cantitate)[1]','decimal(12,2)'), 0) as cantitate, (case when a.plata_incasare='ID' and @RestitCaAchit=1 then 'C' else 'D' end), 
		idPozplin as idPozitieDoc, 'pozplin' as tabela
	from pozplin a
		left outer join conturi c on a.subunitate=c.subunitate and a.cont_corespondent=c.cont
		left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
		left join #fltdec fd on fd.Marca=a.Marca and fd.decont=(case when @GrMarcaCont=1 then a.cont_corespondent else rtrim(a.decont) end) and fd.Cont=a.cont_corespondent
	where a.subunitate=@Sb and isnull(c.sold_credit, 0) = 9 and a.data between @dDataJosDoc and @dDataSus
		and (isnull(@cMarca, '')='' or a.marca=@cMarca) and (isnull(@cDecont, '')='' or (case when @GrMarcaCont=1 then a.cont_corespondent else a.decont end)=@cDecont) 
		and (isnull(@cCont, '')='' or a.cont_corespondent like rtrim(@cCont)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)
		and (@tabela_fltdec=0 or fd.decont is not null and a.Data<=fd.data)

	union all 
	select a.subunitate, left(a.marca, 6), (case when @GrMarcaCont=1 then a.cont else rtrim(a.decont) end), a.plata_incasare, left(a.numar,20), a.data, 
		(case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
		(case when left(a.plata_incasare, 1)='I' then a.suma else 0 end), (case when left(a.plata_incasare, 1)='I' then 0 when left(a.plata_incasare, 1)='P' then 1 else -1 end)*a.suma
			-isnull(a.detalii.value('(/row/@_difcursdec)[1]','float'),0), 
		a.cont, a.cont_corespondent, '4', a.valuta, a.curs, 
		(case when left(a.plata_incasare, 1)='I' then a.suma_valuta else 0 end), (case when left(a.plata_incasare, 1)='I' then 0 when left(a.plata_incasare, 1)='P' then 1 else -1 end)*a.suma_valuta, 
		a.tert, a.factura, isnull(nullif(a.detalii.value('(/row/@explicatii)[1]','varchar(100)'),''),a.explicatii), a.numar_pozitie, a.loc_de_munca, a.comanda, 
		isnull(a.detalii.value('(/row/@datascad)[1]','datetime'), a.data), 
		isnull(a.detalii.value('(/row/@cantitate)[1]','decimal(12,2)'), 0) as cantitate, 'C',
		idPozplin as idPozitieDoc, 'pozplin' as tabela
	from pozplin a
		left outer join conturi c on a.subunitate=c.subunitate and a.cont=c.cont
		left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
		left join #fltdec fd on fd.Marca=a.Marca and fd.decont=(case when @GrMarcaCont=1 then a.cont else rtrim(a.decont) end) and fd.Cont=a.cont
	where a.subunitate=@Sb and isnull(c.sold_credit, 0) = 9 and a.data between @dDataJosDoc and @dDataSus 
		and (isnull(@cMarca, '')='' or a.marca=@cMarca) and (isnull(@cDecont, '')='' or (case when @GrMarcaCont=1 then a.cont else a.decont end)=@cDecont) 
		and (isnull(@cCont, '')='' or a.cont like rtrim(@cCont)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)
		and (@tabela_fltdec=0 or fd.decont is not null and a.Data<=fd.data)

	union all
	select a.subunitate, left(a.gestiune_primitoare,6), a.tert, a.tip, a.numar, a.data, (case when a.data between @dDataJos and @dDataSus then '2' else '1' end), 
		round(convert(decimal(15, 5), a.cantitate*a.pret_de_stoc*a.procent_vama/100*(1+a.cota_TVA/100)), 2), 0, 
		a.cont_factura, (case when @CuContVenDF=1 then @ContVenDF else a.cont_de_stoc end), '2', 
		a.valuta, a.curs, 0, 0, '', '', '', a.numar_pozitie, a.loc_de_munca, a.comanda, a.data, a.cantitate, 'D',
		idPozdoc as idPozitieDoc, 'pozdoc' as tabela
	from pozdoc a
		inner join conturi c on c.subunitate=a.subunitate and c.cont=a.cont_factura
		left join lmfiltrare pr on pr.cod=a.loc_de_munca and pr.utilizator=@userASiS
		left join #fltdec fd on fd.Marca=left(a.gestiune_primitoare,6) and fd.decont=a.tert and fd.Cont=a.cont_factura
	where a.subunitate=@Sb and a.tip='DF' and c.sold_credit=9 and a.tert<>'' and a.procent_vama<>0
		and (isnull(@cMarca, '')='' or left(a.gestiune_primitoare, 6)=@cMarca) 
		and (isnull(@cDecont, '')='' or a.tert=@cDecont) 
		and (isnull(@cCont, '')='' or a.cont_factura like rtrim(@cCont)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or pr.utilizator=@userASiS)
		and (@tabela_fltdec=0 or fd.decont is not null and a.Data<=fd.data)

	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select 'F' as furn_benef, tabela, idPozitieDoc, indbug into #indbugPozitieDoc from #docdec
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML

		update dd set dd.indbug=ib.indbug, dd.comanda=isnull(left(dd.comanda,20)+ib.indbug,dd.comanda)
		from #docdec dd
			left outer join #indbugPozitieDoc ib on ib.tabela=dd.tabela and ib.idPozitieDoc=dd.idPozitieDoc

		update #docdec set indbug=(case when tabela='decimpl' then substring(comanda,21,20) else '' end) where indbug is null

		if (@indicator<>'%') delete #docdec where indbug not like @indicator
	end

	if @cen=1
	begin
		if @GrMarca is null set @GrMarca = 1  
		if @GrDec is null set @GrDec = 1  

		if object_id('tempdb..#tmpdocdec') is not null 
			drop table #tmpdocdec
		select subunitate,marca,decont,tip_document, numar_document, data, in_perioada, valoare, achitat, cont, cont_coresp, fel, valuta,   
		curs, valoare_valuta, achitat_valuta, tert, factura, explicatii,numar_pozitie, loc_de_munca, comanda, data_scadentei, cantitate, debit_credit,   
		subunitate+/*tip_document+*/marca+decont as grp, 
		(case when tip_document in ('PD') then '0' else '1' end)+convert(char(8),data,112)+str(numar_pozitie) as ordine,  
		(case when valuta<>'' and curs<>0 then '2' when valuta<>'' then '1' else '0' end)+(case when tip_document='PD' and fel=3 then '1' else '0' end)+convert(char(8),data,112)+str(numar_pozitie) as ordine_valuta,  
		convert(datetime,'01/01/2999',101) dataDec, convert(varchar(3),'') valutaDec, convert(float,0) as cursDec
		into #tmpdocdec  
		from #docdec
  
		update #tmpdocdec  
		set   
			dataDec=(case when d.ordine=d1.ordine then d.data else d.dataDec end),   
			valutaDec=(case when d.ordine_valuta=d1.ordine_valuta then d.valuta else d.valutaDec end),   
			cursDec=(case when d.ordine_valuta=d1.ordine_valuta then d.curs else d.cursDec end)  
		from #tmpdocdec d, (select d2.grp, min(d2.ordine) as ordine, max(d2.ordine_valuta) as ordine_valuta from #tmpdocdec d2 group by d2.grp) d1  
		where d.grp=d1.grp and (d.ordine=d1.ordine or d.ordine_valuta=d1.ordine_valuta)  

		if OBJECT_ID('tempdb..#pdeconturi') is null
		begin
			create table #pdeconturi (subunitate varchar(9))
			exec CreazaDiezDeconturi @numeTabela='#pdeconturi'
		end

		insert into #pdeconturi 
			(subunitate, tip, Marca, Decont, Cont, Data, Data_scadentei, Valoare, Valuta, Curs,	Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii)
		select  
			subunitate, 'T' /*tip_document*/,
			max(case when @GrMarca=1 then marca else '' end),
			max(case when @GrDec=1 then decont else '' end),  
			min(cont),min(dataDec), min(data_scadentei),  
			sum(round(convert(decimal(17,5), valoare), 2)),
			max(valutaDec),max(cursDec),
			sum(round(convert(decimal(17,5), valoare_valuta), 2)),
			sum(round(convert(decimal(17,5), achitat), 2)),  
			sum(round(convert(decimal(17,5), valoare), 2)-round(convert(decimal(17,5), achitat), 2)),  
			sum(round(convert(decimal(17,5), achitat_valuta), 2)),   
			sum(round(convert(decimal(17,5), valoare_valuta), 2)-round(convert(decimal(17,5), achitat_valuta), 2)),
			max(loc_de_munca),max(comanda), max(data), 
			max(explicatii)
		from #tmpdocdec  
		group by subunitate, /*tip_document,*/  
			(case when @GrDec=1 then decont else '' end),  
			(case when @GrMarca=1 then marca else '' end)  
	end
	else 
	Begin
		if object_id('tempdb..#docdeconturi') is null 
		begin
			create table #docdeconturi (subunitate varchar(9))
			exec CreazaDiezDeconturi @numeTabela='#docdeconturi'
		end

		insert into #docdeconturi
			(subunitate, marca, decont, tip_document, numar_document, data, in_perioada, valoare, achitat, cont, cont_coresp, fel, valuta, curs, valoare_valuta, achitat_valuta, 
			tert, factura, explicatii, numar_pozitie, loc_de_munca, comanda, data_scadentei, cantitate, debit_credit, idPozitieDoc, tabela, indbug)
		select subunitate, marca, decont, tip_document, numar_document, data, in_perioada, valoare, achitat, cont, cont_coresp, fel, valuta, curs, valoare_valuta, achitat_valuta, tert, factura, 
			explicatii, numar_pozitie, loc_de_munca, comanda, data_scadentei, cantitate, debit_credit, idPozitieDoc, tabela, indbug
		from #docdec
	End

end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 11, 1)
end catch
