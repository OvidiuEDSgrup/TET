--***
create procedure wIaCoefAm @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesajeroare varchar(500)--, @subunitate varchar(9), @filtruGestiune varchar(9), @filtruDenumire varchar(30)

	select convert(decimal(12,0),dur) as dur, convert(decimal(12,2),col2) as col2, 
		convert(decimal(12,2),col3) as col3, convert(decimal(12,2),col4) as col4, 
		convert(decimal(12,2),col5) as col5, convert(decimal(12,2),col6) as col6, 
		convert(decimal(12,2),col7) as col7, convert(decimal(12,2),col8) as col8
	from coefMF --Dur,Col2,Col3,Col4,Col5,Col6,Col7,Col8
	order by Dur
	for xml raw
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch	
