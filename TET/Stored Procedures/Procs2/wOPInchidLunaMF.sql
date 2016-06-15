--***
Create procedure wOPInchidLunaMF @sesiune varchar(50), @parXML xml
as

declare @lunaalfa varchar(15), @luna int, @an int, @data datetime, 
@userASiS varchar(20), @lunainch int, @anulinch int, @datainch datetime

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInchidLunaMF'
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
if @luna<>0 and @an<>0 set @data=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
select @lunaalfa=LunaAlfa from fCalendar(@data,@data)
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
	if @luna=0 or @an=0
		raiserror('Alegeti luna si anul!' ,16,1)
	if @data<=@datainch
		raiserror('Luna aleasa este inchisa!' ,16,1)

	exec setare_par 'MF','LUNAINCH','LUNAINCH',0,@luna,@lunaalfa
	exec setare_par 'MF','ANULINCH','ANULINCH',0,@an,''

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
