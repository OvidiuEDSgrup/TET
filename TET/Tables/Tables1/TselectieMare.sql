CREATE TABLE [dbo].[TselectieMare] (
    [Terminal] VARCHAR (10)  NOT NULL,
    [Cod]      VARCHAR (500) NOT NULL,
    [Bifa]     BIT           NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[TselectieMare]([Terminal] ASC, [Cod] ASC);

