create procedure  [dbo].[wStergPlanBugetar] @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @indbug varchar(20),@anplan varchar(20),@lm varchar(20),@anchar varchar(20)
        
	select
         @indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		 @anchar=isnull(@parXML.value('(/row/@anplan)[1]','varchar(20)'),''),
		 @lm=isnull(@parXML.value('(/row/row/@lm)[1]','varchar(20)'),'')

	if isnumeric(@anchar)=1
		set @anplan=convert(int,@anchar)
	else 
		set @anplan=year(getdate())

	declare @dataj datetime,@datas datetime
	set @dataj=CONVERT(date,'01/01/'+ltrim(str(@anplan)))
	set @datas=dbo.EOY(@dataj)
	declare @mesajeroare varchar(500)
    
    if exists (select 1 from angbug a where a.indicator=@indbug and data between @dataj and @datas)
		begin
			raiserror('Nu poate fi sters planul bugetar intrucat pe baza lui au fost realizate angajamente bugetare!',16,1)
			return
		end

	delete from pozncon
		where  substring(comanda,21,20) = @indbug and loc_munca=@lm and subunitate='1' and tip='AO'
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
