CREATE TABLE [dbo].[Termene] (
    [Subunitate]     CHAR (9)   NOT NULL,
    [Tip]            CHAR (2)   NOT NULL,
    [Contract]       CHAR (20)  NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Data]           DATETIME   NOT NULL,
    [Termen]         DATETIME   NOT NULL,
    [Cantitate]      FLOAT (53) NOT NULL,
    [Cant_realizata] FLOAT (53) NOT NULL,
    [Pret]           FLOAT (53) NOT NULL,
    [Explicatii]     CHAR (200) NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Data1]          DATETIME   NOT NULL,
    [Data2]          DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Termene]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Tert] ASC, [Cod] ASC, [Data] ASC, [Termen] ASC);


GO
CREATE NONCLUSTERED INDEX [yso_cantitate]
    ON [dbo].[Termene]([Subunitate] ASC, [Tip] ASC, [Cantitate] ASC)
    INCLUDE([Contract], [Tert], [Cod], [Data], [Termen]);


GO
--***
CREATE trigger termsterg on termene for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssterm
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate , Tip , Contract , Tert , Cod , Data , Termen , Cantitate , Cant_realizata , 
	Pret , Explicatii , Val1 , Val2 , Data1 , Data2
   from deleted