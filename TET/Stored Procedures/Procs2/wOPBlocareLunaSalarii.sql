--***
Create procedure wOPBlocareLunaSalarii @sesiune varchar(50), @parXML xml
as

declare @userASiS varchar(20), @err int, @nrLMFiltru int, 
	@luna int, @an int, @dataCareSeBlocheaza datetime, @lunaalfa varchar(15), 
	@lunainch int, @anulinch int, @datainch datetime, @datablocOK datetime, 
	@lunabloc int, @anulbloc int, @databloc datetime, @lunaalfabloc varchar(15), @mesajEroare varchar(MAX)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPBlocareLunaSalarii' 

select @nrLMFiltru=count(1) from LMfiltrare where utilizator=@userASiS
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @dataCareSeBlocheaza=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
select @lunaalfa=LunaAlfa from fCalendar(@dataCareSeBlocheaza,@dataCareSeBlocheaza)

set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/01/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNABLOC'), 1)
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULBLOC'), 1901)
if @lunabloc not between 1 and 12 or @anulbloc<=1901 
	set @databloc=@datainch
else 
	set @databloc=dbo.eom(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))
select @lunaalfabloc=LunaAlfa from fCalendar(@databloc,@databloc)

begin try 
	--BEGIN TRAN
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>0
		raiserror('Utilizatorii ce au proprietatea LOCMUNCA nu pot executa operatia de blocare luna!' ,16,1)
	if @datainch>@dataCareSeBlocheaza
		raiserror('Ultima luna blocata nu poate fi inaintea ultimei luni inchise!' ,16,1)
	if DateDiff(month,@datainch,@dataCareSeBlocheaza)>=2
	Begin
		set @datablocOK=DateAdd(month,1,@datainch)
		select @lunaalfabloc=LunaAlfa from fCalendar(@datablocOK,@datablocOK)
			Set @mesajEroare='Luna blocata poate fi ' + RTRIM(@lunaalfabloc) + ' - ' + CONVERT(char(4),YEAR(@datablocOK)) + '!'
		raiserror(@mesajEroare,16,1)
	End	
	if @dataCareSeBlocheaza<@databloc
		select 'Ultima luna blocata ('+rtrim(@lunaalfabloc)+' '+convert(char(4),year(@databloc))
		+') e ulterioara lunii curente ('+rtrim(@lunaalfa)+' '+convert(char(4),@an)+')!'+char(13)+'Se vor debloca lunile blocate!' as textMesaj, 
		'Blocare luna' as titluMesaj for xml raw, root('Mesaje')

	exec setare_par 'PS', 'LUNABLOC', 'Luna blocata', 0, @luna, @lunaalfa
	exec setare_par 'PS', 'ANULBLOC', 'Anul lunii blocate', 0, @an, ''

	select 'S-a blocat luna '+rtrim(@lunaalfa)+' '+convert(char(4),@an)+'!' as textMesaj,
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	declare @eroare varchar(254)
	set @eroare='(wOPBlocareLunaSalarii) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch
