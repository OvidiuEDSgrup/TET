CREATE TABLE [dbo].[FisaPeCont] (
    [Data]    DATETIME     NOT NULL,
    [Tip]     VARCHAR (1)  NOT NULL,
    [LM]      VARCHAR (9)  NOT NULL,
    [Comanda] VARCHAR (13) NOT NULL,
    [Cont]    VARCHAR (13) NOT NULL,
    [Suma]    FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Prin]
    ON [dbo].[FisaPeCont]([Data] ASC, [Tip] ASC, [LM] ASC, [Comanda] ASC, [Cont] ASC);

