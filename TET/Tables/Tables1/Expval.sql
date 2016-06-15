CREATE TABLE [dbo].[Expval] (
    [Cod_indicator] VARCHAR (20)  NOT NULL,
    [Tip]           VARCHAR (1)   NOT NULL,
    [Data]          DATETIME      NULL,
    [Element_1]     VARCHAR (150) NULL,
    [Element_2]     VARCHAR (150) NULL,
    [Element_3]     VARCHAR (150) NULL,
    [Element_4]     VARCHAR (150) NULL,
    [Element_5]     VARCHAR (150) NULL,
    [Valoare]       FLOAT (53)    NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Data] ASC, [Element_1] ASC, [Element_2] ASC, [Element_3] ASC, [Element_4] ASC, [Element_5] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_element1]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Element_1] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_element2]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Element_2] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_element3]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Element_3] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_element4]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Element_4] ASC);


GO
CREATE NONCLUSTERED INDEX [ix_element5]
    ON [dbo].[Expval]([Cod_indicator] ASC, [Tip] ASC, [Element_5] ASC);

