--***
Create procedure wOPGenerareDifCursLaDisponibil @sesiune varchar(50), @parXML xml
as

declare @lmstrict int, @lunainch int, @anulinch int, @datainch datetime, 
	@stergplin int,@dataplin datetime,@contfav varchar(40),@contnefav varchar(40),
	@contvendif varchar(40),@contcheltdif varchar(40),@lm varchar(9),@contfiltru varchar(40),@valutafiltru varchar(13),
	@denctfav varchar(80),@denctnefav varchar(80),@denctvendif varchar(80),@denctcheltdif varchar(80),
	@denlm varchar(80),@denctfiltru varchar(80),@denvalutafiltru varchar(80),@curs decimal(12,4), @deschidGridValute bit


Set @lmstrict=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='CENTPROF'), 0)
Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNAINC'), 1)
Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULINC'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
Set @stergplin = ISNULL(@parXML.value('(/parametri/@stergplin)[1]', 'int'), 0)
Set @dataplin = ISNULL(@parXML.value('(/parametri/@dataplin)[1]', 'datetime'), '01/01/1901')
Set @contfav = ISNULL(@parXML.value('(/parametri/@contfav)[1]', 'varchar(40)'), '')
select @denctfav=isnull(Denumire_cont,'') from conturi where cont=@contfav
Set @contnefav = ISNULL(@parXML.value('(/parametri/@contnefav)[1]', 'varchar(40)'), '')
select @denctnefav=isnull(Denumire_cont,'') from conturi where cont=@contnefav
Set @contvendif = ISNULL(@parXML.value('(/parametri/@contvendif)[1]', 'varchar(40)'), '')
select @denctvendif=isnull(Denumire_cont,'') from conturi where cont=@contvendif
Set @contcheltdif = ISNULL(@parXML.value('(/parametri/@contcheltdif)[1]', 'varchar(40)'), '')
select @denctcheltdif=isnull(Denumire_cont,'') from conturi where cont=@contcheltdif
Set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(20)'), '')
select @denlm=isnull(Denumire,'') from lm where cod=@lm
Set @contfiltru = ISNULL(@parXML.value('(/parametri/@contfiltru)[1]', 'varchar(40)'), '')
select @denctfiltru=isnull(Denumire_cont,'') from conturi where cont=@contfiltru
Set @valutafiltru = ISNULL(@parXML.value('(/parametri/@valutafiltru)[1]', 'varchar(20)'), '')
Set @curs= ISNULL(@parXML.value('(/parametri/@curs)[1]', 'decimal(12,4)'), 0)
select @denvalutafiltru=isnull(Denumire_valuta,'') from valuta where valuta=@valutafiltru
Set @deschidGridValute=ISNULL(@parXML.value('(/*/@deschidGridValute)[1]', 'BIT'), 1)

IF @deschidGridValute=1 and exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareDifCursLaDisponibil'

begin try

	IF @deschidGridValute=1
	begin 
		set @parXML.modify('insert attribute procedura {"disponibil"} into (/*)[1]')
		SELECT 'Vizualizare si actualizare cursuri valute' nume, 'GV' codmeniu, 'O' tipmacheta,
				 (select dbo.fInlocuireDenumireElementXML(@parXML,'row')) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

		return
	end


	if @dataplin<=@datainch
		raiserror('Data doc. este intr-o luna inchisa!' ,16,1)
	if not exists (select 1 from conturi where cont=@contfav and Are_analitice=0)
		raiserror('Cont op. favorabile inexistent sau cu analitice!' ,16,1)
	if not exists (select 1 from conturi where cont=@contnefav and Are_analitice=0)
		raiserror('Cont op. nefavorabile inexistent sau cu analitice!' ,16,1)
	if (@lmstrict=1 or @lm<>'') and not exists (select 1 from lm where cod=@lm)
		raiserror('Loc de munca inexistent!' ,16,1)
	if isnull(@contfiltru,'')<>'' and not exists (select 1 from conturi where cont=@contfiltru)
		raiserror('Cont in valuta inexistent!' ,16,1)
	if isnull(@contfiltru,'')<>'' and not exists (select 1 from proprietati p inner join valuta v on p.valoare=v.valuta where tip='CONT' and cod=@contfiltru and Cod_proprietate='INVALUTA')
		raiserror('Contul in valuta pentru care se genereaza diferente de curs la disponibil trebuie sa aiba completata valuta in planul de conturi!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from valuta where valuta=@valutafiltru)
		raiserror('Valuta inexistenta!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from curs where valuta=@valutafiltru)
		raiserror('Valuta fara nici un curs introdus!' ,16,1)

	exec DifCursDisp @parcont=@contfiltru,@parvaluta=@valutafiltru,@datadoc=@dataplin,
		@contfav=@contfav,@contnefav=@contnefav,@sterg_pl_inc_ant=@stergplin,@lm=@lm,@curs=@curs

	select 'Finalizare cu succes a operatiei! S-au generat documente tip PD/ID, numar ="DIF.C.V.", data '+convert(char(10),@dataplin,103) as textMesaj,
		'Notificare' as titluMesaj 
		for xml raw, root('Mesaje')

end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
