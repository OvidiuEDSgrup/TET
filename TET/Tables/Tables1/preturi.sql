CREATE TABLE [dbo].[preturi] (
    [Cod_produs]        CHAR (20)   NOT NULL,
    [UM]                SMALLINT    NOT NULL,
    [Tip_pret]          CHAR (20)   NOT NULL,
    [Data_inferioara]   DATETIME    NOT NULL,
    [Ora_inferioara]    CHAR (13)   NOT NULL,
    [Data_superioara]   DATETIME    NOT NULL,
    [Ora_superioara]    CHAR (6)    NOT NULL,
    [Pret_vanzare]      FLOAT (53)  NOT NULL,
    [Pret_cu_amanuntul] FLOAT (53)  NOT NULL,
    [Utilizator]        CHAR (10)   NOT NULL,
    [Data_operarii]     DATETIME    NOT NULL,
    [Ora_operarii]      CHAR (6)    NOT NULL,
    [umprodus]          VARCHAR (3) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cheie_unica]
    ON [dbo].[preturi]([Cod_produs] ASC, [UM] ASC, [umprodus] ASC, [Tip_pret] ASC, [Data_inferioara] ASC, [Ora_inferioara] ASC, [Ora_superioara] ASC, [Ora_operarii] ASC);


GO
CREATE NONCLUSTERED INDEX [Regasire]
    ON [dbo].[preturi]([Cod_produs] ASC, [Tip_pret] ASC, [umprodus] ASC, [Data_inferioara] ASC, [Ora_inferioara] ASC, [Ora_superioara] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[preturi]([Cod_produs] ASC, [UM] ASC, [umprodus] ASC, [Tip_pret] ASC, [Data_superioara] ASC, [Ora_inferioara] ASC, [Ora_superioara] ASC, [Ora_operarii] ASC);


GO
--***
CREATE trigger preturisterg on preturi for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspv
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, data_operarii, ora_operarii,
	Cod_produs, UM, Tip_pret, Data_inferioara, Ora_inferioara, Data_superioara, Ora_superioara, 
	Pret_vanzare, Pret_cu_amanuntul, Utilizator
   from deleted
