--***
CREATE procedure wIaPozadoc @sesiune varchar(50), @parXML xml
as
begin
	declare @Bugetari int, @userASiS varchar(10), @lista_lm bit, @subunitate char(9), @tip varchar(2), @numar varchar(20), @data datetime, @numere_pozitii varchar(max)

	--select @userASiS=id from utilizatori where observatii=SUSER_NAME()
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	/*Modificare pentru login utilizator sa */
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	select @lista_lm=dbo.f_arelmfiltru(@userASiS)

	select @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
		@numere_pozitii=ISNULL(@parXML.value('(/row/@numerepozitii)[1]', 'varchar(max)'), '')

	if OBJECT_ID('tempdb..#wPozAdoc') is not null 
		drop table #wPozAdoc

	select p.subunitate, p.tip as tip, p.numar_document as numar, p.data as data, p.tip  as subtip, 
		p.tert, isnull(t.denumire, '') as dentert, 
		p.factura_stinga as facturastinga, p.factura_dreapta as facturadreapta, 
		p.cont_deb as contdeb, isnull(cd.denumire_cont, '') as dencontdeb, 
		p.cont_cred as contcred, isnull(cc.denumire_cont, '') as dencontcred, 
		p.suma as suma, p.TVA11 as cotatva, p.TVA22 as sumatva, 
		p.valuta as valuta, p.curs as curs, p.suma_valuta as sumavaluta, 
		p.Tert_beneficiar as tertbenef, 
		p.Dif_TVA as diftva, p.Achit_fact as achitfact, 
		(case when p.valuta='' then '' else p.cont_dif end) as contdifcurs, 
		(case when p.valuta='' then 0 else convert(decimal(15, 2), p.suma_dif) end) as sumadifcurs, 
		p.explicatii as explicatii, 
		p.loc_munca as lm, ISNULL(lm.denumire, '') as denlm, 
		left(p.comanda,20) as comanda, ISNULL(c.descriere, '') as dencomanda, space(20) as indbug,
		p.Data_fact as datafacturii, p.Data_scad as datascadentei, 
		p.numar_pozitie as numarpozitie, p.jurnal as jurnal, p.Stare as tiptva, p.idpozadoc as idpozadoc, 
		'#000000' as culoare
	into #wPozAdoc
	from pozadoc p
		left outer join terti t on t.subunitate=p.subunitate and t.tert=p.tert
		left outer join conturi cd on cd.subunitate = p.subunitate and cd.cont = p.cont_deb
		left outer join conturi cc on cc.subunitate = p.subunitate and cc.cont = p.Cont_cred
		left outer join lm on lm.Cod=p.Loc_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=rtrim(left(p.comanda,20))
	where p.subunitate=@subunitate and p.Tip=@tip and p.Numar_document=@numar and p.data=@data
		and (isnull(@numere_pozitii, '')='' or charindex(';' + ltrim(str(p.numar_pozitie)) + ';', ';' + @numere_pozitii + ';')>0)
		and (@lista_lm=0 or exists (select 1 from lmfiltrare lu where lu.utilizator=@userasis and lu.cod=p.loc_munca))
	order by p.numar_pozitie DESC

	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozadoc' as tabela, idPozadoc as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #wPozAdoc
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #wPozAdoc p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozadoc
	end

	select rtrim(subunitate) as subunitate, 
		tip as tip, 
		rtrim(numar) as numar, convert(char(10), data, 101) as data, 
		tip  as subtip, 
		rtrim(tert) as tert, 
		rtrim(dentert) as dentert, 
		rtrim(facturastinga) as facturastinga, 
		rtrim(facturadreapta) as facturadreapta, 
		rtrim(contdeb) as contdeb, rtrim(dencontdeb) as dencontdeb, 
		rtrim(contcred) as contcred, rtrim(dencontcred) as dencontcred, 
		convert(decimal(15, 2), suma) as suma, 
		ltrim(str(cotatva)) as cotatva, 
		convert(decimal(15, 2), sumatva) as sumatva, 
		rtrim(valuta) as valuta, convert(decimal(10, 4), curs) as curs, convert(decimal(15, 2), sumavaluta) as sumavaluta, 
		rtrim(tertbenef) as tertbenef, 
		convert(decimal(15, 2), diftva) as diftva, 
		convert(decimal(15, 2), achitfact) as achitfact, 
		rtrim(contdifcurs) as contdifcurs, 
		convert(decimal(15, 2), sumadifcurs) as sumadifcurs, 
		rtrim(explicatii) as explicatii, 
		rtrim(lm) as lm, rtrim(denlm) as denlm, 
		rtrim(comanda) as comanda, rtrim(dencomanda) as dencomanda, 
		rtrim(indbug) as indbug,
		convert(char(10), datafacturii, 101) as datafacturii, 
		convert(char(10), datascadentei, 101) as datascadentei, 
		numarpozitie as numarpozitie, rtrim(jurnal) as jurnal, tiptva as tiptva, idpozadoc as idpozadoc, 
		culoare as culoare
	from #wPozAdoc
	order by numarpozitie DESC
	for xml raw

end
