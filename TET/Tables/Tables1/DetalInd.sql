CREATE TABLE [dbo].[DetalInd] (
    [Cod_indicator] VARCHAR (20)  NOT NULL,
    [Tip_detaliere] CHAR (1)      NOT NULL,
    [Expresie]      VARCHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[DetalInd]([Cod_indicator] ASC, [Tip_detaliere] ASC);

