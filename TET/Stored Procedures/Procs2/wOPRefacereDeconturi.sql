--***
Create procedure wOPRefacereDeconturi @sesiune varchar(50), @parXML xml
as

declare @panaladata int, @data datetime, @marcafiltru char(13), @decontfiltru char(20), 
@numemarca varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereDeconturi'

Set @panaladata = ISNULL(@parXML.value('(/parametri/@panaladata)[1]', 'int'), 0)
Set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '12/31/2999')
if @panaladata=0 Set @data = '12/31/2999'
Set @marcafiltru = ISNULL(@parXML.value('(/parametri/@marcafiltru)[1]', 'char(20)'), '')
select @numemarca=isnull(Nume,'') from personal where marca=@marcafiltru
Set @decontfiltru = ISNULL(@parXML.value('(/parametri/@decontfiltru)[1]', 'char(20)'), '')

begin try
	if isnull(@marcafiltru,'')<>'' and not exists (select 1 from personal where marca=@marcafiltru)
		raiserror('Marca inexistenta!' ,16,1)
	if isnull(@decontfiltru,'')<>'' and not exists (select 1 from Deconturi where 
		decont=@decontfiltru and (@marcafiltru='' or Marca=@marcafiltru))
		raiserror('Decont inexistent sau existent la alta marca!' ,16,1)

	exec RefacereDeconturi @dData=@data, @cMarca=@marcafiltru, @cDecont=@decontfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
