create procedure inregNCon @sesiune varchar(50), @parXML xml OUTPUT
as 

	declare 
		 @sub varchar(9), @bugetari int

		/*
		Procedura se bazeaza pe existenta tabelei #DocDeContat
			-> ea va exista insa pentru orice eventualitate apelam crearea (nu creaza daca exista)
		*/

	IF OBJECT_ID('tempdb..#DocDeContat') IS NULL
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	exec luare_date_par 'GE','SUBPRO',0,0,@Sub output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''

	CREATE TABLE [dbo].[#pozincon](
		[Subunitate] varchar(9),
		[Tip] varchar(2),
		[Numar] [varchar](13) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Cont_debitor] [varchar](40) NOT NULL,
		[Cont_creditor] [varchar](40) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Explicatii] [varchar](1000) NOT NULL,
		[Utilizator] [varchar](10) NOT NULL,
		[Numar_pozitie] [int] identity,
		[Loc_de_munca] [varchar](9) NOT NULL,
		[Comanda] [varchar](40) NOT NULL,
		[Jurnal] [varchar](20),
		[Indbug] [varchar](20),
		[Data_operarii] datetime,
		[Ora_operarii] varchar(10)
	) 

	/* am schimbat numele tabelei #pozncon in #tmppozncon, intrucat #pozncon se folosea si in wScriuNcon */
	select 
		RTRIM(p.subunitate) subunitate, rtrim(p.tip) tip, rtrim(p.numar) numar, p.data data, rtrim(p.cont_debitor) cont_debitor, rtrim(p.Cont_creditor) cont_creditor, suma, valuta, curs, suma_valuta, 
		rtrim(explicatii) explicatii, utilizator, data_operarii, ora_operarii, loc_munca, left(comanda,20) as comanda, tert, jurnal, space(20) as indbug, detalii, idPozncon
	into #tmppozncon
	from pozncon p
	INNER JOIN #DocDeContat dc on p.subunitate=dc.subunitate and dc.tip=p.tip and p.numar=dc.numar and p.data=dc.data
	where p.Subunitate=@Sub

	/* apelam procedura unica de stabilire a indicatorului bugetar pentru fiecare pozitie de document */
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, 'pozncon' as tabela, idPozncon as idPozitieDoc, indbug into #indbugPozitieDoc 
		from #tmppozncon
		exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXML
		update p set p.indbug=ib.indbug
		from #tmppozncon p
			left outer join #indbugPozitieDoc ib on ib.idPozitieDoc=p.idPozncon
	end

	insert into #pozincon(Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal, Indbug, Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii)
	select
		subunitate, tip, numar, data, valuta, curs, round(convert(decimal(17,5),Suma_valuta),3), utilizator, loc_munca, comanda, jurnal, Indbug, cont_debitor, cont_creditor, 
		round(convert(decimal(17,5),suma),2), explicatii, Data_operarii, Ora_operarii
	from #tmppozncon
	
	/*	pentru bugetari nu trebuie generate inregistrari contabile pe contul de buget (8060) pe indicator de venituri (doar pe indicatorii de cheltuieli) */
	if @bugetari=1 
	begin
		delete from #pozincon
		where (cont_debitor like '80600%' or cont_creditor like '80600%') and dbo.fIndicatorCheltuieli(indbug)=0
	end
		
	begin try	
		
		/* Apel de procedura SP ce poate trata tabela temporara #pozincon */

		if exists (select 1 from sysobjects where [type]='P' and [name]='inregNConSP')
			exec inregNConSP @sesiune, @parXML output
	
		delete from #pozincon 
			where abs(suma)<0.01 and abs(Suma_valuta)<0.01
	
		delete p 
		from pozincon p
		inner join #tmppozncon dc on p.subunitate=dc.subunitate and p.tip_document=dc.tip and p.numar_document=dc.numar and p.data=dc.data

		insert into pozincon
		(Subunitate, Tip_document, Numar_document, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, Indbug)
		select 
			Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta,'N:'+left(Explicatii,48), Utilizator, Data_operarii, Ora_operarii, Numar_pozitie, Loc_de_munca, Comanda, Jurnal, rtrim(Indbug)
		from #pozincon 
		order by tip,data
	
		-- stergem din docDeContat documentele prevazute - aici lucram doar cu #DocDeContat
		delete dc 
			from DocDeContat dc
			inner join #DocDeContat p on dc.tip=p.tip and p.numar=dc.numar and p.data=dc.data 
			where dc.tip in ('IC','MA','ME','MI','MM','NC','DP','AL','AO','PS','UA')

		delete #DocDeContat where tip in ('IC','MA','ME','MI','MM','NC','DP','AL','AO','PS','UA')
		
	end try
	begin catch
		declare @mesaj varchar(2000)
		set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
		raiserror (@mesaj, 15, 1)
	end catch
