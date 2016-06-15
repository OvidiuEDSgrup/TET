CREATE TABLE [dbo].[lansman] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Comanda]            CHAR (13)  NOT NULL,
    [Cod_produs]         CHAR (20)  NOT NULL,
    [Cod_tata]           CHAR (20)  NOT NULL,
    [Cod_operatie]       CHAR (20)  NOT NULL,
    [Numar_operatie]     SMALLINT   NOT NULL,
    [Cantitate_necesara] FLOAT (53) NOT NULL,
    [Pret]               FLOAT (53) NOT NULL,
    [Numar_fisa]         CHAR (8)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Numar_de_inventar]  CHAR (13)  NOT NULL,
    [Cod_material]       CHAR (20)  NOT NULL,
    [Alfa1]              CHAR (20)  NOT NULL,
    [Alfa2]              CHAR (20)  NOT NULL,
    [Val1]               FLOAT (53) NOT NULL,
    [Val2]               FLOAT (53) NOT NULL,
    [Data]               DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Numar_fisa]
    ON [dbo].[lansman]([Subunitate] ASC, [Comanda] ASC, [Numar_fisa] ASC, [Numar_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_Cod]
    ON [dbo].[lansman]([Subunitate] ASC, [Comanda] ASC, [Cod_produs] ASC, [Cod_operatie] ASC);


GO
CREATE NONCLUSTERED INDEX [Locm_operatie_produs]
    ON [dbo].[lansman]([Subunitate] ASC, [Loc_de_munca] ASC, [Numar_operatie] ASC, [Cod_produs] ASC);


GO
--***
CREATE trigger lansmansterg on lansman for insert, update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysslsman
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A',Subunitate,Comanda,Cod_produs,Cod_tata ,Cod_operatie,Numar_operatie,Cantitate_necesara,Pret,
		Numar_fisa, Loc_de_munca, Numar_de_inventar,Cod_material,Alfa1,Alfa2,Val1,Val2,Data
   from inserted

insert into sysslsman
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S',Subunitate,Comanda,Cod_produs,Cod_tata ,Cod_operatie,Numar_operatie,Cantitate_necesara,Pret,
		Numar_fisa, Loc_de_munca, Numar_de_inventar,Cod_material,Alfa1,Alfa2,Val1,Val2,Data
   from deleted
end