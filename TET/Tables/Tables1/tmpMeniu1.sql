CREATE TABLE [dbo].[tmpMeniu1] (
    [atribuit]   BIT          NOT NULL,
    [stergere]   BIT          NOT NULL,
    [adaugare]   BIT          NOT NULL,
    [modificare] BIT          NOT NULL,
    [formulare]  BIT          NOT NULL,
    [operatii]   BIT          NOT NULL,
    [meniu]      VARCHAR (20) NULL
);


GO
CREATE NONCLUSTERED INDEX [men]
    ON [dbo].[tmpMeniu1]([meniu] ASC);

