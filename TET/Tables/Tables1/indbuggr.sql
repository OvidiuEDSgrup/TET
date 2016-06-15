CREATE TABLE [dbo].[indbuggr] (
    [Grupa]          CHAR (20)  NOT NULL,
    [Denumire_grupa] CHAR (80)  NOT NULL,
    [Alfa1]          CHAR (20)  NOT NULL,
    [Alfa2]          CHAR (20)  NOT NULL,
    [Val1]           FLOAT (53) NOT NULL,
    [Val2]           FLOAT (53) NOT NULL,
    [Utilizator]     CHAR (10)  NOT NULL,
    [Data_operarii]  DATETIME   NOT NULL,
    [Ora_operarii]   CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [grindbug1]
    ON [dbo].[indbuggr]([Grupa] ASC);


GO
CREATE NONCLUSTERED INDEX [grindbug2]
    ON [dbo].[indbuggr]([Denumire_grupa] ASC);

