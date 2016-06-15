--***
Create procedure wOPCalcLunMF @sesiune varchar(50), @parXML xml
as
declare @sub char(9), @nusegennotaamlacalclun int, @lunainch int,@anulinch int, @datainch datetime, 
	@lunaalfaultcalc varchar(15), @lunaultcalc int, @anulultcalc int, @dataultcalc datetime, 
	@lunaalfa varchar(15), @luna int, @an int, @datal datetime, 
	@nrinv varchar(13), @denmf varchar(80), @categmf int, @lm varchar(9), @denlm varchar(30), 
	@userASiS varchar(20), @nrLMFiltru int, @LMFiltru varchar(9), @mesajeroare varchar(254)

exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPCalcLunMF'
set @sub=isnull((select Val_alfanumerica from par where tip_parametru='GE' and 
	parametru='SUBPRO'),'')
set @nusegennotaamlacalclun=isnull((select Val_logica from par where tip_parametru='MF' and 
	parametru='GENSEP'),0)
set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAI'), 1))
set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULINCH'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULI'), 1901))
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
set @lunaultcalc=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNACAL'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='LUNAI'), 1))
set @lunaalfaultcalc=isnull((select max(Val_alfanumerica) from par where tip_parametru='MF' and 
	parametru='LUNACAL'), isnull((select max(Val_alfanumerica) from par where tip_parametru='MF' and 
	parametru='LUNAI'), 'Ianuarie'))
set @anulultcalc=isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULCAL'), isnull((select max(val_numerica) from par where tip_parametru='MF' and 
	parametru='ANULI'), 1901))
if @lunaultcalc not between 1 and 12 or @anulultcalc<=1901 
	set @dataultcalc='01/31/1901'
else 
	set @dataultcalc=dbo.eom(convert(datetime,str(@lunaultcalc,2)+'/01/'+str(@anulultcalc,4)))
set @datal = ISNULL(@parXML.value('(/parametri/@datal)[1]', 'datetime'), '01/01/1901')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @datal=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
select @lunaalfa=LunaAlfa from fCalendar(@datal,@datal)
set @nrinv = ISNULL(@parXML.value('(/parametri/@nrinv)[1]', 'varchar(13)'), '')
select @denmf=isnull(Denumire,'') from mfix where Numar_de_inventar=@nrinv
Set @categmf = ISNULL(@parXML.value('(/parametri/@categmf)[1]', 'int'), 0)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') from LMfiltrare where utilizator=@userASiS
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
if @lm='' set @lm=ISNULL((select loc_de_munca from fisamf f where f.subunitate=@sub 
and f.Numar_de_inventar=@nrinv and f.Data_lunii_operatiei=@datal and f.Felul_operatiei='1'),'')
select @denlm=isnull(Denumire,'') from lm where cod=@lm

begin try
	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
	set @mesajeroare='Ultima data s-au dat calcule lunare pe luna '+rTrim (@lunaalfaultcalc)+' '+
		Str(@anulultcalc,4)+'. Este necesar sa dati calcule lunare incepand cu luna urmatoare!'
	if @datal>dbo.eom(@dataultcalc+1)
		raiserror(@mesajeroare ,16,1)
	if @datal<=@datainch
		raiserror('Luna aleasa este inchisa in MF!' ,16,1)
	if @nrinv<>'' and not exists (select 1 from MFix where Numar_de_inventar=@nrinv)
		raiserror('Mijloc fix inexistent!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Alegeti un loc de munca!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod from 
			LMfiltrare where utilizator=@userASiS) and not exists (select 1 from LMFiltrare where 
			@lm like RTRIM(cod)+'%') 
		raiserror('Locul de munca ales nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

	--exec MFimportdinCG @Datal=@Datal, @nrinvfiltru=@nrinv, @categmffiltru=@categmf, @lmfiltru=@lm
	exec MFcalclun @Datal=@Datal, @nrinv=@nrinv, @categmf=@categmf, @lm=@lm
	if @nusegennotaamlacalclun=0 exec MFgennotaam @gendoc=1, @data=@datal, @lm=@lm

	select 'Terminat operatie!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
