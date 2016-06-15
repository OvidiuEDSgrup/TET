--***
Create procedure wOPPrefiltrareAlerteSalarii_p @sesiune varchar(50), @parXML xml
as

declare @luna int, @an int, @dataJos datetime, @dataSus datetime, @userASiS varchar(20), @LunaInch int, @AnulInch int

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)

select @an=isnull(@parXML.value('(/row/@an)[1]','int'),1901), 
	@luna=isnull(@parXML.value('(/row/@luna)[1]','int'),0)

if @luna=0
	select @luna=month(getdate()), @An=year(getdate())

begin try  
	
	SELECT @luna as luna, @an as an, 30 as zileref
	FOR XML RAW

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPrefiltrareAlerteSalarii_p) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
