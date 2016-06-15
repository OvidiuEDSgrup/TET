--***
Create procedure wOPInitializareAnFacturi @sesiune varchar(50), @parXML xml
as
declare @lunainch int, @anulinch int, @datainch datetime, @lunaimpl int, @anulimpl int, 
	@dataimpl datetime, @anulinit int,@lunainit int,@datainit datetime, 
	@suprascrieredate int, @mesajeroare varchar(254)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInitializareAnFacturi'

--exec luare_date_par 'GE','MEDIUP',@pretmediu output,0,''
Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNAINC'), 1)
Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULINC'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
Set @lunaimpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='LUNAIMPL'), 1)
Set @anulimpl=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
	parametru='ANULIMPL'), 1901)
if @lunaimpl not between 1 and 12 or @anulimpl<=1901 
	set @dataimpl='01/31/1901'
else 
	set @dataimpl=1+dbo.eom(convert(datetime,str(@lunaimpl,2)+'/01/'+str(@anulimpl,4)))
Set @anulinit = ISNULL(@parXML.value('(/parametri/@anulinit)[1]', 'int'), 0)
Set @lunainit = ISNULL(@parXML.value('(/parametri/@lunainit)[1]', 'int'), 1)--@lunainit este 1
Set @datainit=convert(datetime,str(@lunainit,2)+'/01/'+str(@anulinit,4))
Set @suprascrieredate = ISNULL(@parXML.value('(/parametri/@suprascrieredate)[1]', 'int'), 0)

begin try
	if @anulinit=0 or @lunainit=0
		raiserror('Alegeti luna si anul!' ,16,1)
	if @datainit<=@dataimpl set @mesajeroare='Nu se poate face initializare la o data anterioara sau egala cu data implementarii ('+CONVERT(char(10),@dataimpl,103)+')!'
	if @datainit<=@dataimpl
		raiserror(@mesajeroare ,16,1)
	if @datainit<=@datainch set @mesajeroare='Nu se poate face initializare la o data anterioara sau egala cu data ultimei luni inchise ('+CONVERT(char(10),@datainch,103)+')!'
	if @datainit<=@datainch
		raiserror(@mesajeroare ,16,1)
	if isnull(@suprascrieredate,0)=0 and exists (select 1 from istfact where Data_an=@datainit)
		raiserror('A fost calculat soldul initial la facturi pentru anul selectat! Bifati "Suprascriere date initiale" daca doriti sa-l recalculati!' ,16,1)

	exec initializareAnFacturi @data_initializare=@datainit
	--exec setare_par 'GE','ULT_AN_IN','Ultimul an initializare facturi',1,@anulinit,''

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
