CREATE TABLE [dbo].[grupe] (
    [Tip_de_nomenclator] CHAR (1)     NOT NULL,
    [Grupa]              CHAR (13)    NOT NULL,
    [Denumire]           CHAR (120)   NULL,
    [Proprietate_1]      BIT          NOT NULL,
    [Proprietate_2]      BIT          NOT NULL,
    [Proprietate_3]      BIT          NOT NULL,
    [Proprietate_4]      BIT          NOT NULL,
    [Proprietate_5]      BIT          NOT NULL,
    [Proprietate_6]      BIT          NOT NULL,
    [Proprietate_7]      BIT          NOT NULL,
    [Proprietate_8]      BIT          NOT NULL,
    [Proprietate_9]      BIT          NOT NULL,
    [Proprietate_10]     BIT          NOT NULL,
    [detalii]            XML          NULL,
    [grupa_parinte]      VARCHAR (20) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[grupe]([Tip_de_nomenclator] ASC, [Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[grupe]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Grupa]
    ON [dbo].[grupe]([Grupa] ASC);


GO
CREATE trigger [dbo].[yso_grupesterg] on [dbo].grupe for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into yso.syssgr
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator
,[Tip_de_nomenclator]
,[Grupa]
,[Denumire]
,[Proprietate_1]
,[Proprietate_2]
,[Proprietate_3]
,[Proprietate_4]
,[Proprietate_5]
,[Proprietate_6]
,[Proprietate_7]
,[Proprietate_8]
,[Proprietate_9]
,[Proprietate_10]
   from deleted
   
   --select top 0 HOST_ID() as Host_id,HOST_NAME() as Host_name,SPACE(30) as Aplicatia,GETDATE() as Data_stergerii,SPACE(10) as Stergator,
   --grupe.* 
   --into yso.syssgr
   --from grupe