CREATE TABLE [dbo].[tmpprodsisemif] (
    [id]            INT             NULL,
    [utilizator]    VARCHAR (100)   NULL,
    [tip]           VARCHAR (1)     NULL,
    [codNomencl]    VARCHAR (20)    NULL,
    [idp]           INT             NULL,
    [codp]          VARCHAR (20)    NULL,
    [nivel]         INT             NULL,
    [cantitate]     DECIMAL (15, 6) NULL,
    [idPozContract] INT             NULL,
    [detalii]       XML             NULL
);


GO
CREATE NONCLUSTERED INDEX [ptProdSemif]
    ON [dbo].[tmpprodsisemif]([utilizator] ASC, [codNomencl] ASC, [codp] ASC);

