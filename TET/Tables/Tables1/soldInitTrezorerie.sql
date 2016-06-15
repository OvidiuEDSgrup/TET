CREATE TABLE [dbo].[soldInitTrezorerie] (
    [Cont]         VARCHAR (20) NOT NULL,
    [Indicator]    VARCHAR (20) NOT NULL,
    [Loc_de_munca] VARCHAR (9)  NOT NULL,
    [Data]         DATETIME     NOT NULL,
    [Sold]         FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[soldInitTrezorerie]([Cont] ASC, [Indicator] ASC, [Data] ASC, [Loc_de_munca] ASC);

