CREATE TABLE [dbo].[grupeUtilizatoriRia] (
    [utilizator] VARCHAR (50) NULL,
    [grupa]      VARCHAR (50) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ind]
    ON [dbo].[grupeUtilizatoriRia]([utilizator] ASC, [grupa] ASC);

