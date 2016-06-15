/* procedura pentru populare macheta de generare fluturasi */
Create procedure wOPPopulareGenerareFluturasi @sesiune varchar(50), @parXML xml 
as
begin
	declare @data_default datetime
	set @data_default=dateadd(m,-1,getdate())
	select month(@data_default) as luna, year(@data_default) as an, 
		rtrim(a.Numar_formular) as formular, rtrim(a.Denumire_formular) as denFormular
	from antform a where Tip_formular='6' --Numar_formular='Fluturasi'
	for xml raw
end
