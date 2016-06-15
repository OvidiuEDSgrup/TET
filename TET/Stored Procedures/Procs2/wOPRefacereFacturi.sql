--***
Create procedure wOPRefacereFacturi @sesiune varchar(50), @parXML xml
as

declare @panaladata int, @data datetime, @tipfact char(1), @tertfiltru char(13), @factfiltru char(20), 
@dentert varchar(80)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereFacturi'

Set @panaladata = ISNULL(@parXML.value('(/parametri/@panaladata)[1]', 'int'), 0)
Set @data = ISNULL(@parXML.value('(/parametri/@data)[1]', 'datetime'), '12/31/2999')
if @panaladata=0 Set @data = null
Set @tipfact = ISNULL(@parXML.value('(/parametri/@tipfact)[1]', 'char(20)'), ISNULL(@parXML.value('(/parametri/@tip)[1]', 'char(20)'), ''))
Set @tertfiltru = ISNULL(@parXML.value('(/parametri/@tert)[1]', 'char(20)'), ISNULL(@parXML.value('(/parametri/@tertfiltru)[1]', 'char(20)'), ''))
select @dentert=isnull(Denumire,'') from terti where tert=@tertfiltru
Set @factfiltru = ISNULL(@parXML.value('(/parametri/@factura)[1]', 'char(20)'), ISNULL(@parXML.value('(/parametri/@factfiltru)[1]', 'char(20)'), ''))

begin try
	if isnull(@tertfiltru,'')<>'' and not exists (select 1 from terti where tert=isnull(@tertfiltru,''))
		raiserror('Tert inexistent!' ,16,1)
	if isnull(@factfiltru,'')<>'' and (@tipfact='' or isnull(@tertfiltru,'')='')
		raiserror('Alegeti tipul facturii si tertul!' ,16,1)
	if isnull(@factfiltru,'')<>'' and not exists (select 1 from facturi where tip=(case when @tipfact=
		'B' then 0x46 else 0x54 end) and Factura=@factfiltru and (/*@tertfiltru='' or */tert=@tertfiltru))
		raiserror('Factura inexistenta sau de alt tip sau la alt tert!' ,16,1)

	if @tertfiltru='' set @tertfiltru=null
	if @factfiltru='' set @factfiltru=null
	exec RefacereFacturi @cFurnBenef=@tipfact, @dData=@data, @cTert=@tertfiltru, @cFactura=@factfiltru

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@eroare, 16, 1) 
end catch
