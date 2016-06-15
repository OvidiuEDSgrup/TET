--***
create procedure wOPInlocuireCotaTVA_P (@sesiune varchar(50), @parXML xml) 
as     

begin try
		select 24 as cotaveche, 20 as cotanoua, 
		1 as cotanomencl, 1 as pretamtabpreturi, '01/01/2016' as datajospret, 1 as pretamtabstocuri, 
		'R' as optpretam, convert(decimal(4,2),0.05) as sumarotunjire
		for xml raw
end try

begin catch
	declare @mesaj varchar(1000)
	set @mesaj = ERROR_MESSAGE()+' (wOPInlocuireCotaTVA_P)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)