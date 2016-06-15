--***
create procedure wIaPozNcon @sesiune varchar(50), @parXML xml  
as    
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaPozNconSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wIaPozNconSP @sesiune, @parXML output
	return @returnValue
end  
begin try
	declare @subunitate char(9), @Bugetari int, @tip varchar(2), @numar varchar(20), @data datetime, @utilizator varchar(20) ,@mesaj varchar(200), @_cautare varchar(50), @areDetalii int
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	  
	select @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),  
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),  
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),  
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), '')  ,
		@_cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'), '')  

	if OBJECT_ID('tempdb..#wPozNcon') is not null
		drop table #wPozNcon

	/*	Pun datele in tabela temporara #wPozNcon pentru a putea altera campul indbug prin procedura comuna indbugPozitieDocument. Sau poate pentru wIaPozNconSP2. */
	select 
		p.subunitate as subunitate, 
		p.tip as tip,
		p.tip as subtip, 
		p.numar as numar, 
		p.data as data, 
		p.cont_debitor as cont_debitor, 
		rtrim(p.cont_debitor)+' - '+rtrim(cdeb.Denumire_cont) as dencont_debitor, 
		p.cont_creditor as cont_creditor,   
		rtrim(p.cont_creditor)+' - '+rtrim(ccre.Denumire_cont) as dencont_creditor,   
		p.suma as suma,  
		p.valuta as valuta, p.curs as curs, 
		p.suma_valuta as suma_valuta,  
		p.explicatii as ex,
		nr_pozitie as nr_pozitie,
		(case when rtrim(p.tert)<>'' then rtrim(p.tert) else rtrim(cdeb.Articol_de_calculatie) end) as tert,
		p.loc_munca as lm, rtrim(left(p.comanda,20)) as comanda,
		space(20) as indbug,
		isnull(rtrim(lm.denumire), '') as denlm, 
		isnull(rtrim(com.descriere), '') as dencomanda, 
		isnull(rtrim(t.denumire), '') as dentert, 
		p.utilizator as utilizator, p.data_operarii as data_operarii, p.jurnal, p.idpozncon as idpozncon
	into #wPozNcon
	from pozncon p  
		left outer join conturi cdeb on cdeb.Subunitate=p.Subunitate and cdeb.Cont=p.Cont_debitor
		left outer join conturi ccre on ccre.Subunitate=p.Subunitate and ccre.Cont=p.Cont_creditor
		left outer join terti t on t.subunitate = p.subunitate and t.tert = p.tert  
		left outer join lm on lm.cod = p.loc_munca  
		left outer join comenzi com on com.subunitate = p.subunitate and com.comanda = rtrim(left(p.comanda,20)) 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.loc_munca=lu.cod
	where p.subunitate=@subunitate and p.tip=@tip and p.numar=@numar and p.data=@data  
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
		and (ISNULL(@_cautare,'')='' or (p.Cont_creditor like @_cautare+'%' or p.Cont_debitor like @_cautare+'%' or lm.Denumire like '%'+@_cautare+'%'))
	order by nr_pozitie DESC  

	if exists (select 1 from syscolumns sc, sysobjects so where so.id = sc.id and so.NAME = 'pozplin' and sc.NAME = 'detalii')
	begin
		set @areDetalii = 1

		alter table #wPozNcon ADD detalii XML

		update #wPozNcon
		set detalii = pn.detalii
		from pozncon pn
		where #wPozNcon.idpozncon = pn.idpozncon
	end
	else
	begin
		set @areDetalii = 0
		alter table #wPozNcon ADD detalii char(1)
	end


	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozncon' as tabela, idPozncon as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #wPozNcon
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #wPozNcon p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozncon
	end

	select 
		rtrim(subunitate) as subunitate, rtrim(tip) as tip, rtrim(tip) as subtip, 
		rtrim(numar) as numar, convert(char(10),data,101) as data, 
		rtrim(cont_debitor) as cont_debitor, 
		rtrim(dencont_debitor) as dencont_debitor, 
		rtrim(cont_creditor) as cont_creditor,   
		rtrim(dencont_creditor) as dencont_creditor,   
		convert(decimal(14, 2), suma) as suma,  
		rtrim(valuta) as valuta, convert(decimal(14, 4), curs) as curs, 
		convert(decimal(14, 2), suma_valuta) as suma_valuta,  
		rtrim(ex) as ex, nr_pozitie as nr_pozitie,
		rtrim(tert) as tert, rtrim(lm) as lm, rtrim(comanda) as comanda, rtrim(indbug) as indbug,
		rtrim(denlm) as denlm,
		rtrim(dencomanda) as dencomanda,
		rtrim(dentert) as dentert, 
		rtrim(utilizator) as utilizator, convert (char(10),data_operarii,103) as data_operarii, rtrim(jurnal) as jurnal, idpozncon as idpozncon, detalii
	from #wPozNcon 
	order by nr_pozitie DESC  
	for xml raw, root('Date')

	select @areDetalii areDetaliiXml
	for xml raw, root('Mesaje')

end try
begin catch
	set @mesaj = '(wIaPozNcon)'+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
