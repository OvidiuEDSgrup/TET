CREATE TABLE [dbo].[Culori] (
    [Cod_culoare] VARCHAR (20) NOT NULL,
    [Denumire]    VARCHAR (40) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[Culori]([Cod_culoare] ASC);

