CREATE TABLE [dbo].[lansmat] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Comanda]            CHAR (13)  NOT NULL,
    [Cod_produs]         CHAR (20)  NOT NULL,
    [Tip_reper_mat]      BINARY (1) NOT NULL,
    [Cod_tata]           CHAR (20)  NOT NULL,
    [Cod_material]       CHAR (20)  NOT NULL,
    [Cod_inlocuit]       CHAR (20)  NOT NULL,
    [Cantitate_necesara] FLOAT (53) NOT NULL,
    [Pret]               FLOAT (53) NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Numar_fisa]         CHAR (8)   NOT NULL,
    [Gestiune]           CHAR (9)   NOT NULL,
    [Alfa1]              CHAR (20)  NOT NULL,
    [Alfa2]              CHAR (20)  NOT NULL,
    [Val1]               FLOAT (53) NOT NULL,
    [Val2]               FLOAT (53) NOT NULL,
    [Data]               DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[lansmat]([Subunitate] ASC, [Comanda] ASC, [Cod_tata] ASC, [Cod_material] ASC, [Numar_fisa] ASC);


GO
CREATE NONCLUSTERED INDEX [Comanda_Tip_Cod]
    ON [dbo].[lansmat]([Subunitate] ASC, [Comanda] ASC, [Cod_produs] ASC, [Tip_reper_mat] ASC, [Cod_material] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Pe_locm]
    ON [dbo].[lansmat]([Subunitate] ASC, [Comanda] ASC, [Cod_tata] ASC, [Loc_de_munca] ASC, [Tip_reper_mat] ASC, [Cod_material] ASC, [Numar_fisa] ASC);


GO
--***
CREATE trigger lansmatsterg on lansmat for update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)
/*
insert into sysslsmat
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'A',Subunitate,Comanda,Cod_produs,Tip_reper_mat,Cod_tata,Cod_material,Cod_inlocuit,Cantitate_necesara,Pret,
	Loc_de_munca, Numar_fisa, Gestiune,Alfa1,Alfa2,Val1,Val2,Data
 from inserted
*/
insert into sysslsmat
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S',Subunitate,Comanda,Cod_produs,Tip_reper_mat,Cod_tata,Cod_material,Cod_inlocuit,Cantitate_necesara,Pret,
	Loc_de_munca, Numar_fisa, Gestiune,Alfa1,Alfa2,Val1,Val2,Data
 from deleted
end