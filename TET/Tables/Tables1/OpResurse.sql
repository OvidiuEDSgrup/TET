CREATE TABLE [dbo].[OpResurse] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [cod]        VARCHAR (20) NULL,
    [idRes]      INT          NULL,
    [capacitate] FLOAT (53)   NULL,
    CONSTRAINT [PK_OpResurse] PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 20)
);


GO
CREATE NONCLUSTERED INDEX [Princ]
    ON [dbo].[OpResurse]([cod] ASC, [idRes] ASC) WITH (FILLFACTOR = 20);

