/****** Object:  Trigger [dbo].[pozconsterg]    Script Date: 07/18/2012 13:26:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE trigger [dbo].[yso_pozconinsert] on [dbo].[pozcon] for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspcon
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Data_operarii , Ora_operarii ,
	Subunitate , Tip , Contract , Tert , Punct_livrare , Data , Cod , Cantitate , Pret , 
	Pret_promotional , Discount , Termen , Factura , Cant_disponibila , Cant_aprobata , 
	Cant_realizata , Valuta , Cota_TVA , Suma_TVA , Mod_de_plata , UM , Zi_scadenta_din_luna ,
	Explicatii , Numar_pozitie , Utilizator
   from deleted
GO


