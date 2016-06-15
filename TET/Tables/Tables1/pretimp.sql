CREATE TABLE [dbo].[pretimp] (
    [Cod]          CHAR (20)  NOT NULL,
    [Denumire]     CHAR (61)  NOT NULL,
    [Pret_de_stoc] FLOAT (53) NOT NULL,
    [Pret_1]       FLOAT (53) NOT NULL,
    [Pret_2]       FLOAT (53) NOT NULL,
    [Pret_3]       FLOAT (53) NOT NULL,
    [Pret_4]       FLOAT (53) NOT NULL,
    [Pret_5]       FLOAT (53) NOT NULL,
    [Tara]         CHAR (10)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[pretimp]([Cod] ASC);

