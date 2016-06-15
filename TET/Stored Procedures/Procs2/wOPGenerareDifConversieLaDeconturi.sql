--***
Create procedure wOPGenerareDifConversieLaDeconturi @sesiune varchar(50), @parXML xml
as

declare @lunainch int, @anulinch int, @datainch datetime,
@marcafiltru char(13),@valutafiltru char(3),@idcorectii char(5),@datacorectii datetime,
@contfiltru varchar(40),@gencorectii int,@stergcorectii int,
@denmarcafiltru varchar(80),@dencontfiltru varchar(80),@denvalutafiltru varchar(80), 
@deschidGridValute BIT --, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='LUNAINC'), 1)
Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='ANULINC'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
Set @stergcorectii = ISNULL(@parXML.value('(/parametri/@stergcorectii)[1]', 'int'), 0)
Set @gencorectii = ISNULL(@parXML.value('(/parametri/@gencorectii)[1]', 'int'), 0)
Set @idcorectii = ISNULL(@parXML.value('(/parametri/@idcorectii)[1]', 'varchar(20)'), 'DIFCD')
Set @datacorectii = ISNULL(@parXML.value('(/parametri/@datacorectii)[1]', 'datetime'), '01/01/1901')
Set @marcafiltru = ISNULL(@parXML.value('(/parametri/@marcafiltru)[1]', 'varchar(20)'), '')
select @denmarcafiltru=isnull(nume,'') from personal where marca=@marcafiltru
Set @contfiltru = ISNULL(@parXML.value('(/parametri/@contfiltru)[1]', 'varchar(40)'), '')
select @dencontfiltru=isnull(Denumire_cont,'') from conturi where cont=@contfiltru
Set @valutafiltru = ISNULL(@parXML.value('(/parametri/@valutafiltru)[1]', 'varchar(20)'), '')
select @denvalutafiltru=isnull(Denumire_valuta,'') from valuta where valuta=@valutafiltru
Set @deschidGridValute=ISNULL(@parXML.value('(/*/@deschidGridValute)[1]', 'BIT'), 1)

if @deschidGridValute=1 and exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenerareDifConversieLaDeconturi'

begin try

	IF @deschidGridValute=1 and @gencorectii=1
	begin 
		set @parXML.modify('insert attribute procedura {"deconturi"} into (/*)[1]')

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
	if isnull(@marcafiltru,'')<>'' and not exists (select 1 from personal where Marca=@marcafiltru)
		raiserror('Marca inexistenta!' ,16,1)
	if isnull(@contfiltru,'')<>'' and not exists (select 1 from conturi where cont=@contfiltru)
		raiserror('Cont inexistent!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from valuta where valuta=@valutafiltru)
		raiserror('Valuta inexistenta!' ,16,1)
	if isnull(@valutafiltru,'')<>'' and not exists (select 1 from curs where valuta=@valutafiltru)
		raiserror('Valuta fara nici un curs introdus!' ,16,1)

	exec DifCursDecont @paridentdoc=@idcorectii,@parmarca=@marcafiltru,@parvaluta=@valutafiltru,
		@parcontdecont=@contfiltru,@data=@datacorectii,@generare=@gencorectii,@sterg=@stergcorectii
	exec RefacereDeconturi @dData=@datacorectii, @cMarca=@marcafiltru, @cDecont=''/*@decontfiltru*/
	--se cheama refaceredeconturi pt. actualizarea cursului, fiindca nu se modifica on-line prin trigger

	select 'Finalizare cu succes a operatiei!'+(case when @gencorectii=1 then ' S-au generat documente tip PD/ID cu data '+convert(char(10),@datacorectii,103) else '' end) as textMesaj,
		'Notificare' as titluMesaj 
		for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
