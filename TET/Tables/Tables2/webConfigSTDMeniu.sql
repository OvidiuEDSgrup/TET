CREATE TABLE [dbo].[webConfigSTDMeniu] (
    [Meniu]        VARCHAR (20)   NOT NULL,
    [Nume]         VARCHAR (30)   NULL,
    [MeniuParinte] VARCHAR (20)   NULL,
    [Icoana]       VARCHAR (50)   NULL,
    [TipMacheta]   VARCHAR (5)    NULL,
    [NrOrdine]     DECIMAL (7, 2) NULL,
    [Componenta]   VARCHAR (100)  NULL,
    [Semnatura]    VARCHAR (100)  NULL,
    [Detalii]      XML            DEFAULT (NULL) NULL,
    [vizibil]      BIT            DEFAULT ((0)) NOT NULL
);

