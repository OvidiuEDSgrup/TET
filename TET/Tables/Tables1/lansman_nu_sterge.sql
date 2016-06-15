CREATE TABLE [dbo].[lansman_nu_sterge] (
    [Subunitate]         CHAR (9)   NOT NULL,
    [Comanda]            CHAR (13)  NOT NULL,
    [Cod_produs]         CHAR (30)  NOT NULL,
    [Cod_tata]           CHAR (30)  NOT NULL,
    [Cod_operatie]       CHAR (20)  NOT NULL,
    [Numar_operatie]     SMALLINT   NOT NULL,
    [Cantitate_necesara] FLOAT (53) NOT NULL,
    [Pret]               FLOAT (53) NOT NULL,
    [Numar_fisa]         CHAR (8)   NOT NULL,
    [Loc_de_munca]       CHAR (9)   NOT NULL,
    [Numar_de_inventar]  CHAR (13)  NOT NULL,
    [Cod_material]       CHAR (30)  NOT NULL,
    [Alfa1]              CHAR (20)  NOT NULL,
    [Alfa2]              CHAR (20)  NOT NULL,
    [Val1]               FLOAT (53) NOT NULL,
    [Val2]               FLOAT (53) NOT NULL,
    [Data]               DATETIME   NOT NULL
);

