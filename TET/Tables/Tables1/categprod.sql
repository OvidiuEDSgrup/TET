CREATE TABLE [dbo].[categprod] (
    [Categoria]        SMALLINT   NOT NULL,
    [Denumire]         CHAR (30)  NOT NULL,
    [Greutate_medie]   FLOAT (53) NOT NULL,
    [Acciza_cumparare] FLOAT (53) NOT NULL,
    [Acciza_vanzare]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[categprod]([Categoria] ASC);

