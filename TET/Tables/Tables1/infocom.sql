CREATE TABLE [dbo].[infocom] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Comanda]    CHAR (13)  NOT NULL,
    [Pers_lans]  CHAR (6)   NOT NULL,
    [Pers_exec]  CHAR (6)   NOT NULL,
    [Par1]       CHAR (10)  NOT NULL,
    [Par2]       CHAR (10)  NOT NULL,
    [Par3]       CHAR (10)  NOT NULL,
    [Par4]       CHAR (10)  NOT NULL,
    [Par5]       CHAR (10)  NOT NULL,
    [Par6]       CHAR (10)  NOT NULL,
    [Par7]       CHAR (10)  NOT NULL,
    [Par8]       CHAR (10)  NOT NULL,
    [Par9]       CHAR (10)  NOT NULL,
    [Par10]      CHAR (10)  NOT NULL,
    [Par11]      CHAR (10)  NOT NULL,
    [Par12]      CHAR (10)  NOT NULL,
    [Utilizator] CHAR (10)  NOT NULL,
    [Data_op]    DATETIME   NOT NULL,
    [Termen]     DATETIME   NOT NULL,
    [Confirmare] BIT        NOT NULL,
    [Pret]       FLOAT (53) NOT NULL,
    [Valoare]    FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[infocom]([Subunitate] ASC, [Comanda] ASC);

