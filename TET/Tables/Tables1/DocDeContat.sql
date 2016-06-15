CREATE TABLE [dbo].[DocDeContat] (
    [subunitate] VARCHAR (20) NULL,
    [tip]        VARCHAR (2)  NULL,
    [numar]      VARCHAR (20) NULL,
    [data]       DATETIME     NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [idxDocDeContat]
    ON [dbo].[DocDeContat]([subunitate] ASC, [tip] ASC, [numar] ASC, [data] ASC);

