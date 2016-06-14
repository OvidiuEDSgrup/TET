drop procedure yso_creezDateGenDoc 
go

create procedure yso_creezDateGenDoc 
as

alter table #dateGenDoc 
	add numardoc varchar(13),datadoc varchar(10)
		,tert varchar(13),dentert varchar(216)
		,iddelegat varchar(10),numedelegat varchar(200),prenumedelegat varchar(100)
		,nrmijltransp varchar(13),denmijloctp varchar(200),mijloctp varchar(50)
		,seriebuletin varchar(50),numarbuletin varchar(50),eliberatbuletin varchar(50)
		,observatii varchar(200),data_expedierii varchar(30),ora_expedierii varchar(8)
		,modPlata varchar(50),nrformular varchar(10),denformular varchar(100)
		