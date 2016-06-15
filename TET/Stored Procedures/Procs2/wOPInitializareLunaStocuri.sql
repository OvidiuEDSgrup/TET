--***
Create procedure wOPInitializareLunaStocuri @sesiune varchar(50), @parXML xml
as

declare @pretmediu int,@lunainch int, @lunaalfainch char(20), @anulinch int, @datainch datetime, 
@anulinit int,@lunainit int,@datainit datetime, @mesajeroare varchar(254)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

exec luare_date_par 'GE','MEDIUP',@pretmediu output,0,''
Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='LUNAINC'), 1)
Set @lunaalfainch=isnull((select max(Val_alfanumerica) from par where tip_parametru='GE' and 
parametru='LUNAINC'), 'Ianuarie')
Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='ANULINC'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))
Set @anulinit = ISNULL(@parXML.value('(/parametri/@anulinit)[1]', 'int'), 0)
Set @lunainit = ISNULL(@parXML.value('(/parametri/@lunainit)[1]', 'int'), 0)
Set @datainit=dbo.eom(convert(datetime,str(@lunainit,2)+'/01/'+str(@anulinit,4)))

begin try
	if @datainit<=@datainch set @mesajeroare='Ultima luna inchisa este '+RTRIM(@lunaalfainch)+' '+str(@anulinch,4)+'!'
	if @datainit<=@datainch
		raiserror(@mesajeroare ,16,1)
	if @pretmediu=1
		raiserror('Operatie nepermisa in conditii de lucru cu pret mediu!' ,16,1)
	if @anulinit=0 or @lunainit=0
		raiserror('Alegeti luna si anul!' ,16,1)

	exec initializareLunaStocuri @anulinit=@anulinit,@lunainit=@lunainit,
		@inchidlunaant=1,@faracalcstocinit=0,@calculrapid=0,@farainlocpretdoc=0

	if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInitializareLunaStocuri'

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
