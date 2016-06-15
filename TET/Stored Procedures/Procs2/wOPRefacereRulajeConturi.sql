--***
Create procedure wOPRefacereRulajeConturi @sesiune varchar(50), @parXML xml
as

declare @rulajelei int, @rulajevaluta int, @datal datetime, @lunaalfa varchar(15), @luna int, @an int, 
@dataj datetime, @datas datetime, @cont varchar(40), @dencont varchar(80), 
@lunabloc int,@anulbloc int, @databloc datetime--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereRulajeConturi'

Set @rulajelei = ISNULL(@parXML.value('(/parametri/@rulajelei)[1]', 'int'), 1)
Set @rulajevaluta = ISNULL(@parXML.value('(/parametri/@rulajevaluta)[1]', 'int'), 1)
set @datal = ISNULL(@parXML.value('(/parametri/@datal)[1]', 'datetime'), '12/31/2999')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datal=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataj = dbo.bom(@datal)
set @datas = dbo.eom(@datal)
select @lunaalfa=LunaAlfa from fCalendar(@datas,@datas)
set @cont = ISNULL(@parXML.value('(/parametri/@cont)[1]', 'varchar(40)'), '')
select @dencont=isnull(Denumire_cont,'') from conturi where cont=@cont
set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNABLOC'), 1)
set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULBLOC'), 1901)
if @lunabloc not between 1 and 12 or @anulbloc<=1901 
	set @databloc='01/31/1901'
else 
	set @databloc=dbo.eom(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

begin try  
	if @rulajelei+@rulajevaluta=0
		raiserror('Bifati cel putin o optiune!' ,16,1)
	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
	if @cont<>'' and not exists (select 1 from conturi where cont=@cont)
		raiserror('Cont inexistent!' ,16,1)
	if @dataj<=@databloc
		raiserror('Luna aleasa este blocata!' ,16,1)

	set @dataj=dbo.EOM(@dataj)
	exec RefacereRulaje @dDataJos=@dataj, @dDataSus=@datas, @cCont=''/*@cont*/, --nu trimit @cont, fiindca refacerea funct. corect numai cand se da pe toate ct.
		@nInLei=@rulajelei, @nInValuta=@rulajevaluta, @cValuta=''

	select 'Terminat operatie!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
