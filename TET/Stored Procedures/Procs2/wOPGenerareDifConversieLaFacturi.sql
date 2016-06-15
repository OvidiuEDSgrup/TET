
create procedure wOPGenerareDifConversieLaFacturi @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@lunainch int, @anulinch int, @datainch datetime,@tipfact char(1),@tertfiltru char(13),@valutafiltru char(3),@idcorectii varchar(4),
		@datacorectii datetime,	@conttertifiltru varchar(40),@gencorectii int,@stergcorectii int,@dentertfiltru varchar(80),@denconttertifiltru varchar(80),
		@denvalutafiltru varchar(80), @deschidGridValute bit
	
	Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)
	Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
	if @lunainch not between 1 and 12 or @anulinch<=1901 
		set @datainch='01/31/1901'
	else 
		set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

	Set @tipfact = ISNULL(@parXML.value('(/*/@tipfact)[1]', 'char(20)'), 'B')
	Set @stergcorectii = ISNULL(@parXML.value('(/*/@stergcorectii)[1]', 'int'), 0)
	Set @gencorectii = ISNULL(@parXML.value('(/*/@gencorectii)[1]', 'int'), 0)
	Set @idcorectii = ISNULL(@parXML.value('(/*/@idcorectii)[1]', 'varchar(20)'), 'DIFC')
	Set @datacorectii = ISNULL(@parXML.value('(/*/@datacorectii)[1]', 'datetime'), '01/01/1901')
	Set @tertfiltru = ISNULL(@parXML.value('(/*/@tertfiltru)[1]', 'varchar(20)'), '')
	Set @conttertifiltru = ISNULL(@parXML.value('(/*/@conttertifiltru)[1]', 'varchar(40)'), '')
	Set @valutafiltru = ISNULL(@parXML.value('(/*/@valutafiltru)[1]', 'varchar(20)'), '')
	Set @deschidGridValute=ISNULL(@parXML.value('(/*/@deschidGridValute)[1]', 'BIT'), 1)

	if @deschidGridValute=1 and exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareDifConversieLaFacturi'

	select 
		@dentertfiltru=isnull(Denumire,'') from terti where tert=@tertfiltru
	select 
		@denconttertifiltru=isnull(Denumire_cont,'') from conturi where cont=@conttertifiltru
	select 
		@denvalutafiltru=isnull(Denumire_valuta,'') from valuta where valuta=@valutafiltru

	IF @deschidGridValute=1 and @gencorectii=1
	begin 
		set @parXML.modify('insert attribute procedura {"facturi"} into (/*)[1]')

		SELECT 'Vizualizare si actualizare cursuri valute' nume, 'GV' codmeniu, 'O' tipmacheta,
				 (select dbo.fInlocuireDenumireElementXML(@parXML,'row')) dateInitializare
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

		return
	end

	if @stergcorectii=0 
		raiserror('Bifati macar optiunea "Stergere..."!' ,16,1)
	if isnull(@idcorectii,'')=''
		raiserror('Completati nr. / identificator doc.!' ,16,1)
	if @datacorectii<=@datainch
		raiserror('Data doc. este intr-o luna inchisa!' ,16,1)
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=@tertfiltru)
		raiserror('Tert inexistent!' ,16,1)
	if isnull(@conttertifiltru,'')<>'' and not exists (select 1 from conturi where cont=@conttertifiltru)
		raiserror('Cont inexistent!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from valuta where valuta=@valutafiltru)
		raiserror('Valuta inexistenta!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from curs where valuta=@valutafiltru)
		raiserror('Valuta fara nici un curs introdus!' ,16,1)

	exec DifCursFact @TipCor=@tipfact,@partert=@tertfiltru,@parvaluta=@valutafiltru,@paridentdoc=@idcorectii,@parconttert=@conttertifiltru,@contprov='',	
		@generare=@gencorectii,@sterg=@stergcorectii,@data=@datacorectii

	select 'Finalizare cu succes a operatiei!'+(case when @gencorectii=1 then ' S-au generat documente tip '+(case when @tipfact='B' then 'FB' else 'FF' end)+' cu data '+convert(char(10),@datacorectii,103) else '' end) as textMesaj,
		'Notificare' as titluMesaj 
		for xml raw, root('Mesaje')

end try  

begin catch  
	declare 
		@eroare varchar(max) 
	set @eroare=ERROR_MESSAGE() + ' (wOPGenerareDifConversieLaFacturi)'
	raiserror(@eroare, 16, 1) 
end catch
