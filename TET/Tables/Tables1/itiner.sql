CREATE TABLE [dbo].[itiner] (
    [Comanda]      CHAR (13) NOT NULL,
    [Cod_itinerar] CHAR (3)  NOT NULL,
    [etapa]        SMALLINT  NOT NULL,
    [Loc_de_munca] CHAR (9)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[itiner]([Comanda] ASC, [Cod_itinerar] ASC, [etapa] ASC);

