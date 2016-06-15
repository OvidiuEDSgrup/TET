CREATE TABLE [dbo].[valelemimpl] (
    [Masina]  VARCHAR (20) NOT NULL,
    [Element] VARCHAR (20) NOT NULL,
    [Valoare] FLOAT (53)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[valelemimpl]([Masina] ASC, [Element] ASC);

