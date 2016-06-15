CREATE TABLE [dbo].[antchestionar] (
    [Chestionar]   CHAR (13) NOT NULL,
    [Denumire]     CHAR (30) NOT NULL,
    [Nr_intrebari] SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[antchestionar]([Chestionar] ASC);

