--***
if exists (select * from sysobjects where name ='yso_tr_DefinitivareNecesar' and xtype='TR')
	drop trigger yso_tr_DefinitivareNecesar
go
--***
create trigger yso_tr_DefinitivareNecesar on jurnalContracte after insert,update,delete
as
begin try	
	declare @stareDefinitiva int
	select top 1 @stareDefinitiva=stare from StariContracte where tipContract='RN' and modificabil=0 order by stare
	
	update n set Stare=1
	from necesaraprov n join Contracte c on c.tip='RN' and c.numar=n.Numar and c.data=n.Data join inserted i on i.idContract=c.idContract
	where i.stare=@stareDefinitiva 
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 

go
