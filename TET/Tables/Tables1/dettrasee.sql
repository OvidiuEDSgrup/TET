CREATE TABLE [dbo].[dettrasee] (
    [Cod]     CHAR (20)  NOT NULL,
    [Element] CHAR (20)  NOT NULL,
    [Valoare] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[dettrasee]([Cod] ASC, [Element] ASC);

