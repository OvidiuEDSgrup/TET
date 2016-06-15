CREATE TABLE [dbo].[indbug] (
    [Indbug]        CHAR (20)  NOT NULL,
    [Denumire]      CHAR (80)  NOT NULL,
    [Grup]          FLOAT (53) NOT NULL,
    [Grupa]         CHAR (13)  NOT NULL,
    [Descr]         CHAR (200) NOT NULL,
    [Alfa1]         CHAR (20)  NOT NULL,
    [Alfa2]         CHAR (20)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [indbug1]
    ON [dbo].[indbug]([Indbug] ASC);


GO
CREATE NONCLUSTERED INDEX [indbug2]
    ON [dbo].[indbug]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [indbug3]
    ON [dbo].[indbug]([Grupa] ASC);

