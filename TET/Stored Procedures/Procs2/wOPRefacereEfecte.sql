--***
Create procedure wOPRefacereEfecte @sesiune varchar(50), @parXML xml
as

declare @panaladata int, @data datetime, @tipefectfiltru char(1), @tertfiltru char(13), 
@efectfiltru char(20), @dentert varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereEfecte'

Set @panaladata = ISNULL(@parXML.value('(/parametri/@panaladata)[1]', 'int'), 0)
Set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '12/31/2999')
if @panaladata=0 Set @data = '12/31/2999'
Set @tipefectfiltru = ISNULL(@parXML.value('(/parametri/@tipefectfiltru)[1]', 'char(20)'), '')
Set @tertfiltru = ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'char(20)'), '')
select @dentert=isnull(Denumire,'') from terti where tert=@tertfiltru
Set @efectfiltru = ISNULL(@parXML.value('(/parametri/@efectfiltru)[1]', 'char(20)'), '')

begin try
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=@tertfiltru)
		raiserror('Tert inexistent!' ,16,1)
	if isnull(@efectfiltru,'')<>'' and not exists (select 1 from efecte where tip=@tipefectfiltru and 
		Nr_efect=@efectfiltru and (@tertfiltru='' or tert=@tertfiltru))
		raiserror('Efect inexistent sau de alt tip sau la alt tert!' ,16,1)

	exec RefacereEfecte @dData=@data, @cTipEf=@tipefectfiltru, @cTert=@tertfiltru, @cEfect=@efectfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
