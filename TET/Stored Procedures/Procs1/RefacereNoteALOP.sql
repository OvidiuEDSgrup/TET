--***
create procedure RefacereNoteALOP @DataJos datetime, @DataSus datetime, @Indicator char(20), @AngBugetare int, @Ordonantari int, @OP int
as
begin try 
	if @DataJos is null set @DataJos='01/01/1901'
	if @DataSus is null set @DataSus='12/31/2999'
	if @Indicator is null set @Indicator=''
	if @AngBugetare is null set @AngBugetare=1
	if @Ordonantari is null set @Ordonantari=1
	if @OP is null set @OP=1

	declare @Sb char(9), @TipNCAlop char(2), @Ct8066 varchar(40), @Ct8067 varchar(40), @docPozncon xml

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output

	set @TipNCAlop='AO'
	select @Ct8066=cont from conturi where cont like '8066%' and are_analitice=0
	select @Ct8067=cont from conturi where cont like '8067%' and are_analitice=0
	select @Ct8066=isnull(@Ct8066,'8066'), @Ct8067=isnull(@Ct8067,'8067')

	if object_id('tempdb.dbo.#sterse') is not null
		drop table #sterse
	create table #sterse (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	delete pozncon
	OUTPUT deleted.Subunitate,deleted.tip,deleted.numar,deleted.data
	into #sterse (subunitate,tip,numar,data) 
	where subunitate=@Sb and tip=@TipNCAlop and data between @DataJos and @DataSus and right(comanda,20) like RTrim(@Indicator)+'%'
	and (@AngBugetare=1 and cont_debitor like RTrim(@Ct8066)+'%' 
		or @Ordonantari=1 and (cont_creditor like RTrim(@Ct8066)+'%' or cont_debitor like RTrim(@Ct8067)+'%')
		or @OP=1 and cont_creditor like RTrim(@Ct8067)+'%')

	IF OBJECT_ID('tempdb..#poznconbug') is not null drop table #poznconbug
	CREATE TABLE [dbo].[#poznconbug](
		[Tip] [varchar](2) NOT NULL,
		[Numar] [varchar](20) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Cont_debitor] [varchar](40) NOT NULL,
		[Cont_creditor] [varchar](40) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Explicatii] [varchar](50) NOT NULL,
		[Loc_munca] [varchar](9) NOT NULL,
		[Indicator] [varchar](20) NOT NULL,
		[idPozncon] [int] identity (1,1),
		[numar_pozitie] int
	) 

	insert into #poznconbug (Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Loc_munca, Indicator,numar_pozitie)
	select @TipNCAlop, a.numar, (case when a.data_angajament='1901-01-01' then a.data else a.data_angajament end), @Ct8066 as ctdeb, space(40) as ctcred, a.suma, a.valuta, a.curs, a.suma_valuta, 
		convert(char(50), 'Angajare bugetara') as explicatii, a.loc_de_munca as lm, a.indicator as indicator,
		null
	from angbug a
	where @AngBugetare=1 and a.indicator like RTrim(@Indicator)+'%' and (case when a.data_angajament='1901-01-01' then a.data else a.data_angajament end) between @DataJos and @DataSus
	union all
	select @TipNCAlop, o.numar_ang_legal, o.data_ang_legal/*(case when o.data_ang_legal='1901-01-01' then o.Data_ordonantare else o.data_ang_legal end)*/, '', @Ct8066, o.suma, o.valuta, o.curs, o.suma_valuta,
		'Angajare legala '+RTrim(o.numar_ang_legal), o.compartiment, o.indicator, null
	from ordonantari o
	where @Ordonantari=1 and o.indicator like RTrim(@Indicator)+'%' and o.data_ang_legal between @DataJos and @DataSus
	union all
	select @TipNCAlop, o.numar_ang_legal, o.data_ang_legal, @Ct8067, '', o.suma, o.valuta, o.curs, o.suma_valuta,
		'Angajare legala '+RTrim(o.numar_ang_legal), o.compartiment, o.indicator,null
	from ordonantari o
	where @Ordonantari=1 and o.indicator like RTrim(@Indicator)+'%' and o.data_ang_legal between @DataJos and @DataSus
	union all
	select @TipNCAlop, p.numar_OP, p.data_OP, '', @Ct8067, p.suma, p.valuta, p.curs, p.suma_valuta,
		p.explicatii, isnull(o.compartiment, ''), p.indicator, p.Numar_pozitie
	from pozordonantari p
	left outer join ordonantari o on p.indicator=o.indicator and p.numar_ordonantare=o.numar_ordonantare and p.data_ordonantare=o.data_ordonantare
	where @OP=1 and p.indicator like RTrim(@Indicator)+'%' and p.data_OP between @DataJos and @DataSus

	if exists (select 1 from sysobjects where [type]='P' and [name]='RefacereNoteALOPSP')
		exec RefacereNoteALOPSP @DataJos, @DataSus, @Indicator, @AngBugetare, @Ordonantari, @OP -- procedura care va modifica #poznconbug (apelata pt. inceput pt. Primaria Timisoara)

	set @docPozncon=
		(select a.Tip as '@tip', rtrim(a.Numar) as '@numar', a.Data as '@data', 
			(select rtrim(d.Cont_debitor) as '@cont_debitor', rtrim(d.Cont_creditor) as '@cont_creditor', convert(decimal(15,2),d.Suma) as '@suma',
				rtrim(d.Valuta) as '@valuta', convert(decimal(17,5),d.curs) as '@curs', convert(decimal(15,2),d.Suma_valuta) as '@suma_valuta',
				rtrim(d.Explicatii) as '@ex', rtrim(d.Loc_munca) as '@lm', rtrim(d.Indicator) as '@indbug',
				numar_pozitie as '@nr_pozitie'
			from #poznconbug d
			where d.Tip=a.Tip and d.Numar=a.Numar and d.Data=a.Data
			order by d.idPozncon
			for XML path,type)
		from #poznconbug a
		Group by a.Numar, a.Data, a.Tip
		for xml path,root('Date'))

	exec wScriuNcon @sesiune=null, @parXML=@docPozncon

	/*	generare inregistrari contabile	pentru documente sterse si generate	*/
	if object_id('tempdb.dbo.#DocDeContat') is not null
		drop table #DocDeContat
	create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime)

	insert into #DocDeContat (subunitate, tip, numar, data)
	select distinct Subunitate, Tip, Numar, Data
	from #sterse s

	insert into #DocDeContat (subunitate, tip, numar, data)
	select distinct @Sb, p.Tip, p.Numar, p.Data
	from #poznconbug p
	where not exists (select 1 from #DocDeContat d where d.Subunitate=@Sb and d.tip=p.tip and d.numar=p.numar and d.data=p.data)
	
	exec fainregistraricontabile @dinTabela=2
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
