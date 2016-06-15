CREATE TABLE [dbo].[inventar] (
    [Subunitate]        CHAR (9)     NOT NULL,
    [Data_inventarului] DATETIME     NOT NULL,
    [Gestiunea]         CHAR (9)     NOT NULL,
    [Cod_de_bara]       VARCHAR (30) NULL,
    [Cod_produs]        CHAR (20)    NOT NULL,
    [Pret]              FLOAT (53)   NOT NULL,
    [Stoc_faptic]       FLOAT (53)   NOT NULL,
    [Utilizator]        CHAR (10)    NOT NULL,
    [Data_operarii]     DATETIME     NOT NULL,
    [Ora_operarii]      CHAR (6)     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[inventar]([Subunitate] ASC, [Data_inventarului] ASC, [Gestiunea] ASC, [Cod_produs] ASC, [Cod_de_bara] ASC);


GO
CREATE NONCLUSTERED INDEX [Gasit_data]
    ON [dbo].[inventar]([Subunitate] ASC, [Gestiunea] ASC);

