CREATE TABLE [dbo].[poze] (
    [Cod]        CHAR (20)  NOT NULL,
    [Poza]       IMAGE      NULL,
    [Coeficient] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[poze]([Cod] ASC);

