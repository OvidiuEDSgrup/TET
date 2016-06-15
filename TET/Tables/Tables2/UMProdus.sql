CREATE TABLE [dbo].[UMProdus] (
    [cod]        VARCHAR (20) NULL,
    [UM]         VARCHAR (3)  NULL,
    [coeficient] FLOAT (53)   NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [principal]
    ON [dbo].[UMProdus]([cod] ASC, [UM] ASC);

