CREATE TABLE [dbo].[MFixini] (
    [Subunitatea]       CHAR (9)  NOT NULL,
    [Numar_de_inventar] CHAR (13) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[MFixini]([Subunitatea] ASC, [Numar_de_inventar] ASC);

