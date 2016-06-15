CREATE TABLE [dbo].[semnific] (
    [Indicator]    CHAR (20)  NOT NULL,
    [Val_min]      FLOAT (53) NOT NULL,
    [Val_max]      FLOAT (53) NOT NULL,
    [Semnificatie] CHAR (200) NOT NULL,
    [Culoare]      SMALLINT   NOT NULL,
    [Referinta]    BIT        NOT NULL,
    CONSTRAINT [Unic] PRIMARY KEY CLUSTERED ([Indicator] ASC, [Val_min] ASC, [Val_max] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Desc_val_max]
    ON [dbo].[semnific]([Indicator] ASC, [Val_max] DESC);

