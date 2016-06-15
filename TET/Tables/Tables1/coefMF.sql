CREATE TABLE [dbo].[coefMF] (
    [Dur]  SMALLINT NOT NULL,
    [Col2] REAL     NOT NULL,
    [Col3] REAL     NOT NULL,
    [Col4] REAL     NOT NULL,
    [Col5] REAL     NOT NULL,
    [Col6] REAL     NOT NULL,
    [Col7] REAL     NOT NULL,
    [Col8] REAL     NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Dur]
    ON [dbo].[coefMF]([Dur] ASC);

