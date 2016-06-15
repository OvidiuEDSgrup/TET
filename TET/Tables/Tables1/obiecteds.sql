CREATE TABLE [dbo].[obiecteds] (
    [Cod_obiect] CHAR (20)  NOT NULL,
    [Denumire]   CHAR (80)  NOT NULL,
    [Serie]      CHAR (30)  NOT NULL,
    [Tip_obiect] CHAR (20)  NOT NULL,
    [Grupa]      CHAR (20)  NOT NULL,
    [Tert]       CHAR (13)  NOT NULL,
    [Data1]      DATETIME   NOT NULL,
    [Data2]      DATETIME   NOT NULL,
    [Val1]       FLOAT (53) NOT NULL,
    [Val2]       FLOAT (53) NOT NULL,
    [Info1]      CHAR (200) NOT NULL,
    [Info2]      CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [principal]
    ON [dbo].[obiecteds]([Cod_obiect] ASC);


GO
CREATE NONCLUSTERED INDEX [serie]
    ON [dbo].[obiecteds]([Serie] ASC);


GO
CREATE NONCLUSTERED INDEX [tip_obiect]
    ON [dbo].[obiecteds]([Tip_obiect] ASC);

