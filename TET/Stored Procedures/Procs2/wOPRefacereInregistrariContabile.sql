
Create procedure wOPRefacereInregistrariContabile @sesiune varchar(50), @parXML xml
as
/**
	Mod de lucru procedura
	1. Lucru cu seturi de date, operatia de refacere inregistrari contabile din ASiSria
		- se poate alege un interval de date (datasus, datajos) si o lista de tipuri de documente (RM, AP, CM, TE, etc )

**/
begin try
	declare 
		@sub char(9), @lunainch int, @anulinch int, @datainch datetime,@datainf datetime, @datasup datetime, @listaTipuri varchar(max), @tipNC varchar(100), 
		@RM int, @PP int, @CM int, @AP int, @AS int, @AC int,@TE int, @DF int, @PF int, @CI int, @AF int, @AI int, @AE int, @PI int, @AD int, @NC int,
		@mesajeroare varchar(max)

	/*
		Jurnalizare executia operatiei. Daca este chemata de pe cine stie unde pt. un doc, nu jurnalizam
	*/
	IF EXISTS (select 1 from sys.objects where name='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereInregistrariContabile'

	exec luare_date_par 'GE','SUBPRO',0,0,@sub OUTPUT
	exec luare_date_par 'GE','LUNABLOC',0,@lunainch OUTPUT,''
	exec luare_date_par 'GE','ANULBLOC',0,@anulinch OUTPUT,''
	
	/* Construieste luna inchisa */
	select @datainch=CAST(CAST(@anulinch AS varchar) + '-' + CAST(@lunainch AS varchar) + '-' + CAST('01' AS varchar) AS DATETIME)
	select @datainch=dbo.EOM(@datainch)

	select 
		/* Variabile pentru seturi de date*/
		@datainf = @parXML.value('(/*/@datainf)[1]', 'datetime'),
		@datasup = @parXML.value('(/*/@datasup)[1]', 'datetime'),		
		@RM = ISNULL(@parXML.value('(/*/@RM)[1]', 'int'),0),
		@PP = ISNULL(@parXML.value('(/*/@PP)[1]', 'int'),0),
		@CM = ISNULL(@parXML.value('(/*/@CM)[1]', 'int'),0),
		@AP = ISNULL(@parXML.value('(/*/@AP)[1]', 'int'),0),
		@AS = ISNULL(@parXML.value('(/*/@AS)[1]', 'int'),0),
		@AC = ISNULL(@parXML.value('(/*/@AC)[1]', 'int'),0),
		@TE = ISNULL(@parXML.value('(/*/@TE)[1]', 'int'),0),
		@DF = ISNULL(@parXML.value('(/*/@DF)[1]', 'int'),0),
		@PF = ISNULL(@parXML.value('(/*/@PF)[1]', 'int'),0),
		@CI = ISNULL(@parXML.value('(/*/@CI)[1]', 'int'),0),
		@AF = ISNULL(@parXML.value('(/*/@AF)[1]', 'int'),0),
		@AI = ISNULL(@parXML.value('(/*/@AI)[1]', 'int'),0),
		@AE = ISNULL(@parXML.value('(/*/@AE)[1]', 'int'),0),
		@PI = ISNULL(@parXML.value('(/*/@PI)[1]', 'int'),0),
		@AD = ISNULL(@parXML.value('(/*/@AD)[1]', 'int'),0),
		@NC = ISNULL(@parXML.value('(/*/@NC)[1]', 'int'),0),
		@tipNC = ISNULL(@parXML.value('(/*/@tipnc)[1]', 'varchar(100)'),'')

	if @RM+@PP+@CM+@AP+@AS+@AC+@TE+@DF+@PF+@CI+@AF+@AI+@AE+@PI+@AD+@NC=0
		raiserror('Bifati cel putin un tip de document!' ,16,1)
	if @datasup<@datainf
		raiserror('Data superioara < data inferioara!' ,16,1)
	if @datainf<=@datainch 
	begin
		set @mesajeroare='Data inferioara ('+CONVERT(char(10),@datainf,103)+') <= '+CONVERT(char(10),@datainch,103)+' (ultima zi a ultimei luni inchise)!'
		raiserror(@mesajeroare ,16,1)
	end

	/** Seturi */
	/* Construim lista tipuri care va fi trimisa mai departe la faInregistrari si InregDoc */
	select 
		@listaTipuri=''

	select @listaTipuri=
		(case @RM when 1 then 'RM,RS,' else '' end) +
		(case @PP when 1 then 'PP,' else '' end) +
		(case @CM when 1 then 'CM,' else '' end) +
		(case @AP when 1 then 'AP,' else '' end) +
		(case @AS when 1 then 'AS,' else '' end) +
		(case @AC when 1 then 'AC,' else '' end) +
		(case @TE when 1 then 'TE,' else '' end) +
		(case @DF when 1 then 'DF,' else '' end) +
		(case @PF when 1 then 'PF,' else '' end) +
		(case @CI when 1 then 'CI,' else '' end) +
		(case @AF when 1 then 'AF,' else '' end) +
		(case @AI when 1 then 'AI,' else '' end) +
		(case @AE when 1 then 'AE,' else '' end) +
		(case @PI when 1 then 'PI,' else '' end) +
		(case @AD when 1 then 'CO,C3,FF,FB,CF,CB,IF,SF,' else '' end) +
		(case @NC when 1 then isnull(nullif(@tipNC,'')+',','IC,MA,ME,MI,MM,NC,DP,AL,AO,PS,UA,') else '' end) 

	/* Daca n-am cel putin un tip (adica am ceva prostii) => nu am lista tipuri */
	IF LEN(@listaTipuri)<2
		select @listaTipuri=null

	/**
		Reguli generale pentru toate filtrarile din tabele sursa (DOC, POZADOC, POZPLIN, POZNCON) la scrierea in DOCDECONTAT
			Se filtreaza 
				- doar documente primite in @listaDocumente
				- doar documentele cu data intre datajos si datasus
				- doar documentele cu data > data ultimei luni inchise

	**/

	/* Se creaza #DocDeContat in care vom scrie date */

	IF OBJECT_ID('tempdb..#DocDeContat') IS NULL
		create table #DocDeContat (subunitate varchar(9), tip varchar(2), numar varchar(40), data datetime) 
	/** Luam documentele din DOC daca este cazul */
	IF @RM+@PP+@CM+@AP+@AS+@AC+@TE+@DF+@PF+@CI+@AF+@AI+@AE>0 -- lipseste cel putin AF. Tratat sa prelucreze si AF.
		insert into #DocDeContat (subunitate, tip, numar, data)
		select d.subunitate, d.tip, d.numar, d.data
		from pozdoc d
		INNER JOIN dbo.Split(@listaTipuri,',') tipuri on tipuri.item=d.tip
		where 
			d.data between @datainf and @datasup and 
			d.data > @datainch and
			tipuri.item IS NOT NULL
		group by d.subunitate, 	d.tip, d.numar, d.data	

	IF @PI > 0
		insert into #DocDeContat (subunitate, tip, numar, data)
		select	p.subunitate, 'PI', p.cont, p.data
		from pozplin p
		where 
			p.data between @datainf and @datasup and 
			p.data > @datainch
		group by p.subunitate, p.cont, p.data

	IF @AD > 0
		insert into #DocDeContat (subunitate, tip, numar, data)
		select p.subunitate, p.tip, p.numar_document, p.data
		from pozadoc p
		where 
			p.data between @datainf and @datasup and 
			p.data > @datainch
		group by p.subunitate, p.tip, p.numar_document, p.data

	IF @NC>0
		insert into #DocDeContat (subunitate, tip, numar, data)
		select p.subunitate, p.tip, p.numar, p.data
		from pozncon p
		INNER JOIN dbo.Split(@listaTipuri,',') tipuri on tipuri.item=p.tip
		where 
			p.data between @datainf and @datasup and 
			p.data > @datainch and
			tipuri.item IS NOT NULL
		group by p.subunitate, p.tip, p.numar, p.data

	/*
		In acest punct avem in DocDeContat documentele a caror inregistrari le vom reface, dar probabil si altele, care nu vrem sa le "afectam"
		Trimitem prin @parXML la faInregistrariContabile un parametru refacere care va fi interpretat acolo si lista de tipuri care va ajunge pana la inreguri...

		Stergem din POZINCON conform parametrilor (DOCDECONTAT + filtrari de date)

	*/
	delete pn
	from pozincon pn
	where pn.Subunitate=@sub and CHARINDEX(pn.Tip_document, @listaTipuri)<>0 and pn.Data between @datainf and @datasup
--	am renuntat la INNER JOIN pe #DocDeContat intrucat pot fi cazuri in care documentele au fost sterse, nu mai exista in tabele si pentru acestea trebuie refacute (sterse) inregistrarile.
	--INNER JOIN #DocDeContat dc on pn.subunitate=dc.subunitate and pn.data=dc.data and pn.numar_document=dc.numar and pn.tip_document=dc.tip
	
	/* Se executa faInregistrariContabile cu specificatia ca vine din refacere (dintabela=2)=> ne vom baza pe existenta #DocDeContat */
	exec faInregistrariContabile @dintabela=2

	select 
		'Operatie executata cu succes!' as textMesaj, 'Notificare' as titluMesaj 
	for xml raw, root('Mesaje')
end try  

begin catch  
	declare 
		@eroare varchar(MAX) 
	set @eroare=ERROR_MESSAGE()+ ' (wOPRefacereInregistrariContabile)'
	raiserror(@eroare, 16, 1) 
end catch
