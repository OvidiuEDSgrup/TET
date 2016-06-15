CREATE TABLE [dbo].[D112angajatorC5] (
    [Data]         DATETIME    NULL,
    [C5_subv]      CHAR (2)    NULL,
    [C5_recuperat] CHAR (15)   NULL,
    [C5_restituit] CHAR (15)   NULL,
    [Loc_de_munca] VARCHAR (9) DEFAULT (NULL) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Data_Subv]
    ON [dbo].[D112angajatorC5]([Data] ASC, [Loc_de_munca] ASC, [C5_subv] ASC);

