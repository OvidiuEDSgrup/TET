CREATE TABLE [dbo].[codbare] (
    [Cod_de_bare] VARCHAR (30) NULL,
    [Cod_produs]  CHAR (20)    NOT NULL,
    [UM]          VARCHAR (2)  NULL,
    [UMProdus]    VARCHAR (20) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod_de_bare]
    ON [dbo].[codbare]([Cod_de_bare] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_produs]
    ON [dbo].[codbare]([Cod_produs] ASC);

