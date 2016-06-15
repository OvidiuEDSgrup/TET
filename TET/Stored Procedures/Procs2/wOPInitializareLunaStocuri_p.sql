--***
Create procedure wOPInitializareLunaStocuri_p @sesiune varchar(50), @parXML xml
as

declare @lunainch int, @lunaalfainch char(20), @anulinch int, @datainch datetime, 
	@anulinit int,@lunainit int,@datainit datetime, @mesajeroare varchar(254)--, @userASiS varchar(10)

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

set @datainch=dbo.eom(dateadd(MONTH,1, @datainch))

Set @anulinit = year(@datainch)
Set @lunainit = ltrim(str(month(@datainch)))
--Set @datainit=dbo.eom(convert(datetime,str(@lunainit,2)+'/01/'+str(@anulinit,4)))

select @lunainit lunainit, @anulinit anulinit for xml raw, root('Date')
