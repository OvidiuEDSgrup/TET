CREATE TABLE [dbo].[realrep_nu_sterge] (
    [Numar_fisa]            CHAR (20)  NOT NULL,
    [Data]                  DATETIME   NOT NULL,
    [Ora_inceput]           CHAR (6)   NOT NULL,
    [Ora_sfarsit]           CHAR (6)   NOT NULL,
    [Comanda]               CHAR (13)  NOT NULL,
    [Cod_reper]             CHAR (20)  NOT NULL,
    [Numar_operatie]        SMALLINT   NOT NULL,
    [Cod_operatie]          CHAR (20)  NOT NULL,
    [Loc_de_munca]          CHAR (9)   NOT NULL,
    [Comanda_utilaj]        CHAR (13)  NOT NULL,
    [Cantitate]             FLOAT (53) NOT NULL,
    [Cantitate_echivalenta] FLOAT (53) NOT NULL
);

