CREATE TABLE [dbo].[MFix] (
    [Subunitate]                CHAR (9)     NOT NULL,
    [Numar_de_inventar]         CHAR (13)    NOT NULL,
    [Denumire]                  CHAR (80)    NOT NULL,
    [Serie]                     CHAR (20)    NOT NULL,
    [Tip_amortizare]            CHAR (1)     NOT NULL,
    [Cod_de_clasificare]        VARCHAR (20) NULL,
    [Data_punerii_in_functiune] DATETIME     NOT NULL,
    [detalii]                   XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[MFix]([Subunitate] ASC, [Numar_de_inventar] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[MFix]([Denumire] ASC);


GO
--***
CREATE trigger MFixsterg on MFix for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssm
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate, Numar_de_inventar, Denumire, Serie, Tip_amortizare, Cod_de_clasificare, Data_punerii_in_functiune
   from deleted
