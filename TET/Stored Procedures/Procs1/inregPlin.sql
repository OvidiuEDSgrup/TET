create procedure inregPlin @sesiune varchar(50), @parXML xml OUTPUT
as 
/*
	Exemplu apel
		exec inregPlin '',''
*/

	declare 
		@Cttvaded varchar(40),@cttvacol varchar(40),@CtChTVANeded varchar(40),@ignor4428 int,@Cttvaneex varchar(40), @subunitate varchar(9), @invdifcursneg int, @bugetari int

	/*
		Procedura se bazeaza pe existenta tabelei #DocDeContat
			-> ea va exista insa pentru orice eventualitate apelam crearea (nu creaza daca exista)
	*/
	IF OBJECT_ID('tempdb..#DocDeContat') IS NULL
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)
	
	CREATE TABLE [dbo].[#pozincon](
		[TipInregistrare] varchar(20), 
		[Subunitate] varchar(9),
		[Tip] varchar(2),
		[Numar] [varchar](40) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Cont_debitor] [varchar](40) NOT NULL,
		[Cont_creditor] [varchar](40) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Explicatii] [varchar](1000) NOT NULL,
		[Utilizator] [varchar](10) NOT NULL,
		[idPozPlin] [int],
		[Loc_de_munca] [varchar](9) NOT NULL,
		[Comanda] [varchar](40) NOT NULL,
		[Jurnal] [varchar](20),
		[Data_operarii] datetime,
		[Ora_operarii] varchar(10),
		[Inversate] int,
		[Indbug] [varchar](20)
	) 

	exec luare_date_par 'GE','SUBPRO',0,0,@subunitate output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	exec luare_date_par 'GE','CDTVA',0,0,@Cttvaded output
	exec luare_date_par 'GE','CCTVA',0,0,@cttvacol output
	exec luare_date_par 'GE','CCTVANED',0,0,@CtChTVANeded output
	exec luare_date_par 'GE','NEEXAV',@ignor4428 output,0,'' --Generam note contabile cu 4428 la incasari sau plati avans
	exec luare_date_par 'GE','CNEEXREC',0,0,@Cttvaneex output --Contul folosit pentru notele contabile de mai sus
	exec luare_date_par 'GE','INVDIFINR',@invdifcursneg output,0,'' -- inversare nota si ceva conturi la diferenta negativa de curs 

	select 
		@Cttvaded = rtrim(@Cttvaded), @cttvacol= rtrim(@cttvacol),@CtChTVANeded= rtrim(@CtChTVANeded), @Cttvaneex= rtrim(@Cttvaneex)
	/*
		Se genereaza tabelul #pozplin care contine campuri calculate folosite mai jos la generarea inreg.
	*/
	select 
		p.Subunitate, p.Cont, p.Data, p.Numar, p.Plata_incasare, p.Tert, p.Factura, p.Cont_corespondent as ContCorespondent, 
		p.Suma, p.Valuta, p.Curs, p.Suma_valuta, p.tip_tva, p.TVA11, p.TVA22, 
		ltrim(p.plata_incasare)+' '+rtrim(p.numar)+' '
			+(case when p.explicatii='' or p.Plata_incasare in ('PF','IB') then 'f.'+rtrim(p.factura)+' - '+ltrim(isnull(t.Denumire,isnull(c.denumire_cont,''))) else rtrim(p.explicatii) end)
			+(case when c.Sold_credit=9 then ' (dec.'+rtrim(isnull(p.decont,''))+')' else '' end) as explicatii,
		p.Loc_de_munca, left(p.Comanda,20) as comanda, p.idPozPlin, p.Cont_dif, p.Suma_dif, p.Achit_fact, 
		p.Jurnal, isnull(c.Tip_cont,'') as tipcont,utilizator,data_operarii,ora_operarii,space(20) as indbug,
		isnull(p.detalii.value('(/row/@_contdifdec)[1]','varchar(40)'),'') as cont_dif_dec, isnull(p.detalii.value('(/row/@_difcursdec)[1]','float'),0) as dif_curs_dec
	into #pozplin
	from pozplin p
	INNER JOIN #DocDeContat dc on p.subunitate=dc.subunitate and dc.tip='PI' and p.cont=dc.numar and p.data=dc.data
	left join terti t on p.subunitate=t.subunitate and p.tert=t.tert
	left outer join conturi c on p.subunitate = c.subunitate and p.Cont_corespondent = c.cont 
	where p.subunitate=@subunitate
	ORDER BY p.subunitate, p.cont, p.data, p.numar,p.idPozPlin
	/*
		Rotunjirea intotdeauna la nivel de pozitie la 2 zecimale cu formula round(convert(decimal(17,5),@cc),2)

		Tip: BAZA
			CONT = CONT_CORESPONDENT daca left(plata_incasare,1)='I' altfel invers
	*/

	/* apelam procedura unica de stabilire a indicatorului bugetar pentru fiecare pozitie de document */
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozplin' as tabela, idPozPlin as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #pozplin
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #pozplin p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozPlin
	end

	insert into #pozincon(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal, Cont_debitor, Cont_creditor, Suma, 
		Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'BAZA',p.subunitate,'PI',p.cont,p.data,p.valuta,p.curs,sum(round(p.suma_valuta,2)),max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
	(case when left(p.plata_incasare,1)='I' then p.Cont else p.ContCorespondent end),
	(case when left(p.plata_incasare,1)='I' then p.ContCorespondent else p.cont end),
	sum(round(convert(decimal(17,5),p.suma),2)-round(convert(decimal(17,5),p.tva22),2)-(case when p.suma_dif>=0.01 or @invdifcursneg=1 then round(convert(decimal(17,5),p.Suma_dif),2) else 0 end)) as valoare,
	max(p.explicatii) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
	from #pozplin p
	group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozplin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.indbug

	/*		
		TVAD
			CONTTVAD = CONT
		TVAC
			CONT = CONTTVAC
	*/
	insert into #pozincon 
		(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select (case when left(plata_incasare,1)='I' then 'TVAD' else 'TVAC' end),
	p.subunitate,'PI',p.cont,p.data,p.valuta,p.curs,0/*sum(round(p.suma_valuta,2))*/,max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
	(case when left(p.plata_incasare,1)='P' then @Cttvaded else p.Cont end),
	(case when left(p.plata_incasare,1)='P' then p.Cont else @Cttvacol end),
	sum(round(convert(decimal(17,5),p.tva22),2)) as valoare,
	max(p.explicatii) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
	from #pozplin p
	where p.Plata_incasare in ('IC','IB','PF','PC')
	group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozPlin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.indbug
	having abs(sum(round(convert(decimal(17,5),p.tva22),2)))>=0.01

	/*
	TVANED doar la PC
			in functie de tip tva (2 sau 3) contul debitor este cheltuiala la 2 (din setare) sau cont corespondent (la 3)
			cu CONTTVAD
	*/
	insert into #pozincon
		(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'TVANED',p.subunitate,'PI',p.cont,p.data,p.valuta,p.curs,sum(round(p.suma_valuta,2)),max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
	(case when p.tip_tva=2 then @CtChTVANeded else p.ContCorespondent end),
	@Cttvaded,
	sum(round(convert(decimal(17,5),p.tva22),2)) as valoare,
	max(p.explicatii) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
	from #pozplin p
	where p.Plata_incasare='PC' and p.tip_tva in (2,3)
	group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozPlin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.tip_tva,p.Indbug
	having abs(sum(round(convert(decimal(17,5),p.tva22),2)))>=0.01
	
	if @ignor4428=0
	begin
		/*
			TVAAV se aplica la PF si IB, functie de setare 
				conttvaneexavans = cont corespondent pt IB 
				sau invers la PF
		*/
		insert into #pozincon
			(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
		select 'TVAAV',p.subunitate,'PI',p.cont,p.data,p.valuta,p.curs,sum(round(p.suma_valuta,2)),max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
		(case when left(p.plata_incasare,1)='I' then @Cttvaneex else p.ContCorespondent end),
		(case when left(p.plata_incasare,1)='I' then p.ContCorespondent else @cttvaneex end),
		sum(round(convert(decimal(17,5),p.tva22),2)) as valoare,
		max(p.explicatii) as explicatii,
		max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
		from #pozplin p
		where p.Plata_incasare in ('IB','PF')
		group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozPlin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.indbug
		having abs(sum(round(convert(decimal(17,5),p.tva22),2)))>=0.01
	end

	/*
			DIFCURS - pe cazuri
			1. Incasare
				Dif pozitiva (sumadif>0)
					Cont = CtDif
				Dif negativa -- else
					daca @invdifcursneg=1 = inversarea
						ContDif = Cont
					altfel
						ContDif = ContCor
			2. Plata
				Dif pozitiva (sumadif>0)
					CtDif = Cont
				Dif negativa -- else
					daca @invdifcursneg=1 = inversarea
						Cont = ContDif
					altfel
						ContCor = ContDif
			*/
	insert into #pozincon
		(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DIFCURS',p.subunitate,'PI',p.cont,p.data,'',0,0,max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
	(case when left(p.plata_incasare,1)='P' then 
		/*Pentru plati*/
			(case when sum(round(convert(decimal(17,5),p.Suma_dif),2))>0 then p.Cont_dif
					else (case when @invdifcursneg=1 then p.cont else p.contCorespondent end) end)
		else
		/*Pentru incasari*/
			(case when sum(round(convert(decimal(17,5),p.Suma_dif),2))>0 then p.cont
					else p.cont_dif end)
	end),
	(case when left(p.plata_incasare,1)='P' then 
		/*Pentru plati*/
			(case when sum(round(convert(decimal(17,5),p.Suma_dif),2))>0 then p.Cont
					else p.Cont_dif end)
		else
		/*Pentru incasari*/
			(case when sum(round(convert(decimal(17,5),p.Suma_dif),2))>0 then p.cont_dif
			else (case when @invdifcursneg=1 then p.cont else p.contCorespondent end) end)
	end),
	abs(sum(round(convert(decimal(17,5),p.Suma_dif),2))) as valoare,
	max(p.explicatii) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
	from #pozplin p
	where p.Plata_incasare in ('PF', 'IB') 
	group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozPlin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.cont_dif,p.Indbug
	having abs(sum(round(convert(decimal(17,5),p.suma_dif),2)))>=0.01

	/*	DIFERENTE DE CURS la deconturi */
	insert into #pozincon
		(TipInregistrare,Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, idPozPlin, Loc_de_munca, Comanda, Jurnal,Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii, Indbug)
	select 'DIFCURSD',p.subunitate,'PI',p.cont,p.data,'',0,0,max(p.utilizator),p.idPozPlin,p.loc_de_munca,p.comanda,p.jurnal,
	(case when sum(round(convert(decimal(17,5),p.Dif_curs_dec),2))>0 then p.cont 
			else p.cont_dif_dec end),
	(case when sum(round(convert(decimal(17,5),p.Dif_curs_dec),2))>0 then p.cont_dif_dec
			else p.cont end), 
	abs(sum(round(convert(decimal(17,5),p.Dif_curs_dec),2))) as valoare,
	max(p.explicatii) as explicatii,
	max(p.data_operarii), max(p.ora_operarii), rtrim(p.Indbug)
	from #pozplin p
		inner join conturi c on c.Subunitate=p.Subunitate and c.cont=p.cont and c.Sold_credit=9
	group by p.subunitate, p.cont, p.contcorespondent,p.data, p.idPozPlin, p.plata_incasare,p.factura,p.numar,p.valuta,p.curs,p.loc_de_munca,p.comanda,p.jurnal,p.cont_dif_dec,p.Indbug
	having abs(sum(round(convert(decimal(17,5),p.Dif_curs_dec),2)))>=0.01

	
	update #pozincon set Suma_valuta=0, curs=0 where valuta='' and (Suma_valuta<>0 or curs<>0)

	-- pozplin.contul este ignorat daca pozplin.cont_corespondent like 8%
	update #pozincon set Cont_debitor='' where explicatii like'I%' and Cont_creditor like '8%' and Cont_creditor not like '891%' 
	update #pozincon set Cont_creditor='' where explicatii like'P%' and Cont_debitor like '8%' and Cont_debitor not like '891%' 

	/*Inversare daca este cazul, la inreg. de BAZA*/
	update #pozincon 
		set Cont_creditor=Cont_debitor,Cont_debitor=Cont_creditor,suma=-1*suma,Suma_valuta=-1*Suma_valuta, Inversate=1
	from #pozincon p
	inner join conturi cd on p.Cont_debitor=cd.Cont
	inner join conturi cc on p.Cont_creditor=cc.Cont
	where 
		p.TipInregistrare='BAZA' and 
		(p.Cont_debitor like '7%' and cc.Tip_cont='P' or p.Cont_debitor like '6%' and cd.Tip_cont='P') OR
		(p.Cont_creditor like '6%' and cc.Tip_cont='A' or p.Cont_creditor like '7%' and cc.Tip_cont='A')
	
begin try	
	
	/* Apel de procedura SP ce poate trata tabela temporara #pozincon 
		se pot folosi tipurile de inregistrari (ex. ISTOC, TVAD) pentru a afecta doar unele din acestea
	*/

	if exists (select 1 from sysobjects where [type]='P' and [name]='inregPlinSP')
		exec inregPlinSP @sesiune, @parXML output
	
	delete from #pozincon 
		where abs(suma)<0.01 and abs(Suma_valuta)<0.01
	
	delete p 
	from pozincon p
		-- stergem aferent documentelor selectate, ca sa fie luate in calcul si cele fara inregistrari + sa nu intretin conditia de selectie din pozdoc in 2 locuri 
		inner join #pozplin dc on p.subunitate=dc.subunitate and p.tip_document='PI' and p.numar_document=dc.cont and p.data=dc.data

	insert into pozincon
	(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, Indbug)
	select Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, sum(Suma), Valuta, max(Curs), sum(Suma_valuta), 
		max(rtrim(left(Explicatii,48) +' _')), max(Utilizator), 			
			max(Data_operarii),max(Ora_operarii) 
		, idPozPlin, Loc_de_munca, Comanda, max(Jurnal), indbug
		from #pozincon 
		group by subunitate,tip,numar,data,cont_debitor,cont_creditor,Loc_de_munca,comanda,idPozPlin,Valuta,indbug
		order by tip,data

	-- stergem din docDeContat documentele prevazute - aici lucram doar cu #DocDeContat
	delete dc 
		from DocDeContat dc
		inner join #DocDeContat p on dc.tip=p.tip and p.numar=dc.numar and p.data=dc.data 
		where dc.tip='PI'

	delete #DocDeContat where tip='PI'

end try
begin catch
	declare @mesaj varchar(8000)
	set @mesaj =ERROR_MESSAGE()+' (inregPlin)'
	raiserror(@mesaj, 11, 1)
end catch
