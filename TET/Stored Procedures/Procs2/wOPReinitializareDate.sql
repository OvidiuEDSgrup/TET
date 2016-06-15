
Create procedure wOPReinitializareDate @sesiune varchar(50), @parXML xml
as
begin try
	
	declare 
		@lunainch int, @anulinch int, @datainch datetime, @datareinit datetime,@stergdoc int,
		@reffact int,@refdec int,@refefecte int,@mesajeroare varchar(254)

	if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPReinitializareDate'

	Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNAINC'), 1)
	Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULINC'), 1901)
	if @lunainch not between 1 and 12 or @anulinch<=1901 
		set @datainch='01/31/1901'
	else 
		set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))

	SELECT
		@datareinit = ISNULL(@parXML.value('(/*/@datareinit)[1]', 'datetime'), '01/01/1901'),
		@stergdoc = ISNULL(@parXML.value('(/*/@stergdoc)[1]', 'int'), 0),
		@reffact = ISNULL(@parXML.value('(/*/@reffact)[1]', 'int'), 0),
		@refdec = ISNULL(@parXML.value('(/*/@refdec)[1]', 'int'), 0),
		@refefecte = ISNULL(@parXML.value('(/*/@refefecte)[1]', 'int'), 0)


	if @datareinit>@datainch set @mesajeroare='Inchideti lunile pana la '+CONVERT(char(10),dbo.eom(@datareinit),103)+'!'
	if @datareinit>@datainch
		raiserror(@mesajeroare ,16,1)

	exec reinitializareDate @datareinit=@datareinit,@stergdoc=@stergdoc,@reffact=@reffact, @refdec=@refdec,@refefecte=@refefecte

	select 'Terminat operatie!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
