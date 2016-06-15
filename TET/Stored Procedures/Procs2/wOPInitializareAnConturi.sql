--***

create procedure wOPInitializareAnConturi(@sesiune varchar(50), @parXML xml)
as
begin
declare @eroare varchar(2000)
begin try
	if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInitializareAnConturi'
	declare @an int
	select @an=isnull(@parxml.value('(/parametri/@an)[1]','int'),0)
	select @an=(case when @an=0 then year(getdate())+1 else @an end)
	
	declare @dataImplementarii datetime
	select @dataImplementarii=dbo.eom(convert(datetime,
			 convert(varchar(20),max(case when parametru='ANULIMPL' then val_numerica else 0 end))
		+'-'+convert(varchar(20),max(case when parametru='LUNAIMPL' then val_numerica else 0 end))
		+'-1'))
	from par where tip_parametru='GE' and parametru in ('ANULIMPL','LUNAIMPL')
	
	select @dataImplementarii=dateadd(d,1,@dataImplementarii)
	if (@an<=year(@dataImplementarii)) raiserror('Nu este permisa initializarea inainte sau in luna ulterioara implementarii!',16,1)
	
	exec initializareAnConturi @sesiune=@sesiune, @an=@an
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wOPInitializareAnConturi '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
