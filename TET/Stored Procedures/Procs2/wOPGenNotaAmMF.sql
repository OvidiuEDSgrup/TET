--***
Create procedure wOPGenNotaAmMF @sesiune varchar(50), @parXML xml
as

declare @stergdoc int, @gendoc int, @lm varchar(9), @denlm varchar(30), 
@data datetime, @lunaalfa varchar(15), @luna int, @an int, 
@dataj datetime, @datas datetime, --@nrinv varchar(13), @denmf varchar(50), 
@userASiS varchar(20), @lunainch int, @anulinch int, @datainch datetime, 
@nrLMFiltru int, @LMFiltru varchar(9)

exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPGenNotaAmMF'
Set @stergdoc = ISNULL(@parXML.value('(/parametri/@stergdoc)[1]', 'int'), 0)
Set @gendoc = ISNULL(@parXML.value('(/parametri/@gendoc)[1]', 'int'), 0)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @nrLMFiltru=count(1), @LMFiltru=isnull(max(Cod),'') 
from LMfiltrare where utilizator=@userASiS
set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0
	set @data=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @dataj = dbo.bom(@data)
set @datas = dbo.eom(@data)
select @lunaalfa=LunaAlfa from fCalendar(@datas,@datas)
/*set @nrinv = ISNULL(@parXML.value('(/parametri/@nrinv)[1]', 'varchar(13)'), '')
select @denmf=isnull(Denumire,'') from mfix where Numar_de_inventar=@nrinv*/
set @lm = ISNULL(@parXML.value('(/parametri/@lm)[1]', 'varchar(9)'), '')
set @lm=(case when dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru=1 then @LMFiltru else @lm end)
select @denlm=isnull(Denumire,'') from lm where cod=@lm
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

begin try  
	--BEGIN TRAN
	if @stergdoc=0 and @gendoc=0
		raiserror('Bifati macar optiunea "Stergere..."!' ,16,1)
	if @luna=0 and @an<>0
		raiserror('Alegeti luna!' ,16,1)
	if @datas<=@datainch
		raiserror('Luna aleasa este inchisa!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm=''
		raiserror('Alegeti un loc de munca!' ,16,1)
	if dbo.f_areLMFiltru(@userASiS)=1 and @nrLMFiltru>1 and @lm<>'' and @lm not in (select cod 
		from LMfiltrare where utilizator=@userASiS)
		raiserror('Locul de munca ales nu se regaseste in lista de locuri de munca pe care aveti acces!' ,16,1)

	if isnull(@lm,'')='' set @lm=''
	if @stergdoc=1 exec MFgennotaam @gendoc=@gendoc, @data=@data, @lm=@lm

	select 'Terminat operatie '+/*rtrim(@lunaalfa)+' '+convert(char(4),year(@datas))+
	(case when @nrinv<>'' then ', pt. mijlocul fix '+rtrim(@denmf) else '' end)+
	(case when @categmf<>0 then ', pt. categoria '+ltrim(str(@categmf,2)) else '' end)+
	(case when @lm<>'' then ', pt. locul de munca '+rtrim(@denlm) else '' end)+*/'!' as textMesaj, 
	'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
