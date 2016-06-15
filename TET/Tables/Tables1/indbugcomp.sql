CREATE TABLE [dbo].[indbugcomp] (
    [Indbug]        CHAR (20)  NOT NULL,
    [Compindbug]    CHAR (20)  NOT NULL,
    [Alfa1]         CHAR (20)  NOT NULL,
    [Alfa2]         CHAR (20)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [indbugcomp1]
    ON [dbo].[indbugcomp]([Indbug] ASC, [Compindbug] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [indbugcomp2]
    ON [dbo].[indbugcomp]([Compindbug] ASC, [Indbug] ASC);

